const express = require('express');
const { verifySession } = require('../middleware/verifySession');
const { validateRequest } = require('../middleware/validateRequest');
const locationController = require('../controllers/locationController');
const { updateLocationSchema } = require('../validation/locationSchemas');

const router = express.Router();

router.post(
  '/update',
  verifySession,
  validateRequest(updateLocationSchema),
  locationController.updateLocationHandler
);

module.exports = router;
