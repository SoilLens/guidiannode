const { supabaseAdmin } = require('../config/supabaseClient');
const { AppError, wrapDatabaseError } = require('../utils/appError');
const {
  SELF_ASSIGNABLE_ROLES,
  REQUESTABLE_SENSITIVE_ROLES,
  VERIFICATION_STATUS,
} = require('../constants/roles');

const USERS_TABLE = 'users';
const MODERATION_ACTIONS_TABLE = 'moderation_actions';

const getUserById = async (userId) => {
  const { data, error } = await supabaseAdmin
    .from(USERS_TABLE)
    .select('*')
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return data;
};

const updateUser = async (userId, payload) => {
  const { data, error } = await supabaseAdmin
    .from(USERS_TABLE)
    .update(payload)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return data;
};

const logModerationAction = async ({
  actionType,
  targetUserId = null,
  alertId = null,
  performedBy,
  notes = null,
  metadata = {},
}) => {
  const { error } = await supabaseAdmin.from(MODERATION_ACTIONS_TABLE).insert({
    action_type: actionType,
    target_user_id: targetUserId,
    alert_id: alertId,
    performed_by: performedBy,
    notes,
    metadata,
  });

  if (error) {
    throw wrapDatabaseError(error, MODERATION_ACTIONS_TABLE);
  }
};

const requestRole = async ({
  userId,
  requestedRole,
  assistanceCapabilities,
  serviceRadiusMeters,
  organisation,
  verificationNotes,
}) => {
  const isSelfAssignable = SELF_ASSIGNABLE_ROLES.includes(requestedRole);
  const isRequestableSensitive = REQUESTABLE_SENSITIVE_ROLES.includes(requestedRole);

  if (!isSelfAssignable && !isRequestableSensitive) {
    throw new AppError(
      'This role cannot be self-requested. Ask an administrator to assign it.',
      400,
      'role_not_requestable'
    );
  }

  const user = await getUserById(userId);

  if (!user) {
    throw new AppError('User profile could not be found.', 404, 'user_not_found');
  }

  if (isSelfAssignable) {
    return updateUser(userId, { role: requestedRole });
  }

  return updateUser(userId, {
    requested_role: requestedRole,
    verification_status: VERIFICATION_STATUS.PENDING,
    assistance_capabilities: assistanceCapabilities ?? [],
    service_radius_meters: serviceRadiusMeters ?? null,
    organisation: organisation ?? null,
    verification_notes: verificationNotes ?? null,
    verification_date: null,
    verified_by: null,
  });
};

const listPendingRoleRequests = async () => {
  const { data, error } = await supabaseAdmin
    .from(USERS_TABLE)
    .select(
      'id, full_name, phone_number, quarter, requested_role, verification_status, assistance_capabilities, service_radius_meters, organisation, verification_notes, created_at'
    )
    .eq('verification_status', VERIFICATION_STATUS.PENDING)
    .order('created_at', { ascending: true });

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return data ?? [];
};

const decideRoleRequest = async ({ targetUserId, decision, performedBy, notes }) => {
  if (targetUserId === performedBy) {
    throw new AppError(
      'You cannot approve, reject, or suspend your own role request.',
      403,
      'self_approval_not_allowed'
    );
  }

  const target = await getUserById(targetUserId);

  if (!target) {
    throw new AppError('User could not be found.', 404, 'user_not_found');
  }

  if (decision === 'approved') {
    if (!target.requested_role) {
      throw new AppError(
        'This user has no pending role request to approve.',
        409,
        'no_pending_role_request'
      );
    }

    const updated = await updateUser(targetUserId, {
      role: target.requested_role,
      verification_status: VERIFICATION_STATUS.APPROVED,
      verification_date: new Date().toISOString(),
      verified_by: performedBy,
    });
    await logModerationAction({ actionType: 'role_approved', targetUserId, performedBy, notes });
    return updated;
  }

  if (decision === 'rejected') {
    const updated = await updateUser(targetUserId, {
      verification_status: VERIFICATION_STATUS.REJECTED,
      verified_by: performedBy,
      verification_date: new Date().toISOString(),
    });
    await logModerationAction({ actionType: 'role_rejected', targetUserId, performedBy, notes });
    return updated;
  }

  const updated = await updateUser(targetUserId, {
    verification_status: VERIFICATION_STATUS.SUSPENDED,
    verified_by: performedBy,
    verification_date: new Date().toISOString(),
  });
  await logModerationAction({ actionType: 'role_suspended', targetUserId, performedBy, notes });
  return updated;
};

const assignRoleDirectly = async ({ targetUserId, role, performedBy, notes }) => {
  if (targetUserId === performedBy) {
    throw new AppError('You cannot change your own role.', 403, 'self_approval_not_allowed');
  }

  const updated = await updateUser(targetUserId, {
    role,
    verification_status: VERIFICATION_STATUS.APPROVED,
    verification_date: new Date().toISOString(),
    verified_by: performedBy,
    requested_role: null,
  });
  await logModerationAction({
    actionType: 'role_approved',
    targetUserId,
    performedBy,
    notes: notes ?? `Directly assigned role "${role}".`,
  });
  return updated;
};

const updateAvailability = async ({ userId, availabilityStatus }) =>
  updateUser(userId, { availability_status: availabilityStatus });

module.exports = {
  requestRole,
  listPendingRoleRequests,
  decideRoleRequest,
  assignRoleDirectly,
  updateAvailability,
};
