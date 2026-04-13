const { authConfig } = require('../config/authConfig');
const { AppError } = require('../utils/appError');

const sendOtp = async ({ phoneNumber, purpose }) => {
  if (authConfig.debugAuthMode) {
    return {
      delivered: false,
      provider: 'debug',
      phone_number: phoneNumber,
      purpose,
    };
  }

  throw new AppError(
    'Real SMS provider integration is not configured yet. Keep DEBUG_AUTH_MODE=true until provider keys are added and smsService is wired to the provider.',
    503,
    'sms_provider_not_configured'
  );
};

module.exports = {
  sendOtp,
};
