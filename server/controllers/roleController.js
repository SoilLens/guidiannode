const roleService = require('../services/roleService');
const { sendError, sendSuccess } = require('../utils/apiResponse');

const requestRoleHandler = async (req, res) => {
  try {
    const payload = req.validated?.body ?? req.body;
    const profile = await roleService.requestRole({
      userId: req.user.id,
      requestedRole: payload.requested_role,
      assistanceCapabilities: payload.assistance_capabilities,
      serviceRadiusMeters: payload.service_radius_meters,
      organisation: payload.organisation,
      verificationNotes: payload.verification_notes,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Role request submitted successfully.',
      data: { profile },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Request Role Error' });
  }
};

const listPendingRoleRequestsHandler = async (req, res) => {
  try {
    const requests = await roleService.listPendingRoleRequests();

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Pending role requests fetched successfully.',
      data: { requests },
    });
  } catch (error) {
    return sendError(res, error, { label: 'List Pending Role Requests Error' });
  }
};

const decideRoleRequestHandler = async (req, res) => {
  try {
    const params = req.validated?.params ?? req.params;
    const payload = req.validated?.body ?? req.body;
    const profile = await roleService.decideRoleRequest({
      targetUserId: params.userId,
      decision: payload.decision,
      performedBy: req.user.id,
      notes: payload.notes,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: `Role request ${payload.decision} successfully.`,
      data: { profile },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Decide Role Request Error' });
  }
};

const assignRoleDirectlyHandler = async (req, res) => {
  try {
    const params = req.validated?.params ?? req.params;
    const payload = req.validated?.body ?? req.body;
    const profile = await roleService.assignRoleDirectly({
      targetUserId: params.userId,
      role: payload.role,
      performedBy: req.user.id,
      notes: payload.notes,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Role assigned successfully.',
      data: { profile },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Assign Role Directly Error' });
  }
};

const updateAvailabilityHandler = async (req, res) => {
  try {
    const payload = req.validated?.body ?? req.body;
    const profile = await roleService.updateAvailability({
      userId: req.user.id,
      availabilityStatus: payload.availability_status,
    });

    return sendSuccess(res, {
      statusCode: 200,
      message: 'Availability updated successfully.',
      data: { profile },
    });
  } catch (error) {
    return sendError(res, error, { label: 'Update Availability Error' });
  }
};

module.exports = {
  requestRoleHandler,
  listPendingRoleRequestsHandler,
  decideRoleRequestHandler,
  assignRoleDirectlyHandler,
  updateAvailabilityHandler,
};
