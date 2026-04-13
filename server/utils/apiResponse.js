const { AppError } = require('./appError');

const sendSuccess = (
  res,
  {
    statusCode = 200,
    message = 'Request completed successfully.',
    data = null,
    meta = null,
  } = {}
) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
    meta,
  });
};

const sendError = (
  res,
  error,
  { label = 'Request Error', fallbackMessage = 'Internal server error' } = {}
) => {
  const statusCode = error instanceof AppError ? error.statusCode : 500;
  const message = error instanceof AppError ? error.message : fallbackMessage;

  if (statusCode >= 500) {
    console.error(`${label}:`, error);
  } else {
    console.warn(`${label}:`, error.message);
  }

  return res.status(statusCode).json({
    success: false,
    message,
    code: error instanceof AppError ? error.code : 'internal_error',
    details:
      statusCode < 500 && error instanceof AppError
        ? error.details ?? null
        : null,
  });
};

module.exports = {
  sendError,
  sendSuccess,
};
