const { supabaseAdmin } = require('../config/supabaseClient');
const { wrapDatabaseError } = require('../utils/appError');
const proximityService = require('./proximityService');

const INCIDENT_LOGS_TABLE = 'incident_logs';
const NOTIFICATIONS_TABLE = 'notifications';

const normalizeEmergencyLabel = (emergencyType) =>
  String(emergencyType ?? 'Emergency')
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (character) => character.toUpperCase());

const isSchemaCacheMissingColumn = (error, relationName, columnName) => {
  const haystack = [error?.message, error?.details, error?.hint]
    .filter(Boolean)
    .join(' ');
  const match = haystack.match(
    /could not find the ['"]([^'"]+)['"] column of ['"]([^'"]+)['"] in the schema cache/i
  );

  if (!match) {
    return false;
  }

  const [, reportedColumnName, reportedRelationName] = match;

  return (
    reportedRelationName.toLowerCase() === String(relationName).toLowerCase() &&
    reportedColumnName.toLowerCase() === String(columnName).toLowerCase()
  );
};

const createIncidentLog = async ({
  alertId,
  action,
  performedBy,
  metadata = {},
}) => {
  let { data, error } = await supabaseAdmin
    .from(INCIDENT_LOGS_TABLE)
    .insert({
      alert_id: alertId,
      action,
      performed_by: performedBy,
      metadata,
      created_at: new Date().toISOString(),
    })
    .select()
    .single();

  if (error && isSchemaCacheMissingColumn(error, INCIDENT_LOGS_TABLE, 'created_at')) {
    ({ data, error } = await supabaseAdmin
      .from(INCIDENT_LOGS_TABLE)
      .insert({
        alert_id: alertId,
        action,
        performed_by: performedBy,
        metadata,
      })
      .select()
      .single());
  }

  if (error) {
    throw wrapDatabaseError(error, INCIDENT_LOGS_TABLE);
  }

  return data;
};

const notifyNearbyUsers = async ({
  alert,
  latestLocation,
  radiusMeters = proximityService.DEFAULT_RADIUS_METERS,
  excludeUserId,
}) => {
  const nearbyUsers = await proximityService.listNearbyUsers({
    latitude: latestLocation.latitude,
    longitude: latestLocation.longitude,
    radiusMeters,
    excludeUserId,
  });

  if (!nearbyUsers.length) {
    return [];
  }

  const emergencyLabel = normalizeEmergencyLabel(alert.emergency_type);
  const locationLabel =
    latestLocation.formatted_address ?? latestLocation.locality ?? 'your area';
  const notificationRows = nearbyUsers.map((user) => ({
    user_id: user.id,
    alert_id: alert.id,
    channel: 'in_app',
    title: `${emergencyLabel} SOS nearby`,
    message: `${emergencyLabel} alert reported near ${locationLabel}.`,
    delivery_status: 'queued',
    created_at: new Date().toISOString(),
  }));

  let { data, error } = await supabaseAdmin
    .from(NOTIFICATIONS_TABLE)
    .insert(notificationRows)
    .select();

  if (error && isSchemaCacheMissingColumn(error, NOTIFICATIONS_TABLE, 'created_at')) {
    const fallbackRows = notificationRows.map(({ created_at, ...row }) => row);

    ({ data, error } = await supabaseAdmin
      .from(NOTIFICATIONS_TABLE)
      .insert(fallbackRows)
      .select());
  }

  if (error) {
    throw wrapDatabaseError(error, NOTIFICATIONS_TABLE);
  }

  return data ?? [];
};

module.exports = {
  createIncidentLog,
  notifyNearbyUsers,
};
