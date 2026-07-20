const { sendError } = require('../utils/apiResponse');
const { AppError } = require('../utils/appError');
const {
  isModeratorOrAdmin,
  isAdministrator,
  canActAsResponder,
  hasApprovedSensitiveRole,
} = require('../constants/roles');

// Role checks always run after verifySession, so req.user is the full
// public.users row. Hiding a button client-side is not access control --
// every privileged write in this file is also enforced here.

const requireModerator = (req, res, next) => {
  if (!isModeratorOrAdmin(req.user)) {
    return sendError(
      res,
      new AppError('Moderator or administrator access is required.', 403, 'moderator_access_required'),
      { label: 'Role Check Error' }
    );
  }
  return next();
};

const requireAdministrator = (req, res, next) => {
  if (!isAdministrator(req.user)) {
    return sendError(
      res,
      new AppError('Administrator access is required.', 403, 'administrator_access_required'),
      { label: 'Role Check Error' }
    );
  }
  return next();
};

const requireModeratorOrApprovedResponder = (req, res, next) => {
  if (!isModeratorOrAdmin(req.user) && !hasApprovedSensitiveRole(req.user)) {
    return sendError(
      res,
      new AppError(
        'An approved responder role or moderator access is required for this action.',
        403,
        'responder_or_moderator_access_required'
      ),
      { label: 'Role Check Error' }
    );
  }
  return next();
};

const requireResponderCapability = (req, res, next) => {
  if (!canActAsResponder(req.user)) {
    return sendError(
      res,
      new AppError(
        'You need an approved community-helper or responder role to do this.',
        403,
        'responder_role_required'
      ),
      { label: 'Role Check Error' }
    );
  }
  return next();
};

module.exports = {
  requireModerator,
  requireAdministrator,
  requireModeratorOrApprovedResponder,
  requireResponderCapability,
};
