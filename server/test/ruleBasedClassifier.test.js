const assert = require('node:assert/strict');
const test = require('node:test');

const ruleBasedClassifier = require('../services/classification/ruleBasedClassifier');
const classificationService = require('../services/classificationService');
const { INCIDENT_CATEGORY, URGENCY_LEVEL, DETECTED_LANGUAGE } = require('../constants/incidentTaxonomy');

test('classifies a Pidgin gunshot report as a critical security threat', () => {
  const result = ruleBasedClassifier.classify('Gunshots di happen for Mile 3.');

  assert.equal(result.category, INCIDENT_CATEGORY.SECURITY_THREAT);
  assert.equal(result.urgency, URGENCY_LEVEL.CRITICAL);
  assert.equal(result.detected_language, DETECTED_LANGUAGE.PIDGIN);
  assert.equal(result.classification_source, 'rules');
});

test('classifies a Pidgin medical report needing an ambulance', () => {
  const result = ruleBasedClassifier.classify('Person don wound and we need ambulance.');

  assert.equal(result.category, INCIDENT_CATEGORY.MEDICAL_EMERGENCY);
  assert.ok([URGENCY_LEVEL.HIGH, URGENCY_LEVEL.CRITICAL].includes(result.urgency));
  assert.equal(result.detected_language, DETECTED_LANGUAGE.PIDGIN);
});

test('classifies a fire report and escalates urgency near a populated place', () => {
  const result = ruleBasedClassifier.classify('Fire is burning near the market.');

  assert.equal(result.category, INCIDENT_CATEGORY.FIRE);
  assert.equal(result.urgency, URGENCY_LEVEL.CRITICAL);
  assert.equal(result.detected_language, DETECTED_LANGUAGE.ENGLISH);
});

test('classifies a missing child report as high urgency', () => {
  const result = ruleBasedClassifier.classify('A child is missing.');

  assert.equal(result.category, INCIDENT_CATEGORY.MISSING_PERSON);
  assert.equal(result.urgency, URGENCY_LEVEL.HIGH);
});

test('flooding with a shelter request stays categorised as flooding, with shelter recorded as assistance needed', () => {
  const result = ruleBasedClassifier.classify('There is flooding and families need shelter.');

  assert.equal(result.category, INCIDENT_CATEGORY.FLOODING_LANDSLIDE);
  assert.ok(result.assistance_needed.includes('shelter'));
});

test('classifies a road accident report', () => {
  const result = ruleBasedClassifier.classify('Road accident with injured passengers.');

  assert.equal(result.category, INCIDENT_CATEGORY.ROAD_ACCIDENT);
  assert.equal(result.urgency, URGENCY_LEVEL.HIGH);
});

test('classifies a food and water request as medium urgency', () => {
  const result = ruleBasedClassifier.classify('We need food and drinking water.');

  assert.equal(result.category, INCIDENT_CATEGORY.FOOD_WATER_REQUEST);
  assert.equal(result.urgency, URGENCY_LEVEL.MEDIUM);
  assert.ok(result.assistance_needed.includes('food_water'));
});

test('detects French free-text reports', () => {
  const result = ruleBasedClassifier.classify('Il y a un accident de la route avec des blesses graves.');

  assert.equal(result.category, INCIDENT_CATEGORY.ROAD_ACCIDENT);
  assert.equal(result.detected_language, DETECTED_LANGUAGE.FRENCH);
});

test('vague or unmatched text routes to "other" and flags for moderator review', () => {
  const result = ruleBasedClassifier.classify('something is happening');

  assert.equal(result.category, INCIDENT_CATEGORY.OTHER);
  assert.equal(result.requires_moderator_attention, true);
});

test('very short low-signal text is flagged as possible spam', () => {
  const result = ruleBasedClassifier.classify('ok');

  assert.equal(result.possible_spam, true);
});

test('classificationService falls back to rules when no AI provider is configured', async () => {
  delete process.env.ANTHROPIC_API_KEY;

  const result = await classificationService.classifyIncidentReport({
    description: 'Fire is burning near the market.',
  });

  assert.equal(result.classification_source, 'rules');
  assert.equal(result.category, INCIDENT_CATEGORY.FIRE);
  assert.equal(classificationService.isAiConfigured(), false);
});

test('classificationService returns an advisory empty result for a blank description', async () => {
  const result = await classificationService.classifyIncidentReport({ description: '   ' });

  assert.equal(result.category, INCIDENT_CATEGORY.OTHER);
  assert.equal(result.requires_moderator_attention, true);
});
