const jwt = require('jsonwebtoken');
const { authConfig } = require('../config/authConfig');

const createAppSession = (user) => {
  const issuedAt = new Date();
  const expiresAt = new Date(issuedAt.getTime() + authConfig.sessionExpiresInSeconds * 1000);

  const token = jwt.sign(
    {
      sub: user.id,
      phone_number: user.phone_number,
      type: 'guardian_node_access',
    },
    authConfig.jwtSecret,
    {
      expiresIn: authConfig.jwtExpiresIn,
    }
  );

  return {
    access_token: token,
    token_type: 'Bearer',
    expires_in: authConfig.sessionExpiresInSeconds,
    issued_at: issuedAt.toISOString(),
    expires_at: expiresAt.toISOString(),
    user,
  };
};

const verifyAccessToken = (token) => jwt.verify(token, authConfig.jwtSecret);

module.exports = {
  createAppSession,
  verifyAccessToken,
};
