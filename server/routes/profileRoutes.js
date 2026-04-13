const express = require('express');
const profileController = require('../controllers/profileController');
const { verifySession } = require('../middleware/verifySession');
const { validateRequest } = require('../middleware/validateRequest');
const { updateProfileSchema } = require('../validation/profileSchemas');

const router = express.Router();

router.get('/me', verifySession, profileController.getMyProfileHandler);

router.put(
  '/me',
  verifySession,
  validateRequest(updateProfileSchema),
  profileController.updateMyProfileHandler
);

module.exports = router;
