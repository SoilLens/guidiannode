const express = require('express');
const authController = require('../controllers/authController');
const { validateRequest } = require('../middleware/validateRequest');
const {
  registrationSchema,
  requestOtpSchema,
  resendOtpSchema,
  verifyOtpSchema,
} = require('../validation/authSchemas');

const router = express.Router();

router.post(
  '/request-otp',
  validateRequest(requestOtpSchema),
  authController.requestOtpHandler
);

router.post(
  '/verify-otp',
  validateRequest(verifyOtpSchema),
  authController.verifyOtpHandler
);

router.post(
  '/register',
  validateRequest(registrationSchema),
  authController.registerHandler
);

router.post(
  '/resend-otp',
  validateRequest(resendOtpSchema),
  authController.resendOtpHandler
);

module.exports = router;
