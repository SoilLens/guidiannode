const { supabaseAdmin } = require('../config/supabaseClient');
const { AppError, wrapDatabaseError } = require('../utils/appError');
const { normalizeCoordinates } = require('../utils/geo');

const USERS_TABLE = 'users';

const getUserLocationProfile = async (userId) => {
  const { data, error } = await supabaseAdmin
    .from(USERS_TABLE)
    .select('*')
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return data;
};

const updateUserLocation = async ({
  userId,
  locationPermission,
  latitude,
  longitude,
}) => {
  const existingUser = await getUserLocationProfile(userId);

  if (!existingUser) {
    throw new AppError('User profile could not be found.', 404, 'user_not_found');
  }

  const shouldPersistLocation = Boolean(locationPermission);
  const normalizedCoordinates = shouldPersistLocation
    ? normalizeCoordinates({ latitude, longitude })
    : { latitude: null, longitude: null };

  const payload = {
    location_permission: shouldPersistLocation,
    latitude: normalizedCoordinates.latitude,
    longitude: normalizedCoordinates.longitude,
    updated_at: new Date().toISOString(),
  };

  const { data, error } = await supabaseAdmin
    .from(USERS_TABLE)
    .update(payload)
    .eq('id', userId)
    .select('*')
    .single();

  if (error) {
    throw wrapDatabaseError(error, USERS_TABLE);
  }

  return data;
};

module.exports = {
  getUserLocationProfile,
  updateUserLocation,
};
