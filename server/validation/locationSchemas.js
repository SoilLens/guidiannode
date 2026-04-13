const { z } = require('zod');

const rawCoordinateSchema = z.union([z.number(), z.string().trim().min(1)]);
const rawOptionalNumericSchema = z
  .union([z.number(), z.string().trim().min(1)])
  .optional()
  .nullable();

const latitudeSchema = rawCoordinateSchema
  .transform((value) => Number(value))
  .refine((value) => Number.isFinite(value), 'Latitude must be a valid number')
  .refine((value) => value >= -90 && value <= 90, 'Latitude must be between -90 and 90');

const longitudeSchema = rawCoordinateSchema
  .transform((value) => Number(value))
  .refine((value) => Number.isFinite(value), 'Longitude must be a valid number')
  .refine((value) => value >= -180 && value <= 180, 'Longitude must be between -180 and 180');

const optionalNumericSchema = rawOptionalNumericSchema.transform((value) => {
  if (value === undefined || value === null || value === '') {
    return null;
  }

  const normalizedValue = Number(value);
  return Number.isFinite(normalizedValue) ? normalizedValue : null;
});

const updateLocationSchema = z
  .object({
    location_permission: z.coerce.boolean(),
    latitude: latitudeSchema.nullable().optional(),
    longitude: longitudeSchema.nullable().optional(),
    accuracy: optionalNumericSchema.optional(),
    heading: optionalNumericSchema.optional(),
    speed: optionalNumericSchema.optional(),
    source: z.string().trim().min(2).max(50).optional(),
  })
  .superRefine((value, ctx) => {
    const hasLatitude = value.latitude !== undefined && value.latitude !== null;
    const hasLongitude = value.longitude !== undefined && value.longitude !== null;

    if (hasLatitude !== hasLongitude) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: hasLatitude ? ['longitude'] : ['latitude'],
        message: 'Latitude and longitude must be supplied together.',
      });
    }

    if (value.location_permission && (!hasLatitude || !hasLongitude)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['latitude'],
        message: 'Latitude and longitude are required when location sharing is enabled.',
      });
    }
  });

module.exports = {
  updateLocationSchema,
};
