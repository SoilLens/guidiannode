const { z } = require('zod');
const {
  SELF_ASSIGNABLE_ROLES,
  REQUESTABLE_SENSITIVE_ROLES,
  ROLE_VALUES,
  AVAILABILITY_STATUS_VALUES,
} = require('../constants/roles');
const { ASSISTANCE_TYPE_VALUES } = require('../constants/incidentTaxonomy');

const requestRoleSchema = z.object({
  requested_role: z.enum([...SELF_ASSIGNABLE_ROLES, ...REQUESTABLE_SENSITIVE_ROLES]),
  assistance_capabilities: z.array(z.enum(ASSISTANCE_TYPE_VALUES)).max(10).optional(),
  service_radius_meters: z.coerce.number().int().min(100).max(50000).optional(),
  organisation: z.string().trim().max(120).optional(),
  verification_notes: z.string().trim().max(1000).optional(),
});

const decideRoleRequestSchema = z.object({
  decision: z.enum(['approved', 'rejected', 'suspended']),
  notes: z.string().trim().max(500).optional(),
});

const assignRoleDirectlySchema = z.object({
  role: z.enum(ROLE_VALUES),
  notes: z.string().trim().max(500).optional(),
});

const updateAvailabilitySchema = z.object({
  availability_status: z.enum(AVAILABILITY_STATUS_VALUES),
});

const targetUserIdParamSchema = z.object({
  userId: z.string().trim().uuid('userId must be a valid UUID'),
});

module.exports = {
  requestRoleSchema,
  decideRoleRequestSchema,
  assignRoleDirectlySchema,
  updateAvailabilitySchema,
  targetUserIdParamSchema,
};
