const { AppError } = require('../../utils/appError');
const {
  INCIDENT_CATEGORY_VALUES,
  URGENCY_LEVEL_VALUES,
  DETECTED_LANGUAGE_VALUES,
} = require('../../constants/incidentTaxonomy');

const ANTHROPIC_MESSAGES_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';
const DEFAULT_MODEL = 'claude-haiku-4-5-20251001';
const DEFAULT_TIMEOUT_MS = 6000;

const getConfig = () => ({
  apiKey: process.env.ANTHROPIC_API_KEY,
  model: process.env.AI_CLASSIFICATION_MODEL || DEFAULT_MODEL,
  timeoutMs: Number.parseInt(process.env.AI_CLASSIFICATION_TIMEOUT_MS, 10) || DEFAULT_TIMEOUT_MS,
});

const isConfigured = () => Boolean(getConfig().apiKey);

const SYSTEM_PROMPT = `You are an advisory emergency-report triage assistant for GuardianNode, a community crisis-reporting app in Cameroon. You never take autonomous action and you never confirm whether a report is true -- you only suggest a category and urgency for a human to review.

Respond with strict JSON only, no markdown fences, matching exactly this shape:
{
  "category": one of ${JSON.stringify(INCIDENT_CATEGORY_VALUES)},
  "urgency": one of ${JSON.stringify(URGENCY_LEVEL_VALUES)},
  "detected_language": one of ${JSON.stringify(DETECTED_LANGUAGE_VALUES)},
  "explanation": a short plain-language sentence (max 200 characters) explaining the suggestion,
  "confidence": a number between 0 and 1,
  "recommended_action": a short practical next step (max 200 characters),
  "requires_moderator_attention": boolean,
  "possible_spam": boolean,
  "assistance_needed": an array of short lowercase snake_case tags such as "medical", "security", "fire_rescue", "transport", "shelter", "food_water", "search", "counselling", "translation", "general"
}

The report may be written in English, French, or Cameroon Pidgin. Do not refuse to classify based on language. If the text is too vague to classify, use category "other" and set requires_moderator_attention to true.`;

const buildUserPrompt = (description) =>
  `Classify this emergency report submitted by a resident:\n"""${description}"""`;

const stripCodeFences = (text) =>
  text
    .trim()
    .replace(/^```(?:json)?/i, '')
    .replace(/```$/, '')
    .trim();

const classify = async (description) => {
  const { apiKey, model, timeoutMs } = getConfig();

  if (!apiKey) {
    throw new AppError('AI classification provider is not configured.', 503, 'ai_provider_not_configured');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetch(ANTHROPIC_MESSAGES_URL, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': ANTHROPIC_VERSION,
      },
      body: JSON.stringify({
        model,
        max_tokens: 400,
        system: SYSTEM_PROMPT,
        messages: [{ role: 'user', content: buildUserPrompt(description) }],
      }),
      signal: controller.signal,
    });
  } catch (error) {
    if (error?.name === 'AbortError') {
      throw new AppError('AI classification request timed out.', 504, 'ai_classification_timeout');
    }
    throw new AppError(`AI classification request failed: ${error.message}`, 502, 'ai_classification_request_failed');
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const bodyText = await response.text().catch(() => '');
    throw new AppError(
      `AI classification provider returned status ${response.status}.`,
      502,
      'ai_classification_provider_error',
      bodyText.slice(0, 500)
    );
  }

  const payload = await response.json();
  const rawText = Array.isArray(payload?.content)
    ? payload.content.map((block) => block?.text ?? '').join('')
    : '';

  if (!rawText) {
    throw new AppError('AI classification provider returned an empty response.', 502, 'ai_classification_empty_response');
  }

  let parsed;
  try {
    parsed = JSON.parse(stripCodeFences(rawText));
  } catch (error) {
    throw new AppError('AI classification response was not valid JSON.', 502, 'ai_classification_invalid_json');
  }

  if (!INCIDENT_CATEGORY_VALUES.includes(parsed.category)) {
    throw new AppError('AI classification returned an unrecognised category.', 502, 'ai_classification_invalid_category');
  }

  if (!URGENCY_LEVEL_VALUES.includes(parsed.urgency)) {
    throw new AppError('AI classification returned an unrecognised urgency level.', 502, 'ai_classification_invalid_urgency');
  }

  return {
    category: parsed.category,
    urgency: parsed.urgency,
    detected_language: DETECTED_LANGUAGE_VALUES.includes(parsed.detected_language)
      ? parsed.detected_language
      : 'unknown',
    explanation: String(parsed.explanation ?? '').slice(0, 200),
    confidence: Number.isFinite(Number(parsed.confidence))
      ? Math.min(1, Math.max(0, Number(parsed.confidence)))
      : 0.5,
    recommended_action: String(parsed.recommended_action ?? '').slice(0, 200),
    requires_moderator_attention: Boolean(parsed.requires_moderator_attention),
    possible_spam: Boolean(parsed.possible_spam),
    assistance_needed: Array.isArray(parsed.assistance_needed)
      ? parsed.assistance_needed.filter((tag) => typeof tag === 'string').slice(0, 6)
      : [],
  };
};

module.exports = {
  classify,
  isConfigured,
};
