const { z } = require('zod');
const { CONFIRMATION_TYPE_VALUES } = require('../constants/alertTrust');
const {
  VERIFICATION_STATUS_VALUES,
  MODERATION_STATUS_VALUES,
} = require('../constants/alertTrust');

const confirmAlertSchema = z.object({
  confirmation_type: z.enum(CONFIRMATION_TYPE_VALUES),
  note: z.string().trim().max(300).optional(),
});

const setAlertVerificationSchema = z
  .object({
    verification_status: z.enum(VERIFICATION_STATUS_VALUES).optional(),
    moderation_status: z.enum(MODERATION_STATUS_VALUES).optional(),
    notes: z.string().trim().max(500).optional(),
  })
  .refine(
    (value) => value.verification_status !== undefined || value.moderation_status !== undefined,
    { message: 'At least one of verification_status or moderation_status must be supplied.', path: [] }
  );

module.exports = {
  confirmAlertSchema,
  setAlertVerificationSchema,
};
