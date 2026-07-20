const classificationService = require('../services/classificationService');
const { sendError, sendSuccess } = require('../utils/apiResponse');

const classifyReportHandler = async (req, res) => {
  try {
    const payload = req.validated?.body ?? req.body;
    const classification = await classificationService.classifyIncidentReport({
      description: payload.description,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Report classified successfully.',
      data: {
        classification,
        ai_configured: classificationService.isAiConfigured(),
      },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Classify Report Error' });
  }
};

module.exports = {
  classifyReportHandler,
};
