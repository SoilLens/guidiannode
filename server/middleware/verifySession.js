const { verifyAccessToken } = require('../services/sessionService');
const userService = require('../services/userService');

const verifySession = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Missing or invalid authorization header',
      });
    }

    const token = authHeader.split(' ')[1];
    const decodedToken = verifyAccessToken(token);
    const user = await userService.getUserById(decodedToken.sub);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid or expired session',
      });
    }

    req.user = user;
    next();
  } catch (err) {
    if (err?.name === 'JsonWebTokenError' || err?.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid or expired session',
      });
    }

    console.error('Session verification error:', err);
    res.status(500).json({
      success: false,
      message: 'Internal server error during session verification',
    });
  }
};

module.exports = { verifySession };
