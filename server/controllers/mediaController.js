const mediaService = require('../services/mediaService');
const { sendError, sendSuccess } = require('../utils/apiResponse');

const uploadAlertMediaHandler = async (req, res) => {
  try {
    const params = req.validated?.params ?? req.params;
    const media = await mediaService.uploadAlertMedia({
      alertId: params.alertId,
      uploadedBy: req.user.id,
      file: req.file,
    });

    return sendSuccess(res, {
      statusCode: 201,
      message: 'Evidence uploaded successfully.',
      data: { media },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Upload Alert Media Error' });
  }
};

const listAlertMediaHandler = async (req, res) => {
  try {
    const params = req.validated?.params ?? req.params;
    const media = await mediaService.listAlertMedia({
      alertId: params.alertId,
      viewer: req.user,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Alert media fetched successfully.',
      data: { media },
    });
  } catch (error) {
    return sendError(res, error, { label: 'List Alert Media Error' });
  }
};

module.exports = {
  uploadAlertMediaHandler,
  listAlertMediaHandler,
};
