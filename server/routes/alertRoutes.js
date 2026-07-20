const express = require('express');
const { verifySession } = require('../middleware/verifySession');
const { validateRequest } = require('../middleware/validateRequest');
const {
  alertSubmitLimiter,
  classificationLimiter,
  confirmationLimiter,
  mediaUploadLimiter,
} = require('../middleware/rateLimits');
const { mediaUploadSingle } = require('../middleware/mediaUpload');
const alertController = require('../controllers/alertController');
const classificationController = require('../controllers/classificationController');
const mediaController = require('../controllers/mediaController');
const {
  alertIdParamSchema,
  createSosAlertSchema,
  nearbyAlertsQuerySchema,
  respondToAlertSchema,
  responderFollowQuerySchema,
  updateAlertLocationSchema,
} = require('../validation/alertSchemas');
const { classifyReportSchema } = require('../validation/classificationSchemas');
const {
  confirmAlertSchema,
  setAlertVerificationSchema,
} = require('../validation/confirmationSchemas');

const router = express.Router();

router.post(
  '/classify',
  verifySession,
  classificationLimiter,
  validateRequest(classifyReportSchema),
  classificationController.classifyReportHandler
);

router.post(
  '/sos',
  verifySession,
  alertSubmitLimiter,
  validateRequest(createSosAlertSchema),
  alertController.createSosAlertHandler
);

router.get(
  '/nearby',
  verifySession,
  validateRequest(nearbyAlertsQuerySchema, 'query'),
  alertController.getNearbyAlertsHandler
);

router.get(
  '/:alertId/follow',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  validateRequest(responderFollowQuerySchema, 'query'),
  alertController.getResponderFollowDetailsHandler
);

router.post(
  '/:alertId/respond',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  validateRequest(respondToAlertSchema),
  alertController.respondToAlertHandler
);

router.post(
  '/:alertId/location',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  validateRequest(updateAlertLocationSchema),
  alertController.updateLiveAlertLocationHandler
);

router.post(
  '/:alertId/resolve',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  alertController.resolveAlertHandler
);

router.post(
  '/:alertId/confirmations',
  verifySession,
  confirmationLimiter,
  validateRequest(alertIdParamSchema, 'params'),
  validateRequest(confirmAlertSchema),
  alertController.confirmAlertHandler
);

router.post(
  '/:alertId/verification',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  validateRequest(setAlertVerificationSchema),
  alertController.setAlertVerificationHandler
);

router.post(
  '/:alertId/media',
  verifySession,
  mediaUploadLimiter,
  validateRequest(alertIdParamSchema, 'params'),
  mediaUploadSingle('file'),
  mediaController.uploadAlertMediaHandler
);

router.get(
  '/:alertId/media',
  verifySession,
  validateRequest(alertIdParamSchema, 'params'),
  mediaController.listAlertMediaHandler
);

module.exports = router;
