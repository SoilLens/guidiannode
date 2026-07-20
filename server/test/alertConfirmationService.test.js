const assert = require('node:assert/strict');
const test = require('node:test');

process.env.JWT_SECRET ||= 'test_jwt_secret_with_enough_length_for_unit_tests';

const { createFakeSupabaseAdmin, mockSupabaseClientModule } = require('./helpers/fakeSupabase');

const fake = createFakeSupabaseAdmin();
const restoreSupabaseClientModule = mockSupabaseClientModule(fake.admin);

const alertConfirmationServicePath = require.resolve('../services/alertConfirmationService');
delete require.cache[alertConfirmationServicePath];
const alertConfirmationService = require('../services/alertConfirmationService');

test.after(() => {
  restoreSupabaseClientModule();
});

test('a user cannot confirm, dispute, or flag their own report', async () => {
  fake.setQueues({
    alerts: [{ data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'unverified' }, error: null }],
  });

  await assert.rejects(
    () =>
      alertConfirmationService.confirmAlert({
        alertId: 'alert-1',
        userId: 'reporter-1',
        confirmationType: 'community_confirm',
      }),
    (error) => error.code === 'cannot_confirm_own_alert'
  );
});

test('an unverified alert becomes community_confirmed once the confirmation threshold is reached', async () => {
  fake.setQueues({
    alerts: [
      { data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'unverified' }, error: null },
      { data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'community_confirmed' }, error: null },
    ],
    alert_confirmations: [
      {
        data: { id: 'conf-1', alert_id: 'alert-1', user_id: 'helper-1', confirmation_type: 'community_confirm' },
        error: null,
      },
      {
        data: [
          { alert_id: 'alert-1', confirmation_type: 'community_confirm' },
          { alert_id: 'alert-1', confirmation_type: 'community_confirm' },
        ],
        error: null,
      },
    ],
  });

  const result = await alertConfirmationService.confirmAlert({
    alertId: 'alert-1',
    userId: 'helper-1',
    confirmationType: 'community_confirm',
  });

  assert.equal(result.counts.community_confirm, 2);
  assert.equal(result.alert.verification_status, 'community_confirmed');
});

test('a plain citizen cannot change an alert verification status', async () => {
  fake.setQueues({
    alerts: [
      {
        data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'unverified', visibility_level: 'standard' },
        error: null,
      },
    ],
  });

  await assert.rejects(
    () =>
      alertConfirmationService.setAlertVerification({
        alertId: 'alert-1',
        actor: { id: 'citizen-1', role: 'citizen', verification_status: 'not_requested' },
        verificationStatus: 'responder_confirmed',
      }),
    (error) => error.code === 'responder_or_moderator_access_required'
  );
});

test('an approved medical responder may mark themselves as a confirming responder', async () => {
  fake.setQueues({
    alerts: [
      { data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'unverified' }, error: null },
      { data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'responder_confirmed' }, error: null },
    ],
    moderation_actions: [{ error: null }],
  });

  const updated = await alertConfirmationService.setAlertVerification({
    alertId: 'alert-1',
    actor: { id: 'responder-1', role: 'medical_responder', verification_status: 'approved' },
    verificationStatus: 'responder_confirmed',
  });

  assert.equal(updated.verification_status, 'responder_confirmed');
});

test('an approved responder (not a moderator) cannot mark a report as a false report', async () => {
  fake.setQueues({
    alerts: [{ data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'unverified' }, error: null }],
  });

  await assert.rejects(
    () =>
      alertConfirmationService.setAlertVerification({
        alertId: 'alert-1',
        actor: { id: 'responder-1', role: 'medical_responder', verification_status: 'approved' },
        verificationStatus: 'false_report',
      }),
    (error) => error.code === 'moderator_access_required'
  );
});

test('a moderator can mark a disputed report as a false report and flag it for review', async () => {
  fake.setQueues({
    alerts: [
      { data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'disputed' }, error: null },
      {
        data: { id: 'alert-1', user_id: 'reporter-1', verification_status: 'false_report', moderation_status: 'flagged' },
        error: null,
      },
    ],
    moderation_actions: [{ error: null }],
  });

  const updated = await alertConfirmationService.setAlertVerification({
    alertId: 'alert-1',
    actor: { id: 'moderator-1', role: 'moderator' },
    verificationStatus: 'false_report',
    moderationStatus: 'flagged',
    notes: 'Reviewed community reports; this looks fabricated.',
  });

  assert.equal(updated.verification_status, 'false_report');
  assert.equal(updated.moderation_status, 'flagged');
});
