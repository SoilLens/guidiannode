const multer = require('multer');
const { ALLOWED_MIME_TYPES, getMaxFileSizeBytes } = require('../services/mediaService');

// Memory storage only -- nothing ever touches disk. mediaService re-checks
// mime type and size again before writing to Supabase Storage, so this is
// the first of two independent gates against dangerous or oversized files.
const mediaUpload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: getMaxFileSizeBytes(),
    files: 1,
  },
  fileFilter: (req, file, callback) => {
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      callback(new multer.MulterError('LIMIT_UNEXPECTED_FILE', 'file'));
      return;
    }

    callback(null, true);
  },
});

const mediaUploadSingle = (fieldName) => (req, res, next) => {
  mediaUpload.single(fieldName)(req, res, (error) => {
    if (!error) {
      next();
      return;
    }

    if (error instanceof multer.MulterError) {
      const message =
        error.code === 'LIMIT_FILE_SIZE'
          ? `File is too large. The maximum allowed size is ${Math.round(getMaxFileSizeBytes() / (1024 * 1024))}MB.`
          : 'Unsupported file type. Only images, short videos, and audio clips are accepted.';

      res.status(400).json({ success: false, message, code: 'media_upload_rejected' });
      return;
    }

    next(error);
  });
};

module.exports = { mediaUpload, mediaUploadSingle };
