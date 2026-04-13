const { supabaseAdmin } = require('../config/supabaseClient');
const { wrapDatabaseError } = require('../utils/appError');
const { buildBoundingBox, distanceInMeters, normalizeCoordinates } = require('../utils/geo');

const USERS_TABLE = 'users';
const ALERTS_TABLE = 'alerts';
const LIVE_LOCATIONS_TABLE = 'live_locations';
const DEFAULT_RADIUS_METERS = 3000;

const mapUsersById = (users) =>
  new Map((users ?? []).map((user) => [user.id, user]));

const mapLiveLocationsByAlertId = (liveLocations) =>
  new Map((liveLocations ?? []).map((location) => [location.alert_id, location]));

const listNearbyUsers = async ({
  latitude,
  longitude,
  radiusMeters = DEFAULT_RADIUS_METERS,
  excludeUserId,
}) => {
  const center = normalizeCoordinates({ latitude, longitude });
  const bounds = buildBoundingBox({
    latitude: center.latitude,
    longitude: center.longitude,
    radiusMeters,
  });

  let query = supabaseAdmin
    .from(USERS_TABLE)
    .select(
      'id, full_name, phone_number, quarter, location_permission, latitude, longitude, updated_at'
    )
    .eq('location_permission', true)
    .not('latitude', 'is', null)
    .not('longitude', 'is', null)
    .gte('latitude', bounds.minLatitude)
    .lte('latitude', bounds.maxLatitude)
    .gte('longitude', bounds.minLongitude)
    .lte('longitude', bounds.maxLongitude);

  if (excludeUserId) {
    query = query.neq('id', excludeUserId);
  }

  const { data, error } = await query;

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return (data ?? [])
    .map((user) => ({
      ...user,
      distance_meters: distanceInMeters(center, {
        latitude: user.latitude,
        longitude: user.longitude,
      }),
    }))
    .filter((user) => user.distance_meters <= radiusMeters)
    .sort((left, right) => left.distance_meters - right.distance_meters);
};

const listNearbyAlerts = async ({
  latitude,
  longitude,
  radiusMeters = DEFAULT_RADIUS_METERS,
  excludeUserId,
}) => {
  const center = normalizeCoordinates({ latitude, longitude });
  const bounds = buildBoundingBox({
    latitude: center.latitude,
    longitude: center.longitude,
    radiusMeters,
  });

  const { data: alerts, error: alertsError } = await supabaseAdmin
    .from(ALERTS_TABLE)
    .select('*')
    .eq('status', 'active')
    .gte('latitude', bounds.minLatitude)
    .lte('latitude', bounds.maxLatitude)
    .gte('longitude', bounds.minLongitude)
    .lte('longitude', bounds.maxLongitude);

  if (alertsError) {
    throw wrapDatabaseError(alertsError, ALERTS_TABLE);
  }

  const filteredAlerts = (alerts ?? []).filter((alert) =>
    excludeUserId ? alert.user_id !== excludeUserId : true
  );

  if (!filteredAlerts.length) {
    return [];
  }

  const alertIds = filteredAlerts.map((alert) => alert.id);
  const userIds = [...new Set(filteredAlerts.map((alert) => alert.user_id))];

  const [{ data: liveLocations, error: liveLocationsError }, { data: users, error: usersError }] =
    await Promise.all([
      supabaseAdmin
        .from(LIVE_LOCATIONS_TABLE)
        .select('*')
        .in('alert_id', alertIds),
      supabaseAdmin
        .from(USERS_TABLE)
        .select('id, full_name, phone_number, quarter')
        .in('id', userIds),
    ]);

  if (liveLocationsError) {
    throw wrapDatabaseError(liveLocationsError, LIVE_LOCATIONS_TABLE);
  }

  if (usersError) {
    throw wrapDatabaseError(usersError, USERS_TABLE);
  }

  const liveLocationsByAlertId = mapLiveLocationsByAlertId(liveLocations);
  const usersById = mapUsersById(users);

  return filteredAlerts
    .map((alert) => {
      const liveLocation = liveLocationsByAlertId.get(alert.id);
      const effectiveLatitude = liveLocation?.latitude ?? alert.latitude;
      const effectiveLongitude = liveLocation?.longitude ?? alert.longitude;
      const distanceMeters = distanceInMeters(center, {
        latitude: effectiveLatitude,
        longitude: effectiveLongitude,
      });

      return {
        ...alert,
        latitude: effectiveLatitude,
        longitude: effectiveLongitude,
        readable_address: liveLocation?.formatted_address ?? null,
        locality: liveLocation?.locality ?? null,
        live_location_updated_at: liveLocation?.updated_at ?? null,
        distance_meters: distanceMeters,
        victim: usersById.get(alert.user_id) ?? null,
      };
    })
    .filter((alert) => alert.distance_meters <= radiusMeters)
    .sort((left, right) => left.distance_meters - right.distance_meters);
};

module.exports = {
  DEFAULT_RADIUS_METERS,
  listNearbyAlerts,
  listNearbyUsers,
};
