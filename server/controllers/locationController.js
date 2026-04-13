const locationService = require('../services/locationService');
const { sendError, sendSuccess } = require('../utils/apiResponse');

const updateLocationHandler = async (req, res) => {
  try {
    const payload = req.validated?.body ?? req.body;
    const updatedUser = await locationService.updateUserLocation({
      userId: req.user.id,
      locationPermission: payload.location_permission,
      latitude: payload.latitude,
      longitude: payload.longitude,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Location sharing preferences updated successfully.',
      data: {
        user: updatedUser,
      },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Update Location Error' });
  }
};

module.exports = {
  updateLocationHandler,
};
