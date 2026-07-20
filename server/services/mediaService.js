const crypto = require('crypto');

const { supabaseAdmin } = require('../config/supabaseClient');
const { AppError, wrapDatabaseError } = require('../utils/appError');
const { VISIBILITY_LEVEL } = require('../constants/alertTrust');
const { isModeratorOrAdmin } = require('../constants/roles');

const ALERTS_TABLE = 'alerts';
const ALERT_MEDIA_TABLE = 'alert_media';
const SIGNED_URL_EXPIRY_SECONDS = 600;

const MIME_TYPE_TO_MEDIA_TYPE = Object.freeze({
  'image/jpeg': 'image',
  'image/png': 'image',
  'image/webp': 'image',
  'video/mp4': 'video',
  'video/quicktime': 'video',
  'video/webm': 'video',
  'audio/mpeg': 'audio',
  'audio/mp4': 'audio',
  'audio/aac': 'audio',
  'audio/wav': 'audio',
  'audio/x-wav': 'audio',
  'audio/ogg': 'audio',
  'audio/webm': 'audio',
});

const ALLOWED_MIME_TYPES = Object.freeze(Object.keys(MIME_TYPE_TO_MEDIA_TYPE));

const getStorageBucket = () => process.env.SUPABASE_MEDIA_BUCKET || 'alert-media';

const getMaxFileSizeBytes = () => {
  const configuredMb = Number.parseInt(process.env.MEDIA_MAX_FILE_SIZE_MB, 10);
  const megabytes = Number.isFinite(configuredMb) && configuredMb > 0 ? configuredMb : 20;
  return megabytes * 1024 * 1024;
};

const sanitizeFileName = (originalName) =>
  String(originalName ?? 'upload')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .slice(-80);

const getAlertById = async (alertId) => {
  const { data, error } = await supabaseAdmin
    .from(ALERTS_TABLE)
    .select('*')
    .eq('id', alertId)
    .maybeSingle();

  if (error) {
    throw wrapDatabaseError(error, ALERTS_TABLE);
  }

  return data;
};

const uploadAlertMedia = async ({ alertId, uploadedBy, file }) => {
  if (!file) {
    throw new AppError('No file was uploaded.', 400, 'media_file_required');
  }

  const alert = await getAlertById(alertId);

  if (!alert) {
    throw new AppError('Alert could not be found.', 404, 'alert_not_found');
  }

  const uploaderProfile = await supabaseAdmin
    .from('users')
    .select('id, role')
    .eq('id', uploadedBy)
    .maybeSingle();

  const isOwner = alert.user_id === uploadedBy;
  const isModerator = isModeratorOrAdmin(uploaderProfile.data);

  if (!isOwner && !isModerator) {
    throw new AppError(
      'Only the person who filed this report (or a moderator) can attach evidence to it.',
      403,
      'media_upload_forbidden'
    );
  }

  const mediaType = MIME_TYPE_TO_MEDIA_TYPE[file.mimetype];

  if (!mediaType) {
    throw new AppError(
      `Unsupported file type "${file.mimetype}". Only images, short videos, and audio clips are accepted.`,
      400,
      'unsupported_media_type'
    );
  }

  if (file.size > getMaxFileSizeBytes()) {
    throw new AppError(
      `File is too large. The maximum allowed size is ${Math.round(getMaxFileSizeBytes() / (1024 * 1024))}MB.`,
      400,
      'media_file_too_large'
    );
  }

  const storagePath = `${alertId}/${crypto.randomUUID()}-${sanitizeFileName(file.originalname)}`;

  const { error: uploadError } = await supabaseAdmin.storage
    .from(getStorageBucket())
    .upload(storagePath, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });

  if (uploadError) {
    throw new AppError(
      `Media upload to storage failed: ${uploadError.message}`,
      502,
      'media_storage_upload_failed'
    );
  }

  const { data: mediaRow, error: insertError } = await supabaseAdmin
    .from(ALERT_MEDIA_TABLE)
    .insert({
      alert_id: alertId,
      uploaded_by: uploadedBy,
      media_type: mediaType,
      storage_path: storagePath,
      mime_type: file.mimetype,
      size_bytes: file.size,
    })
    .select()
    .single();

  if (insertError) {
    throw wrapDatabaseError(insertError, ALERT_MEDIA_TABLE);
  }

  const { data: signedUrlData } = await supabaseAdmin.storage
    .from(getStorageBucket())
    .createSignedUrl(storagePath, SIGNED_URL_EXPIRY_SECONDS);

  return {
    ...mediaRow,
    url: signedUrlData?.signedUrl ?? null,
  };
};

const canViewAlertMedia = ({ alert, viewer }) => {
  if (alert.user_id === viewer.id || isModeratorOrAdmin(viewer)) {
    return true;
  }

  return alert.visibility_level !== VISIBILITY_LEVEL.SENSITIVE;
};

const listAlertMedia = async ({ alertId, viewer }) => {
  const alert = await getAlertById(alertId);

  if (!alert) {
    throw new AppError('Alert could not be found.', 404, 'alert_not_found');
  }

  if (!canViewAlertMedia({ alert, viewer })) {
    throw new AppError(
      'This report has restricted visibility. Only the reporter or a moderator can view its media.',
      403,
      'media_view_forbidden'
    );
  }

  const { data, error } = await supabaseAdmin
    .from(ALERT_MEDIA_TABLE)
    .select('*')
    .eq('alert_id', alertId)
    .order('created_at', { ascending: true });

  if (error) {
    throw wrapDatabaseError(error, ALERT_MEDIA_TABLE);
  }

  const rows = data ?? [];

  const signedRows = await Promise.all(
    rows.map(async (row) => {
      const { data: signedUrlData } = await supabaseAdmin.storage
        .from(getStorageBucket())
        .createSignedUrl(row.storage_path, SIGNED_URL_EXPIRY_SECONDS);

      return { ...row, url: signedUrlData?.signedUrl ?? null };
    })
  );

  return signedRows;
};

module.exports = {
  ALLOWED_MIME_TYPES,
  getMaxFileSizeBytes,
  uploadAlertMedia,
  listAlertMedia,
};
