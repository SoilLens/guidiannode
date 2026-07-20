// Crisis-report taxonomy shared by the AI classification service, the
// rule-based fallback, and the free-text report review step. `emergency_type`
// on public.alerts keeps the legacy quick-SOS values (security|medical|fire|
// accident|general_distress); confirmed_category/suggested_category use this
// richer set instead of replacing the legacy column, so existing quick-SOS
// alerts keep working unchanged.

const INCIDENT_CATEGORY = Object.freeze({
  SECURITY_THREAT: 'security_threat',
  MEDICAL_EMERGENCY: 'medical_emergency',
  FIRE: 'fire',
  ROAD_ACCIDENT: 'road_accident',
  MISSING_PERSON: 'missing_person',
  GENDER_BASED_VIOLENCE: 'gender_based_violence',
  NATURAL_DISASTER: 'natural_disaster',
  FLOODING_LANDSLIDE: 'flooding_landslide',
  FOOD_WATER_REQUEST: 'food_water_request',
  SHELTER_REQUEST: 'shelter_request',
  INFRASTRUCTURE_HAZARD: 'infrastructure_hazard',
  PUBLIC_HEALTH_CONCERN: 'public_health_concern',
  OTHER: 'other',
});

const INCIDENT_CATEGORY_VALUES = Object.freeze(Object.values(INCIDENT_CATEGORY));

const URGENCY_LEVEL = Object.freeze({
  CRITICAL: 'critical',
  HIGH: 'high',
  MEDIUM: 'medium',
  LOW: 'low',
});

const URGENCY_LEVEL_VALUES = Object.freeze(Object.values(URGENCY_LEVEL));

const CLASSIFICATION_SOURCE = Object.freeze({
  AI: 'ai',
  RULES: 'rules',
  USER: 'user',
  MODERATOR: 'moderator',
});

const CLASSIFICATION_SOURCE_VALUES = Object.freeze(Object.values(CLASSIFICATION_SOURCE));

const DETECTED_LANGUAGE = Object.freeze({
  ENGLISH: 'en',
  FRENCH: 'fr',
  PIDGIN: 'pcm',
  UNKNOWN: 'unknown',
});

const DETECTED_LANGUAGE_VALUES = Object.freeze(Object.values(DETECTED_LANGUAGE));

// Categories that involve reporting a person's identity/safety in a way
// that should never be shown to the public with an exact pin or the
// reporter's identity attached, per the platform's privacy requirements.
const SENSITIVE_CATEGORIES = Object.freeze([
  INCIDENT_CATEGORY.GENDER_BASED_VIOLENCE,
  INCIDENT_CATEGORY.MISSING_PERSON,
]);

// Assistance types selectable on both the report form (what help is needed)
// and the responder capability profile (what a helper can offer).
const ASSISTANCE_TYPE = Object.freeze({
  MEDICAL: 'medical',
  SECURITY: 'security',
  FIRE_RESCUE: 'fire_rescue',
  TRANSPORT: 'transport',
  SHELTER: 'shelter',
  FOOD_WATER: 'food_water',
  SEARCH: 'search',
  COUNSELLING: 'counselling',
  TRANSLATION: 'translation',
  GENERAL: 'general',
});

const ASSISTANCE_TYPE_VALUES = Object.freeze(Object.values(ASSISTANCE_TYPE));

module.exports = {
  INCIDENT_CATEGORY,
  INCIDENT_CATEGORY_VALUES,
  URGENCY_LEVEL,
  URGENCY_LEVEL_VALUES,
  CLASSIFICATION_SOURCE,
  CLASSIFICATION_SOURCE_VALUES,
  DETECTED_LANGUAGE,
  DETECTED_LANGUAGE_VALUES,
  SENSITIVE_CATEGORIES,
  ASSISTANCE_TYPE,
  ASSISTANCE_TYPE_VALUES,
};
