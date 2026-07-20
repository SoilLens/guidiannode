const { supabaseAdmin } = require('../config/supabaseClient');
const { AppError, wrapDatabaseError } = require('../utils/appError');
const {
  VERIFICATION_STATUS,
  MODERATION_STATUS,
  CONFIRMATION_TYPE,
} = require('../constants/alertTrust');
const { isModeratorOrAdmin, hasApprovedSensitiveRole } = require('../constants/roles');

const ALERTS_TABLE = 'alerts';
const CONFIRMATIONS_TABLE = 'alert_confirmations';
const MODERATION_ACTIONS_TABLE = 'moderation_actions';

const COMMUNITY_CONFIRM_THRESHOLD = 2;
const DISPUTE_THRESHOLD = 2;
const FALSE_REPORT_THRESHOLD = 3;

const VERIFICATION_ACTION_TYPE = Object.freeze({
  [VERIFICATION_STATUS.OFFICIALLY_CONFIRMED]: 'alert_verified',
  [VERIFICATION_STATUS.RESPONDER_CONFIRMED]: 'alert_verified',
  [VERIFICATION_STATUS.DISPUTED]: 'alert_disputed_reviewed',
  [VERIFICATION_STATUS.FALSE_REPORT]: 'alert_marked_false',
  [VERIFICATION_STATUS.RESOLVED]: 'alert_resolved_by_moderator',
});

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

const updateAlert = async (alertId, payload) => {
  const { data, error } = await supabaseAdmin
    .from(ALERTS_TABLE)
    .update(payload)
    .eq('id', alertId)
    .select()
    .single();

  if (error) {
    throw wrapDatabaseError(error, ALERTS_TABLE);
  }

  return data;
};

const getConfirmationCounts = async (alertIds) => {
  const uniqueIds = [...new Set(alertIds)].filter(Boolean);

  if (uniqueIds.length === 0) {
    return new Map();
  }

  const { data, error } = await supabaseAdmin
    .from(CONFIRMATIONS_TABLE)
    .select('alert_id, confirmation_type')
    .in('alert_id', uniqueIds);

  if (error) {
    throw wrapDatabaseError(error, CONFIRMATIONS_TABLE);
  }

  const counts = new Map();

  (data ?? []).forEach((row) => {
    if (!counts.has(row.alert_id)) {
      counts.set(row.alert_id, {
        community_confirm: 0,
        dispute: 0,
        false_report: 0,
      });
    }

    counts.get(row.alert_id)[row.confirmation_type] += 1;
  });

  return counts;
};

const getUserConfirmationsForAlerts = async (userId, alertIds) => {
  const uniqueIds = [...new Set(alertIds)].filter(Boolean);

  if (!userId || uniqueIds.length === 0) {
    return new Map();
  }

  const { data, error } = await supabaseAdmin
    .from(CONFIRMATIONS_TABLE)
    .select('alert_id, confirmation_type')
    .eq('user_id', userId)
    .in('alert_id', uniqueIds);

  if (error) {
    throw wrapDatabaseError(error, CONFIRMATIONS_TABLE);
  }

  return new Map((data ?? []).map((row) => [row.alert_id, row.confirmation_type]));
};

const getConfirmationCountsForAlert = async (alertId) => {
  const counts = await getConfirmationCounts([alertId]);
  return (
    counts.get(alertId) ?? {
      community_confirm: 0,
      dispute: 0,
      false_report: 0,
    }
  );
};

const maybeAutoUpdateVerificationStatus = async (alert, counts) => {
  // Never downgrade a status a moderator/responder has already asserted.
  const AUTHORITATIVE_STATUSES = [
    VERIFICATION_STATUS.RESPONDER_CONFIRMED,
    VERIFICATION_STATUS.OFFICIALLY_CONFIRMED,
    VERIFICATION_STATUS.RESOLVED,
  ];

  if (AUTHORITATIVE_STATUSES.includes(alert.verification_status)) {
    return alert;
  }

  if (counts.false_report >= FALSE_REPORT_THRESHOLD) {
    return updateAlert(alert.id, {
      verification_status: VERIFICATION_STATUS.FALSE_REPORT,
      moderation_status: MODERATION_STATUS.FLAGGED,
      requires_moderator_attention: true,
    });
  }

  if (counts.dispute >= DISPUTE_THRESHOLD) {
    return updateAlert(alert.id, {
      verification_status: VERIFICATION_STATUS.DISPUTED,
      requires_moderator_attention: true,
    });
  }

  if (
    counts.community_confirm >= COMMUNITY_CONFIRM_THRESHOLD &&
    alert.verification_status === VERIFICATION_STATUS.UNVERIFIED
  ) {
    return updateAlert(alert.id, {
      verification_status: VERIFICATION_STATUS.COMMUNITY_CONFIRMED,
    });
  }

  return alert;
};

const confirmAlert = async ({ alertId, userId, confirmationType, note }) => {
  const alert = await getAlertById(alertId);

  if (!alert) {
    throw new AppError('Alert could not be found.', 404, 'alert_not_found');
  }

  if (alert.user_id === userId) {
    throw new AppError('You cannot confirm, dispute, or flag your own report.', 409, 'cannot_confirm_own_alert');
  }

  const { data, error } = await supabaseAdmin
    .from(CONFIRMATIONS_TABLE)
    .upsert(
      {
        alert_id: alertId,
        user_id: userId,
        confirmation_type: confirmationType,
        note: note ?? null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: 'alert_id,user_id' }
    )
    .select()
    .single();

  if (error) {
    throw wrapDatabaseError(error, CONFIRMATIONS_TABLE);
  }

  const counts = await getConfirmationCountsForAlert(alertId);
  const updatedAlert = await maybeAutoUpdateVerificationStatus(alert, counts);

  return { confirmation: data, counts, alert: updatedAlert };
};

const setAlertVerification = async ({
  alertId,
  actor,
  verificationStatus,
  moderationStatus,
  notes,
}) => {
  const alert = await getAlertById(alertId);

  if (!alert) {
    throw new AppError('Alert could not be found.', 404, 'alert_not_found');
  }

  const actorIsModerator = isModeratorOrAdmin(actor);
  const actorIsApprovedResponder = hasApprovedSensitiveRole(actor);

  if (!actorIsModerator && !actorIsApprovedResponder) {
    throw new AppError(
      'An approved responder role or moderator access is required to change verification status.',
      403,
      'responder_or_moderator_access_required'
    );
  }

  // Plain (non-moderator) responders may only assert their own confirmation;
  // marking a report false, disputed, officially confirmed, or resolved
  // requires moderator/administrator authority.
  const RESPONDER_ALLOWED_STATUSES = [VERIFICATION_STATUS.RESPONDER_CONFIRMED];

  if (
    verificationStatus &&
    !actorIsModerator &&
    !RESPONDER_ALLOWED_STATUSES.includes(verificationStatus)
  ) {
    throw new AppError(
      'Only a moderator or administrator can set this verification status.',
      403,
      'moderator_access_required'
    );
  }

  if (moderationStatus && !actorIsModerator) {
    throw new AppError(
      'Only a moderator or administrator can change moderation status.',
      403,
      'moderator_access_required'
    );
  }

  const payload = {};

  if (verificationStatus) {
    payload.verification_status = verificationStatus;
  }

  if (moderationStatus) {
    payload.moderation_status = moderationStatus;
  }

  if (actorIsModerator) {
    payload.moderated_by = actor.id;
    payload.moderated_at = new Date().toISOString();
    if (notes) {
      payload.moderation_notes = notes;
    }
  }

  const updatedAlert = await updateAlert(alertId, payload);

  const actionType = verificationStatus
    ? VERIFICATION_ACTION_TYPE[verificationStatus] ?? 'other'
    : 'other';

  const { error: logError } = await supabaseAdmin.from(MODERATION_ACTIONS_TABLE).insert({
    action_type: actionType,
    alert_id: alertId,
    performed_by: actor.id,
    notes: notes ?? null,
    metadata: { verification_status: verificationStatus ?? null, moderation_status: moderationStatus ?? null },
  });

  if (logError) {
    console.warn('Moderation action log failed:', logError.message);
  }

  return updatedAlert;
};

module.exports = {
  CONFIRMATION_TYPE,
  confirmAlert,
  getConfirmationCounts,
  getConfirmationCountsForAlert,
  getUserConfirmationsForAlerts,
  setAlertVerification,
};
