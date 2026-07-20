const { z } = require('zod');

const classifyReportSchema = z.object({
  description: z.string().trim().min(3).max(1000),
});

module.exports = {
  classifyReportSchema,
};
