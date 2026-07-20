const { spawnSync } = require('node:child_process');

const files = [
  'server.js',
  'config/databaseReadiness.js',
  'services/authService.js',
  'services/userService.js',
  'services/whatsappVerificationService.js',
  'controllers/whatsappWebhookController.js',
  'controllers/verificationController.js',
  'middleware/rateLimits.js',
  'routes/verificationRoutes.js',
  'scripts/test-live-verification-flow.js',
  'scripts/test-auth-purpose-flow.js',
  'routes/legalRoutes.js',
  'services/classificationService.js',
  'services/classification/aiClassifier.js',
  'services/classification/ruleBasedClassifier.js',
  'services/alertService.js',
  'services/alertConfirmationService.js',
  'services/roleService.js',
  'services/mediaService.js',
  'controllers/alertController.js',
  'controllers/classificationController.js',
  'controllers/roleController.js',
  'controllers/mediaController.js',
  'middleware/requireRole.js',
  'middleware/mediaUpload.js',
  'routes/alertRoutes.js',
  'routes/roleRoutes.js',
  'validation/alertSchemas.js',
  'validation/roleSchemas.js',
  'validation/confirmationSchemas.js',
  'validation/classificationSchemas.js',
  'scripts/run-migrations.js',
];

for (const file of files) {
  const result = spawnSync(process.execPath, ['--check', file], {
    cwd: __dirname + '/..',
    stdio: 'inherit',
  });

  if (result.status !== 0) {
    process.exit(result.status || 1);
  }
}

console.log('Backend syntax checks passed.');
