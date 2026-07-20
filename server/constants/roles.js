const ROLE = Object.freeze({
  CITIZEN: 'citizen',
  COMMUNITY_HELPER: 'community_helper',
  VERIFIED_RESPONDER: 'verified_responder',
  MEDICAL_RESPONDER: 'medical_responder',
  SECURITY_RESPONDER: 'security_responder',
  HUMANITARIAN_RESPONDER: 'humanitarian_responder',
  MODERATOR: 'moderator',
  ADMINISTRATOR: 'administrator',
});

const ROLE_VALUES = Object.freeze(Object.values(ROLE));

// Citizens may self-select these roles immediately; no admin verification
// is required because they grant no elevated data access or capability.
const SELF_ASSIGNABLE_ROLES = Object.freeze([ROLE.CITIZEN, ROLE.COMMUNITY_HELPER]);

// These roles unlock elevated capability (exact victim location, responder
// tooling, moderation actions) and must be granted by an administrator.
const SENSITIVE_ROLES = Object.freeze([
  ROLE.VERIFIED_RESPONDER,
  ROLE.MEDICAL_RESPONDER,
  ROLE.SECURITY_RESPONDER,
  ROLE.HUMANITARIAN_RESPONDER,
  ROLE.MODERATOR,
  ROLE.ADMINISTRATOR,
]);

// Administrator is never granted through the public role-request flow; it
// can only be assigned directly by an existing administrator.
const REQUESTABLE_SENSITIVE_ROLES = Object.freeze([
  ROLE.VERIFIED_RESPONDER,
  ROLE.MEDICAL_RESPONDER,
  ROLE.SECURITY_RESPONDER,
  ROLE.HUMANITARIAN_RESPONDER,
]);

const RESPONDER_ROLES = Object.freeze([
  ROLE.VERIFIED_RESPONDER,
  ROLE.MEDICAL_RESPONDER,
  ROLE.SECURITY_RESPONDER,
  ROLE.HUMANITARIAN_RESPONDER,
]);

const VERIFICATION_STATUS = Object.freeze({
  NOT_REQUESTED: 'not_requested',
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  SUSPENDED: 'suspended',
});

const VERIFICATION_STATUS_VALUES = Object.freeze(Object.values(VERIFICATION_STATUS));

const AVAILABILITY_STATUS = Object.freeze({
  AVAILABLE: 'available',
  BUSY: 'busy',
  OFFLINE: 'offline',
});

const AVAILABILITY_STATUS_VALUES = Object.freeze(Object.values(AVAILABILITY_STATUS));

const isSensitiveRole = (role) => SENSITIVE_ROLES.includes(role);

const isRequestableSensitiveRole = (role) => REQUESTABLE_SENSITIVE_ROLES.includes(role);

// A user's role only grants sensitive access while it was actually approved
// and has not since been suspended/rejected. This lets an administrator
// suspend access without mutating the historical `role` column.
const hasApprovedSensitiveRole = (user) =>
  isSensitiveRole(user?.role) && user?.verification_status === VERIFICATION_STATUS.APPROVED;

const isModeratorOrAdmin = (user) =>
  user?.role === ROLE.MODERATOR || user?.role === ROLE.ADMINISTRATOR;

const isAdministrator = (user) => user?.role === ROLE.ADMINISTRATOR;

const canActAsResponder = (user) =>
  user?.role === ROLE.COMMUNITY_HELPER || hasApprovedSensitiveRole(user) || isModeratorOrAdmin(user);

module.exports = {
  ROLE,
  ROLE_VALUES,
  SELF_ASSIGNABLE_ROLES,
  SENSITIVE_ROLES,
  REQUESTABLE_SENSITIVE_ROLES,
  RESPONDER_ROLES,
  VERIFICATION_STATUS,
  VERIFICATION_STATUS_VALUES,
  AVAILABILITY_STATUS,
  AVAILABILITY_STATUS_VALUES,
  isSensitiveRole,
  isRequestableSensitiveRole,
  hasApprovedSensitiveRole,
  isModeratorOrAdmin,
  isAdministrator,
  canActAsResponder,
};
