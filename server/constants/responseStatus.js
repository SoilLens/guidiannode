// Full community-helper response state machine. 'on_the_way' and 'stopped'
// are the legacy values the live app already sends from
// ResponderFollowScreen; they stay valid alongside the richer new states so
// no existing client build breaks.

const RESPONSE_STATUS = Object.freeze({
  OFFERED: 'offered',
  ACCEPTED: 'accepted',
  ON_THE_WAY: 'on_the_way',
  EN_ROUTE: 'en_route',
  ARRIVED: 'arrived',
  ASSISTANCE_IN_PROGRESS: 'assistance_in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
  UNABLE_TO_ASSIST: 'unable_to_assist',
  STOPPED: 'stopped',
});

const RESPONSE_STATUS_VALUES = Object.freeze(Object.values(RESPONSE_STATUS));

const TERMINAL_RESPONSE_STATUSES = Object.freeze([
  RESPONSE_STATUS.COMPLETED,
  RESPONSE_STATUS.CANCELLED,
  RESPONSE_STATUS.UNABLE_TO_ASSIST,
  RESPONSE_STATUS.STOPPED,
]);

const isTerminalResponseStatus = (status) => TERMINAL_RESPONSE_STATUSES.includes(status);

module.exports = {
  RESPONSE_STATUS,
  RESPONSE_STATUS_VALUES,
  TERMINAL_RESPONSE_STATUSES,
  isTerminalResponseStatus,
};
