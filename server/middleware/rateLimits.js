const { rateLimit } = require('express-rate-limit');

const buildRateLimitHandler = (message, code) => (req, res) =>
  res.status(429).json({
    success: false,
    message,
    code,
  });

const verificationStartLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many verification requests. Please wait before trying again.',
    'verification_rate_limited'
  ),
});

const verificationStatusLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 240,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many verification status checks. Please wait before retrying.',
    'verification_status_rate_limited'
  ),
});

const verificationConfirmLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many verification confirmation attempts. Please wait before retrying.',
    'verification_confirm_rate_limited'
  ),
});

// A genuine flood of emergencies from one account/IP is either a bug in a
// client retry loop or abuse; either way the fix is to slow it down, not to
// silently drop reports, so the limit stays generous enough for a real
// multi-incident day.
const alertSubmitLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many emergency reports submitted in a short time. Please wait before submitting another.',
    'alert_submit_rate_limited'
  ),
});

const classificationLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 60,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many classification requests. Please wait before trying again.',
    'classification_rate_limited'
  ),
});

const confirmationLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 60,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many confirmation actions. Please wait before trying again.',
    'confirmation_rate_limited'
  ),
});

const mediaUploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  handler: buildRateLimitHandler(
    'Too many media uploads in a short time. Please wait before uploading more evidence.',
    'media_upload_rate_limited'
  ),
});

module.exports = {
  verificationConfirmLimiter,
  verificationStartLimiter,
  verificationStatusLimiter,
  alertSubmitLimiter,
  classificationLimiter,
  confirmationLimiter,
  mediaUploadLimiter,
};
