const OTP_PURPOSE = Object.freeze({
  REGISTER: 'register',
  LOGIN: 'login',
  RESET_PASSWORD: 'reset_password',
  VERIFY_PHONE: 'verify_phone',
});

const OTP_PURPOSE_VALUES = Object.freeze(Object.values(OTP_PURPOSE));

const LEGACY_OTP_PURPOSE_ALIASES = Object.freeze({
  registration: OTP_PURPOSE.REGISTER,
});

const normalizeOtpPurpose = (value) => LEGACY_OTP_PURPOSE_ALIASES[value] ?? value;

const isOtpPurpose = (value) => OTP_PURPOSE_VALUES.includes(normalizeOtpPurpose(value));

module.exports = {
  OTP_PURPOSE,
  OTP_PURPOSE_VALUES,
  normalizeOtpPurpose,
  isOtpPurpose,
};
