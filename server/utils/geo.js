const { AppError } = require('./appError');

const EARTH_RADIUS_METERS = 6371000;

const toRadians = (degrees) => (degrees * Math.PI) / 180;

const normalizeNumber = (value, label) => {
  const normalizedValue = Number(value);

  if (!Number.isFinite(normalizedValue)) {
    throw new AppError(`${label} must be a valid number.`, 400, 'invalid_coordinate');
  }

  return normalizedValue;
};

const normalizeLatitude = (value) => {
  const latitude = normalizeNumber(value, 'Latitude');

  if (latitude < -90 || latitude > 90) {
    throw new AppError('Latitude must be between -90 and 90.', 400, 'invalid_coordinate');
  }

  return latitude;
};

const normalizeLongitude = (value) => {
  const longitude = normalizeNumber(value, 'Longitude');

  if (longitude < -180 || longitude > 180) {
    throw new AppError('Longitude must be between -180 and 180.', 400, 'invalid_coordinate');
  }

  return longitude;
};

const normalizeCoordinates = ({ latitude, longitude }) => ({
  latitude: normalizeLatitude(latitude),
  longitude: normalizeLongitude(longitude),
});

const distanceInMeters = (origin, destination) => {
  const normalizedOrigin = normalizeCoordinates(origin);
  const normalizedDestination = normalizeCoordinates(destination);

  const latitudeDelta = toRadians(
    normalizedDestination.latitude - normalizedOrigin.latitude
  );
  const longitudeDelta = toRadians(
    normalizedDestination.longitude - normalizedOrigin.longitude
  );
  const originLatitude = toRadians(normalizedOrigin.latitude);
  const destinationLatitude = toRadians(normalizedDestination.latitude);

  const haversineComponent =
    Math.sin(latitudeDelta / 2) ** 2 +
    Math.cos(originLatitude) *
      Math.cos(destinationLatitude) *
      Math.sin(longitudeDelta / 2) ** 2;

  const angularDistance =
    2 * Math.atan2(Math.sqrt(haversineComponent), Math.sqrt(1 - haversineComponent));

  return EARTH_RADIUS_METERS * angularDistance;
};

const buildBoundingBox = ({ latitude, longitude, radiusMeters }) => {
  const center = normalizeCoordinates({ latitude, longitude });
  const radius = normalizeNumber(radiusMeters, 'Radius');

  if (radius <= 0) {
    throw new AppError('Radius must be greater than zero.', 400, 'invalid_radius');
  }

  const latitudeDelta = radius / 111320;
  const longitudeCosine = Math.max(Math.cos(toRadians(center.latitude)), 0.01);
  const longitudeDelta = radius / (111320 * longitudeCosine);

  return {
    minLatitude: center.latitude - latitudeDelta,
    maxLatitude: center.latitude + latitudeDelta,
    minLongitude: center.longitude - longitudeDelta,
    maxLongitude: center.longitude + longitudeDelta,
  };
};

const hasMovedBeyondThreshold = (
  origin,
  destination,
  thresholdMeters = 20
) => {
  const threshold = normalizeNumber(thresholdMeters, 'Movement threshold');

  if (threshold <= 0) {
    return true;
  }

  return distanceInMeters(origin, destination) >= threshold;
};

module.exports = {
  buildBoundingBox,
  distanceInMeters,
  hasMovedBeyondThreshold,
  normalizeCoordinates,
  normalizeLatitude,
  normalizeLongitude,
  toRadians,
};
