const aiClassifier = require('./classification/aiClassifier');
const ruleBasedClassifier = require('./classification/ruleBasedClassifier');
const {
  INCIDENT_CATEGORY,
  INCIDENT_CATEGORY_VALUES,
  URGENCY_LEVEL,
  URGENCY_LEVEL_VALUES,
  CLASSIFICATION_SOURCE,
  DETECTED_LANGUAGE,
} = require('../constants/incidentTaxonomy');

// Advisory-only triage: this service never confirms an emergency is real and
// never blocks alert submission. It always resolves, even if the AI
// provider is unavailable, misconfigured, or times out -- callers should
// treat classification_source === 'rules' as a signal that a human should
// double check the suggestion.

const buildEmptyResult = () => ({
  category: INCIDENT_CATEGORY.OTHER,
  urgency: URGENCY_LEVEL.MEDIUM,
  detected_language: DETECTED_LANGUAGE.UNKNOWN,
  explanation: 'No description was provided, so no category could be suggested.',
  confidence: 0,
  recommended_action: 'Ask the reporter for more detail before distributing this report.',
  requires_moderator_attention: true,
  possible_spam: false,
  assistance_needed: [],
  classification_source: CLASSIFICATION_SOURCE.RULES,
});

const clampConfidence = (value) => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? Math.min(1, Math.max(0, numeric)) : 0.5;
};

const normalizeResult = (result, source) => ({
  category: INCIDENT_CATEGORY_VALUES.includes(result.category) ? result.category : INCIDENT_CATEGORY.OTHER,
  urgency: URGENCY_LEVEL_VALUES.includes(result.urgency) ? result.urgency : URGENCY_LEVEL.MEDIUM,
  detected_language: result.detected_language ?? DETECTED_LANGUAGE.UNKNOWN,
  explanation: result.explanation ?? '',
  confidence: clampConfidence(result.confidence),
  recommended_action: result.recommended_action ?? '',
  requires_moderator_attention: Boolean(result.requires_moderator_attention),
  possible_spam: Boolean(result.possible_spam),
  assistance_needed: Array.isArray(result.assistance_needed) ? result.assistance_needed : [],
  classification_source: source,
});

const isAiConfigured = () => aiClassifier.isConfigured();

const classifyIncidentReport = async ({ description }) => {
  const trimmedDescription = String(description ?? '').trim();

  if (!trimmedDescription) {
    return buildEmptyResult();
  }

  if (isAiConfigured()) {
    try {
      const aiResult = await aiClassifier.classify(trimmedDescription);
      return normalizeResult(aiResult, CLASSIFICATION_SOURCE.AI);
    } catch (error) {
      console.warn(
        `[classification] AI classification unavailable (${error.code ?? error.message}); using rule-based fallback.`
      );
    }
  }

  const rulesResult = ruleBasedClassifier.classify(trimmedDescription);
  return normalizeResult(rulesResult, CLASSIFICATION_SOURCE.RULES);
};

module.exports = {
  classifyIncidentReport,
  isAiConfigured,
};
