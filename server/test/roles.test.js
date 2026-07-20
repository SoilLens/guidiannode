const assert = require('node:assert/strict');
const test = require('node:test');

process.env.JWT_SECRET ||= 'test_jwt_secret_with_enough_length_for_unit_tests';

const {
  ROLE,
  VERIFICATION_STATUS,
  isSensitiveRole,
  hasApprovedSensitiveRole,
  isModeratorOrAdmin,
  canActAsResponder,
} = require('../constants/roles');
const roleService = require('../services/roleService');

test('citizen and community_helper are not sensitive roles', () => {
  assert.equal(isSensitiveRole(ROLE.CITIZEN), false);
  assert.equal(isSensitiveRole(ROLE.COMMUNITY_HELPER), false);
});

test('responder/medical/security/humanitarian roles and moderator/administrator are sensitive', () => {
  [
    ROLE.VERIFIED_RESPONDER,
    ROLE.MEDICAL_RESPONDER,
    ROLE.SECURITY_RESPONDER,
    ROLE.HUMANITARIAN_RESPONDER,
    ROLE.MODERATOR,
    ROLE.ADMINISTRATOR,
  ].forEach((role) => assert.equal(isSensitiveRole(role), true, `${role} should be sensitive`));
});

test('a sensitive role only grants elevated access once verification_status is approved', () => {
  const pendingUser = { role: ROLE.MEDICAL_RESPONDER, verification_status: VERIFICATION_STATUS.PENDING };
  const approvedUser = { role: ROLE.MEDICAL_RESPONDER, verification_status: VERIFICATION_STATUS.APPROVED };
  const suspendedUser = { role: ROLE.MEDICAL_RESPONDER, verification_status: VERIFICATION_STATUS.SUSPENDED };

  assert.equal(hasApprovedSensitiveRole(pendingUser), false);
  assert.equal(hasApprovedSensitiveRole(approvedUser), true);
  assert.equal(hasApprovedSensitiveRole(suspendedUser), false);
});

test('moderator and administrator are recognised regardless of verification_status', () => {
  assert.equal(isModeratorOrAdmin({ role: ROLE.MODERATOR }), true);
  assert.equal(isModeratorOrAdmin({ role: ROLE.ADMINISTRATOR }), true);
  assert.equal(isModeratorOrAdmin({ role: ROLE.CITIZEN }), false);
});

test('community helpers and approved responders can act as a responder; plain citizens cannot claim elevated capability', () => {
  assert.equal(canActAsResponder({ role: ROLE.COMMUNITY_HELPER }), true);
  assert.equal(
    canActAsResponder({ role: ROLE.VERIFIED_RESPONDER, verification_status: VERIFICATION_STATUS.APPROVED }),
    true
  );
  assert.equal(
    canActAsResponder({ role: ROLE.VERIFIED_RESPONDER, verification_status: VERIFICATION_STATUS.PENDING }),
    false
  );
  assert.equal(canActAsResponder({ role: ROLE.CITIZEN }), false);
});

test('administrator and moderator cannot be self-requested through the public role-request flow', async () => {
  await assert.rejects(
    () => roleService.requestRole({ userId: 'user-1', requestedRole: ROLE.ADMINISTRATOR }),
    (error) => error.code === 'role_not_requestable'
  );
  await assert.rejects(
    () => roleService.requestRole({ userId: 'user-1', requestedRole: ROLE.MODERATOR }),
    (error) => error.code === 'role_not_requestable'
  );
});

test('an administrator cannot approve, reject, or suspend their own role request', async () => {
  await assert.rejects(
    () =>
      roleService.decideRoleRequest({
        targetUserId: 'admin-1',
        performedBy: 'admin-1',
        decision: 'approved',
      }),
    (error) => error.code === 'self_approval_not_allowed'
  );
});

test('an administrator cannot directly assign a role to themselves', async () => {
  await assert.rejects(
    () =>
      roleService.assignRoleDirectly({
        targetUserId: 'admin-1',
        performedBy: 'admin-1',
        role: ROLE.MODERATOR,
      }),
    (error) => error.code === 'self_approval_not_allowed'
  );
});
