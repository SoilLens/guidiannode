const crypto = require('crypto');

const { authConfig, buildDebugOtpHelperMessage } = require('../config/authConfig');
const {
  isOtpPurpose,
  normalizeOtpPurpose,
} = require('../constants/otpPurpose');
const { supabaseAdmin } = require('../config/supabaseClient');
const { AppError, wrapDatabaseError } = require('../utils/appError');
const {
  addMinutes,
  generateOtpCode,
  hashOtpCode,
  maskPhoneNumber,
  nowIso,
} = require('../utils/authUtils');
const { sendOtp } = require('./smsService');

const OTP_SESSIONS_TABLE = 'otp_sessions';

const normalizeAndValidatePurpose = (purpose) => {
  const normalizedPurpose = normalizeOtpPurpose(purpose);

  if (!isOtpPurpose(normalizedPurpose)) {
    throw new AppError(
      `Unsupported OTP purpose: ${purpose}`,
      500,
      'unsupported_otp_purpose'
    );
  }

  return normalizedPurpose;
};

const buildSessionDebugMetadata = () => ({
  mode: 'debug',
  auto_verify_ready: authConfig.autoVerifyDebugOtp,
  otp_length: authConfig.primaryOtpLength,
  accepted_codes: authConfig.debugOtpReferences,
});

const buildSessionRealMetadata = () => ({
  mode: 'real',
  auto_verify_ready: false,
  otp_length: authConfig.realOtpLength,
});

const buildOtpResponseMetadata = (otpSession) => {
  const isDebugSession = otpSession?.metadata?.mode === 'debug' && authConfig.debugAuthMode;

  if (!isDebugSession) {
    return null;
  }

  return {
    mode: 'debug',
    helper_message: buildDebugOtpHelperMessage(),
  };
};

const mapOtpSession = (otpSession) => ({
  ...otpSession,
  debug: buildOtpResponseMetadata(otpSession),
});

const updateSessions = async (matchers, payload) => {
  let query = supabaseAdmin.from(OTP_SESSIONS_TABLE).update(payload);

  matchers.forEach(({ column, value }) => {
    query = query.eq(column, value);
  });

  const { error } = await query;

  if (error) {
    throw wrapDatabaseError(error, OTP_SESSIONS_TABLE);
  }
};

const cancelPendingSessions = async ({ phoneNumber, purpose }) => {
  const normalizedPurpose = normalizeAndValidatePurpose(purpose);

  await updateSessions(
    [
      { column: 'phone_number', value: phoneNumber },
      { column: 'purpose', value: normalizedPurpose },
      { column: 'status', value: 'pending' },
    ],
    {
      status: 'cancelled',
      updated_at: nowIso(),
    }
  );
};

const createOtpSession = async ({ phoneNumber, purpose, registrationPayload = null }) => {
  const normalizedPurpose = normalizeAndValidatePurpose(purpose);

  await cancelPendingSessions({ phoneNumber, purpose: normalizedPurpose });

  const isDebugMode = authConfig.debugAuthMode;
  const otpCode = isDebugMode ? authConfig.debugDefaultOtp : generateOtpCode();

  const sessionPayload = {
    id: crypto.randomUUID(),
    phone_number: phoneNumber,
    purpose: normalizedPurpose,
    status: 'pending',
    otp_code_hash: hashOtpCode(otpCode),
    expires_at: addMinutes(authConfig.otpExpiresMinutes),
    attempts: 0,
    max_attempts: authConfig.maxOtpAttempts,
    registration_payload: registrationPayload,
    metadata: isDebugMode ? buildSessionDebugMetadata() : buildSessionRealMetadata(),
    created_at: nowIso(),
    updated_at: nowIso(),
  };

  const { data, error } = await supabaseAdmin
    .from(OTP_SESSIONS_TABLE)
    .insert(sessionPayload)
    .select()
    .single();

  if (error) {
    throw wrapDatabaseError(error, OTP_SESSIONS_TABLE);
  }

  if (isDebugMode) {
    console.log(
      `[auth] Created debug OTP session ${data.id} for ${maskPhoneNumber(phoneNumber)} (${normalizedPurpose}).`
    );

    return mapOtpSession(data);
  }

  try {
    await sendOtp({
      phoneNumber,
      otpCode,
      purpose: normalizedPurpose,
      otpSessionId: data.id,
    });
  } catch (errorToThrow) {
    await updateSessions(
      [{ column: 'id', value: data.id }],
      {
        status: 'cancelled',
        updated_at: nowIso(),
      }
    );

    throw errorToThrow;
  }

  return mapOtpSession(data);
};

const getPendingOtpSession = async ({ phoneNumber, otpSessionId }) => {
  let query = supabaseAdmin.from(OTP_SESSIONS_TABLE).select('*').eq('status', 'pending');

  if (otpSessionId) {
    query = query.eq('id', otpSessionId);
  } else {
    query = query
      .eq('phone_number', phoneNumber)
      .order('created_at', { ascending: false })
      .limit(1);
  }

  const { data, error } = otpSessionId ? await query.maybeSingle() : await query;

  if (error) {
    throw wrapDatabaseError(error, OTP_SESSIONS_TABLE);
  }

  const otpSession = otpSessionId ? data : data?.[0] ?? null;

  if (!otpSession) {
    return null;
  }

  if (phoneNumber && otpSession.phone_number !== phoneNumber) {
    throw new AppError(
      'OTP session does not belong to the supplied phone number',
      400,
      'otp_session_phone_mismatch'
    );
  }

  return otpSession;
};

const getLatestOtpSession = async ({ phoneNumber, otpSessionId }) => {
  let query = supabaseAdmin.from(OTP_SESSIONS_TABLE).select('*');

  if (otpSessionId) {
    query = query.eq('id', otpSessionId);
  } else {
    query = query
      .eq('phone_number', phoneNumber)
      .order('created_at', { ascending: false })
      .limit(1);
  }

  const { data, error } = otpSessionId ? await query.maybeSingle() : await query;

  if (error) {
    throw wrapDatabaseError(error, OTP_SESSIONS_TABLE);
  }

  const otpSession = otpSessionId ? data : data?.[0] ?? null;

  if (!otpSession) {
    return null;
  }

  if (phoneNumber && otpSession.phone_number !== phoneNumber) {
    throw new AppError(
      'OTP session does not belong to the supplied phone number',
      400,
      'otp_session_phone_mismatch'
    );
  }

  return otpSession;
};

const updateOtpSession = async (otpSessionId, payload) => {
  const { data, error } = await supabaseAdmin
    .from(OTP_SESSIONS_TABLE)
    .update({
      ...payload,
      updated_at: nowIso(),
    })
    .eq('id', otpSessionId)
    .select()
    .single();

  if (error) {
    throw wrapDatabaseError(error, OTP_SESSIONS_TABLE);
  }

  return mapOtpSession(data);
};

const expireOtpSession = async (otpSessionId) =>
  updateOtpSession(otpSessionId, {
    status: 'expired',
  });

const rollbackVerifiedOtpSession = async (otpSession) => {
  if (!otpSession?.id) {
    return;
  }

  await updateSessions(
    [
      { column: 'id', value: otpSession.id },
      { column: 'status', value: 'verified' },
    ],
    {
      attempts: Math.max((otpSession.attempts ?? 1) - 1, 0),
      status: 'pending',
      verified_at: null,
      updated_at: nowIso(),
    }
  );
};

const verifyOtpSession = async ({ phoneNumber, otpCode, otpSessionId }) => {
  const otpSession = await getPendingOtpSession({ phoneNumber, otpSessionId });

  if (!otpSession) {
    throw new AppError(
      'No active OTP session found. Request a new code and try again.',
      404,
      'otp_session_not_found'
    );
  }

  const isExpired = new Date(otpSession.expires_at).getTime() <= Date.now();

  if (isExpired) {
    await expireOtpSession(otpSession.id);
    throw new AppError('OTP has expired. Please request a new code.', 410, 'otp_expired');
  }

  if (otpSession.attempts >= otpSession.max_attempts) {
    await expireOtpSession(otpSession.id);
    throw new AppError(
      'OTP attempt limit reached. Please request a new code.',
      429,
      'otp_attempts_exceeded'
    );
  }

  const attempts = otpSession.attempts + 1;
  const isDebugSession = otpSession.metadata?.mode === 'debug' && authConfig.debugAuthMode;
  const isValidOtp = isDebugSession
    ? authConfig.debugOtpValues.includes(otpCode)
    : otpSession.otp_code_hash === hashOtpCode(otpCode);

  if (!isValidOtp) {
    await updateOtpSession(otpSession.id, {
      attempts,
      status: attempts >= otpSession.max_attempts ? 'expired' : otpSession.status,
    });

    throw new AppError('Invalid or expired OTP', 401, 'invalid_otp');
  }

  return updateOtpSession(otpSession.id, {
    attempts,
    status: 'verified',
    verified_at: nowIso(),
  });
};

const resendOtpSession = async ({ phoneNumber, otpSessionId }) => {
  const latestOtpSession = await getLatestOtpSession({ phoneNumber, otpSessionId });

  if (!latestOtpSession) {
    throw new AppError(
      'No OTP session found to resend. Start the auth flow again.',
      404,
      'otp_session_not_found'
    );
  }

  if (latestOtpSession.status === 'verified') {
    throw new AppError('This OTP session is already verified.', 409, 'otp_session_already_verified');
  }

  return createOtpSession({
    phoneNumber: latestOtpSession.phone_number,
    purpose: latestOtpSession.purpose,
    registrationPayload: latestOtpSession.registration_payload,
  });
};

module.exports = {
  buildOtpResponseMetadata,
  createOtpSession,
  rollbackVerifiedOtpSession,
  resendOtpSession,
  verifyOtpSession,
};
