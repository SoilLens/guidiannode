const validateRequest = (schema, source = 'body') => {
  return (req, res, next) => {
    const payload =
      source === 'query'
        ? req.query
        : source === 'params'
          ? req.params
          : req.body;
    const validationResult = schema.safeParse(payload);

    if (!validationResult.success) {
      return res.status(400).json({
        success: false,
        message: 'Request validation failed',
        errors: validationResult.error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      });
    }

    req.validated = {
      ...(req.validated ?? {}),
      [source]: validationResult.data,
    };

    if (source === 'body') {
      req.validatedBody = validationResult.data;
    }

    next();
  };
};

module.exports = { validateRequest };
