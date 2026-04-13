const { z } = require('zod');
const { normalizePhoneNumber } = require('../utils/authUtils');

const phoneNumberSchema = z
  .string()
  .trim()
  .min(8, 'Phone number must be at least 8 digits long')
  .transform(normalizePhoneNumber)
  .refine(
    (value) => /^\+?\d{8,15}$/.test(value),
    'Phone number must contain only digits and may start with +'
  );

const emergencyContactSchema = z.object({
  contact_name: z.string().trim().min(2, 'Emergency contact name is required'),
  phone_number: phoneNumberSchema,
  relationship: z.string().trim().min(2, 'Emergency contact relationship is required'),
});

const updateProfileSchema = z
  .object({
    full_name: z.string().trim().min(2, 'Full name must be at least 2 characters').optional(),
    quarter: z.string().trim().min(2, 'Neighborhood is required').optional(),
    emergency_contact: emergencyContactSchema.optional(),
  })
  .refine(
    (value) =>
      value.full_name !== undefined ||
      value.quarter !== undefined ||
      value.emergency_contact !== undefined,
    {
      message: 'At least one profile field must be supplied.',
      path: [],
    }
  );

module.exports = {
  updateProfileSchema,
};
