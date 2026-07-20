const {
  INCIDENT_CATEGORY,
  URGENCY_LEVEL,
  DETECTED_LANGUAGE,
  CLASSIFICATION_SOURCE,
  ASSISTANCE_TYPE,
} = require('../../constants/incidentTaxonomy');

// Lightweight, dependency-free keyword classifier for English, French, and
// Cameroon Pidgin. This is the mandatory fallback that keeps emergency
// reporting working when no AI provider is configured or the AI call times
// out -- it must never block submission and must always return a result.

const URGENCY_ORDER = [
  URGENCY_LEVEL.LOW,
  URGENCY_LEVEL.MEDIUM,
  URGENCY_LEVEL.HIGH,
  URGENCY_LEVEL.CRITICAL,
];

const escalate = (level, steps = 1) => {
  const index = URGENCY_ORDER.indexOf(level);
  const nextIndex = Math.min(URGENCY_ORDER.length - 1, index + steps);
  return URGENCY_ORDER[nextIndex];
};

const BASE_URGENCY = Object.freeze({
  [INCIDENT_CATEGORY.SECURITY_THREAT]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.MEDICAL_EMERGENCY]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.FIRE]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.ROAD_ACCIDENT]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.GENDER_BASED_VIOLENCE]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.MISSING_PERSON]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.NATURAL_DISASTER]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.FLOODING_LANDSLIDE]: URGENCY_LEVEL.HIGH,
  [INCIDENT_CATEGORY.PUBLIC_HEALTH_CONCERN]: URGENCY_LEVEL.MEDIUM,
  [INCIDENT_CATEGORY.INFRASTRUCTURE_HAZARD]: URGENCY_LEVEL.MEDIUM,
  [INCIDENT_CATEGORY.FOOD_WATER_REQUEST]: URGENCY_LEVEL.MEDIUM,
  [INCIDENT_CATEGORY.SHELTER_REQUEST]: URGENCY_LEVEL.MEDIUM,
  [INCIDENT_CATEGORY.OTHER]: URGENCY_LEVEL.LOW,
});

// Higher-priority categories win ties when a report matches keywords from
// more than one category (e.g. "flooding and families need shelter" should
// file as flooding_landslide, with shelter recorded under assistance_needed
// rather than becoming the primary category).
const CATEGORY_PRIORITY = [
  INCIDENT_CATEGORY.SECURITY_THREAT,
  INCIDENT_CATEGORY.MEDICAL_EMERGENCY,
  INCIDENT_CATEGORY.GENDER_BASED_VIOLENCE,
  INCIDENT_CATEGORY.FIRE,
  INCIDENT_CATEGORY.ROAD_ACCIDENT,
  INCIDENT_CATEGORY.NATURAL_DISASTER,
  INCIDENT_CATEGORY.FLOODING_LANDSLIDE,
  INCIDENT_CATEGORY.MISSING_PERSON,
  INCIDENT_CATEGORY.INFRASTRUCTURE_HAZARD,
  INCIDENT_CATEGORY.PUBLIC_HEALTH_CONCERN,
  INCIDENT_CATEGORY.SHELTER_REQUEST,
  INCIDENT_CATEGORY.FOOD_WATER_REQUEST,
  INCIDENT_CATEGORY.OTHER,
];

const CATEGORY_KEYWORDS = Object.freeze({
  [INCIDENT_CATEGORY.SECURITY_THREAT]: [
    'gunshot', 'gunshots', 'gun shot', 'shooting', 'gun ', 'armed robbery', 'robbery', 'robber',
    'thief', 'thieves', 'attacked', 'attack', 'kidnap', 'kidnapping', 'weapon', 'machete',
    'bandit', 'hold-up', 'holdup', 'gang', 'break-in', 'break in', 'burglar', 'intruder',
    'coup de feu', 'vol a main armee', 'voleur', 'agression', 'arme', 'braquage', 'bandits',
    'arm robbery', 'bad boys', 'thief man', 'wahala man',
  ],
  [INCIDENT_CATEGORY.MEDICAL_EMERGENCY]: [
    // 'injured'/'injury' are deliberately excluded: they are generic enough
    // to appear in accident, violence, and disaster reports too, which was
    // causing ties with more specific categories like road_accident.
    'wound', 'wounded', 'bleeding', 'blood', 'unconscious', 'collapsed',
    'heart attack', 'seizure', 'convulsion', 'labour', 'labor', 'pregnant', 'pregnancy',
    'ambulance', 'dying', 'poison', 'poisoned', 'snake bite', 'choking', 'not breathing',
    'blesse', 'blessure', 'sang', 'malade', 'accouchement', 'inconscient', 'crise cardiaque',
    'don wound', 'e don faint', 'belle woman', 'sick pass', 'e no fine', 'body no fine',
  ],
  [INCIDENT_CATEGORY.FIRE]: [
    'fire', 'burning', 'flames', 'smoke', 'gas leak', 'explosion',
    'feu', 'incendie', 'brule', 'fumee',
    'fire dey burn', 'house dey burn', 'e dey burn',
  ],
  [INCIDENT_CATEGORY.ROAD_ACCIDENT]: [
    'accident', 'crash', 'collision', 'car accident', 'motor accident', 'bike accident',
    'hit and run', 'overturned', 'okada accident',
    'accident de route', 'accident de la route', 'renverse',
    'moto accident', 'njangi bus', 'accident happen',
  ],
  [INCIDENT_CATEGORY.MISSING_PERSON]: [
    'missing', 'disappeared', 'went missing', 'lost child', "can't find", 'cannot find',
    'kidnapped child',
    'disparu', 'disparition', 'enfant perdu',
    'pikin don lost', 'e don miss road', 'we no see am',
  ],
  [INCIDENT_CATEGORY.GENDER_BASED_VIOLENCE]: [
    'rape', 'raped', 'sexual assault', 'domestic violence', 'abused', 'beaten by her husband',
    'forced her', 'harassment', 'sexually assaulted',
    'viol', 'violence conjugale', 'agression sexuelle',
    'dem rape am', 'man dey beat im wife', 'husband dey beat am',
  ],
  [INCIDENT_CATEGORY.NATURAL_DISASTER]: [
    'earthquake', 'storm', 'hurricane', 'tornado', 'drought', 'wildfire',
    'tremblement de terre', 'tempete', 'secheresse',
    'ground dey shake',
  ],
  [INCIDENT_CATEGORY.FLOODING_LANDSLIDE]: [
    'flood', 'flooding', 'landslide', 'mudslide', 'water rising', 'water is rising',
    'inondation', 'glissement de terrain', 'crue',
    'water don enter house', 'flood dey',
  ],
  [INCIDENT_CATEGORY.FOOD_WATER_REQUEST]: [
    'food', 'hunger', 'hungry', 'starving', 'drinking water', 'no water', 'water shortage',
    'nourriture', 'faim', 'eau potable', "manque d'eau",
    'hungry di kill us', 'we need chop', 'water no dey',
  ],
  [INCIDENT_CATEGORY.SHELTER_REQUEST]: [
    'shelter', 'homeless', 'displaced', 'refugee', 'need housing', 'roof over', 'tent',
    'abri', 'sans-abri', 'deplaces', 'hebergement',
    'we no get house', 'need place for sleep',
  ],
  [INCIDENT_CATEGORY.INFRASTRUCTURE_HAZARD]: [
    'bridge collapse', 'power line', 'electrical hazard', 'building collapse', 'downed pole',
    'live wire', 'road damage', 'collapsed wall',
    'pont effondre', 'fil electrique', 'effondrement',
    'bridge don break', 'wire dey fall',
  ],
  [INCIDENT_CATEGORY.PUBLIC_HEALTH_CONCERN]: [
    'outbreak', 'epidemic', 'cholera', 'disease spreading', 'contaminated water',
    'epidemie', 'cholera', 'maladie qui se propage',
    'sickness dey waka', 'cholera dey',
  ],
});

const ESCALATE_CRITICAL_KEYWORDS = [
  'gunshot', 'gunshots', 'gun shot', 'shooting', 'weapon', 'machete attack',
  'unconscious', 'not breathing', 'cardiac arrest', 'heart attack', 'severe bleeding',
  'bleeding heavily', 'bleeding badly', 'trapped', 'drowning', 'explosion',
  'collapsed building', 'building collapse', 'life threatening', 'dying', 'about to die',
  'kidnapped', 'rape', 'raped', 'sexual assault', 'inconscient', 'ne respire pas',
  'e no dey breathe', 'body don cold',
];

const POPULATED_PLACE_KEYWORDS = [
  'market', 'school', 'church', 'mosque', 'hospital', 'stadium', 'motor park',
  'marche', 'ecole', 'eglise', 'hopital',
];

const ASSISTANCE_KEYWORDS = Object.freeze({
  [ASSISTANCE_TYPE.MEDICAL]: ['ambulance', 'wound', 'injured', 'bleeding', 'blesse', 'sick', 'malade'],
  [ASSISTANCE_TYPE.SECURITY]: ['gunshot', 'armed', 'robbery', 'attack', 'security', 'police'],
  [ASSISTANCE_TYPE.FIRE_RESCUE]: ['fire', 'burning', 'incendie', 'smoke'],
  [ASSISTANCE_TYPE.TRANSPORT]: ['accident', 'crash', 'evacuate', 'evacuation'],
  [ASSISTANCE_TYPE.SHELTER]: ['shelter', 'homeless', 'displaced', 'abri', 'roof'],
  [ASSISTANCE_TYPE.FOOD_WATER]: ['food', 'hungry', 'water', 'nourriture', 'eau'],
  [ASSISTANCE_TYPE.SEARCH]: ['missing', 'disappeared', 'lost child', 'disparu'],
  [ASSISTANCE_TYPE.COUNSELLING]: ['rape', 'abused', 'trauma', 'violence conjugale'],
});

const PIDGIN_MARKERS = [
  ' di ', ' dey ', ' don ', ' na ', 'wetin', 'abeg', 'pikin', 'sabi', ' wan ', ' dem ',
  'waka', 'chop', 'wahala', ' oga ', 'e go ', 'no dey', ' sef', ' for mile', ' for ',
];

const FRENCH_MARKERS = [
  'le ', 'la ', 'les ', 'des ', 'une ', ' un ', ' et ', 'avec', ' de ', 'dans ',
  'il y a', 'besoin', 'accident de', 'incendie', 'blesse', 'secours', "s'il vous plait",
  'nous avons', 'nous sommes',
];

const SPAM_MARKERS = ['http://', 'https://', 'www.', 'click here', 'you won', 'congratulations you'];

const normalizeText = (text) => ` ${String(text ?? '').toLowerCase().trim()} `;

const countMatches = (haystack, keywords) =>
  keywords.reduce((count, keyword) => (haystack.includes(keyword) ? count + 1 : count), 0);

const detectLanguage = (haystack) => {
  const pidginScore = countMatches(haystack, PIDGIN_MARKERS);
  const frenchScore = countMatches(haystack, FRENCH_MARKERS);
  const hasAccentedCharacters = /[àâçéèêëîïôûù]/.test(haystack);
  const frenchTotal = frenchScore + (hasAccentedCharacters ? 1 : 0);

  if (pidginScore === 0 && frenchTotal === 0) {
    return DETECTED_LANGUAGE.ENGLISH;
  }

  if (pidginScore >= frenchTotal) {
    return DETECTED_LANGUAGE.PIDGIN;
  }

  return DETECTED_LANGUAGE.FRENCH;
};

const pickCategory = (haystack) => {
  const scores = new Map();

  Object.entries(CATEGORY_KEYWORDS).forEach(([category, keywords]) => {
    const score = countMatches(haystack, keywords);
    if (score > 0) {
      scores.set(category, score);
    }
  });

  if (scores.size === 0) {
    return { category: INCIDENT_CATEGORY.OTHER, score: 0 };
  }

  const topScore = Math.max(...scores.values());
  const topCategories = CATEGORY_PRIORITY.filter(
    (category) => scores.get(category) === topScore
  );

  return { category: topCategories[0] ?? INCIDENT_CATEGORY.OTHER, score: topScore };
};

const buildAssistanceNeeded = (haystack) =>
  Object.entries(ASSISTANCE_KEYWORDS)
    .filter(([, keywords]) => countMatches(haystack, keywords) > 0)
    .map(([assistanceType]) => assistanceType);

const buildExplanation = (category, urgency, matchCount) => {
  if (matchCount === 0) {
    return 'No strong keyword match was found, so this report needs a human to pick the right category.';
  }

  return `Matched ${matchCount} keyword(s) associated with "${category.replace(/_/g, ' ')}"; urgency set to "${urgency}" using rule-based triage.`;
};

const buildRecommendedAction = (category, urgency) => {
  if (urgency === URGENCY_LEVEL.CRITICAL) {
    return 'Treat as life-threatening: alert nearby responders immediately and advise the reporter to contact official emergency services if possible.';
  }

  if (category === INCIDENT_CATEGORY.OTHER) {
    return 'Route to a moderator for manual categorisation before wider distribution.';
  }

  return 'Share with nearby verified helpers and monitor for community or responder confirmation.';
};

const isLikelySpam = (haystack, wordCount, matchScore) => {
  if (SPAM_MARKERS.some((marker) => haystack.includes(marker))) {
    return true;
  }

  return wordCount <= 2 && matchScore === 0;
};

const classify = (description) => {
  const haystack = normalizeText(description);
  const wordCount = haystack.trim().split(/\s+/).filter(Boolean).length;
  const { category, score } = pickCategory(haystack);
  const populatedPlaceMentioned = countMatches(haystack, POPULATED_PLACE_KEYWORDS) > 0;
  const criticalKeywordMatched = countMatches(haystack, ESCALATE_CRITICAL_KEYWORDS) > 0;

  let urgency = BASE_URGENCY[category] ?? URGENCY_LEVEL.MEDIUM;

  if (criticalKeywordMatched) {
    urgency = URGENCY_LEVEL.CRITICAL;
  } else if (populatedPlaceMentioned && category !== INCIDENT_CATEGORY.OTHER) {
    urgency = escalate(urgency, 1);
  }

  const detectedLanguage = detectLanguage(haystack);
  const assistanceNeeded = buildAssistanceNeeded(haystack);
  const confidence = score === 0 ? 0.2 : Math.min(0.9, 0.5 + score * 0.1);
  const possibleSpam = isLikelySpam(haystack, wordCount, score);
  const requiresModeratorAttention =
    possibleSpam || category === INCIDENT_CATEGORY.OTHER || urgency === URGENCY_LEVEL.CRITICAL;

  return {
    category,
    urgency,
    detected_language: detectedLanguage,
    explanation: buildExplanation(category, urgency, score),
    confidence,
    recommended_action: buildRecommendedAction(category, urgency),
    requires_moderator_attention: requiresModeratorAttention,
    possible_spam: possibleSpam,
    assistance_needed: assistanceNeeded,
    classification_source: CLASSIFICATION_SOURCE.RULES,
  };
};

module.exports = {
  classify,
  detectLanguage,
};
