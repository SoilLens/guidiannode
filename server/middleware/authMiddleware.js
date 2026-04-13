const supabase = require('../services/supabaseClient');

const verifyAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Missing or invalid authorization header',
      });
    }

    const token = authHeader.split(' ')[1];
    
    // Verify the JWT token using Supabase User Auth
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized: Invalid token',
        error: error?.message
      });
    }

    // Attach the authenticated Supabase user object to the request
    req.user = user;
    next();
  } catch (err) {
    console.error('Error verifying auth token:', err);
    res.status(500).json({
      success: false,
      message: 'Internal server error during authentication',
    });
  }
};

module.exports = { verifyAuth };
