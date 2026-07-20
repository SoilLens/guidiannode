const express = require('express');
const { verifySession } = require('../middleware/verifySession');
const { validateRequest } = require('../middleware/validateRequest');
const { requireAdministrator } = require('../middleware/requireRole');
const roleController = require('../controllers/roleController');
const {
  requestRoleSchema,
  decideRoleRequestSchema,
  assignRoleDirectlySchema,
  updateAvailabilitySchema,
  targetUserIdParamSchema,
} = require('../validation/roleSchemas');

const router = express.Router();

router.post(
  '/request',
  verifySession,
  validateRequest(requestRoleSchema),
  roleController.requestRoleHandler
);

router.post(
  '/availability',
  verifySession,
  validateRequest(updateAvailabilitySchema),
  roleController.updateAvailabilityHandler
);

// Administrator-only role verification queue. Self-approval is additionally
// blocked in roleService regardless of this middleware.
router.get(
  '/pending',
  verifySession,
  requireAdministrator,
  roleController.listPendingRoleRequestsHandler
);

router.post(
  '/:userId/decision',
  verifySession,
  requireAdministrator,
  validateRequest(targetUserIdParamSchema, 'params'),
  validateRequest(decideRoleRequestSchema),
  roleController.decideRoleRequestHandler
);

router.post(
  '/:userId/assign',
  verifySession,
  requireAdministrator,
  validateRequest(targetUserIdParamSchema, 'params'),
  validateRequest(assignRoleDirectlySchema),
  roleController.assignRoleDirectlyHandler
);

module.exports = router;
