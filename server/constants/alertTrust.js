const VERIFICATION_STATUS = Object.freeze({
  UNVERIFIED: 'unverified',
  COMMUNITY_CONFIRMED: 'community_confirmed',
  RESPONDER_CONFIRMED: 'responder_confirmed',
  OFFICIALLY_CONFIRMED: 'officially_confirmed',
  DISPUTED: 'disputed',
  FALSE_REPORT: 'false_report',
  RESOLVED: 'resolved',
});

const VERIFICATION_STATUS_VALUES = Object.freeze(Object.values(VERIFICATION_STATUS));

const VISIBILITY_LEVEL = Object.freeze({
  STANDARD: 'standard',
  SENSITIVE: 'sensitive',
  RESTRICTED: 'restricted',
});

const VISIBILITY_LEVEL_VALUES = Object.freeze(Object.values(VISIBILITY_LEVEL));

const MODERATION_STATUS = Object.freeze({
  PENDING_REVIEW: 'pending_review',
  REVIEWED: 'reviewed',
  FLAGGED: 'flagged',
  ACTIONED: 'actioned',
});

const MODERATION_STATUS_VALUES = Object.freeze(Object.values(MODERATION_STATUS));

const CONFIRMATION_TYPE = Object.freeze({
  COMMUNITY_CONFIRM: 'community_confirm',
  DISPUTE: 'dispute',
  FALSE_REPORT: 'false_report',
});

const CONFIRMATION_TYPE_VALUES = Object.freeze(Object.values(CONFIRMATION_TYPE));

// Approximate-location rounding applied for any viewer who is not the
// reporter, an authorised responder, or a moderator/administrator. ~110m at
// the equator -- enough to place a marker on the right street without
// exposing the exact doorway a victim is standing at.
const PUBLIC_COORDINATE_PRECISION = 3;

module.exports = {
  VERIFICATION_STATUS,
  VERIFICATION_STATUS_VALUES,
  VISIBILITY_LEVEL,
  VISIBILITY_LEVEL_VALUES,
  MODERATION_STATUS,
  MODERATION_STATUS_VALUES,
  CONFIRMATION_TYPE,
  CONFIRMATION_TYPE_VALUES,
  PUBLIC_COORDINATE_PRECISION,
};
