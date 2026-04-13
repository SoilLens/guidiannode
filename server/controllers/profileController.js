const userService = require('../services/userService');
const { sendError, sendSuccess } = require('../utils/apiResponse');

const getMyProfileHandler = async (req, res) => {
  try {
    const profile = await userService.getUserProfile(req.user.id);

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Profile fetched successfully.',
      data: {
        profile,
      },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Get Profile Error' });
  }
};

const updateMyProfileHandler = async (req, res) => {
  try {
    const payload = req.validated?.body ?? req.body;
    const profile = await userService.updateUserProfile({
      userId: req.user.id,
      full_name: payload.full_name,
      quarter: payload.quarter,
      emergency_contact: payload.emergency_contact,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Profile updated successfully.',
      data: {
        profile,
      },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Update Profile Error' });
  }
};

module.exports = {
  getMyProfileHandler,
  updateMyProfileHandler,
};
