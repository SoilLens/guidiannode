const { AppError } = require('../utils/appError');
const { normalizeCoordinates } = require('../utils/geo');

const GEOCODING_API_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
const ROUTES_API_URL = 'https://routes.googleapis.com/directions/v2:computeRoutes';

const requireMapsServerKey = () => {
  const mapsKey = process.env.GOOGLE_MAPS_SERVER_API_KEY;

  if (!mapsKey) {
    throw new AppError(
      'GOOGLE_MAPS_SERVER_API_KEY is required for geocoding and route generation.',
      500,
      'maps_api_key_missing'
    );
  }

  return mapsKey;
};

const parseDurationSeconds = (durationValue) => {
  const normalizedDuration = String(durationValue ?? '').trim();

  if (!normalizedDuration.endsWith('s')) {
    return 0;
  }

  return Math.max(0, Math.round(Number(normalizedDuration.slice(0, -1)) || 0));
};

const formatDistance = (distanceMeters) => {
  const normalizedDistance = Math.max(0, Number(distanceMeters) || 0);

  if (normalizedDistance < 1000) {
    return `${normalizedDistance.toFixed(0)} m`;
  }

  return `${(normalizedDistance / 1000).toFixed(1)} km`;
};

const formatDuration = (durationSeconds) => {
  const normalizedDuration = Math.max(0, Number(durationSeconds) || 0);

  if (normalizedDuration < 60) {
    return `${normalizedDuration.toFixed(0)} sec`;
  }

  if (normalizedDuration < 3600) {
    return `${(normalizedDuration / 60).toFixed(0)} min`;
  }

  const hours = Math.floor(normalizedDuration / 3600);
  const minutes = Math.round((normalizedDuration % 3600) / 60);
  return `${hours}h ${minutes}m`;
};

const findAddressComponent = (addressComponents, acceptedTypes) => {
  const component = addressComponents.find((candidate) =>
    acceptedTypes.some((type) => candidate.types?.includes(type))
  );

  return component?.long_name ?? null;
};

const reverseGeocode = async (latitude, longitude) => {
  const mapsKey = requireMapsServerKey();
  const coordinates = normalizeCoordinates({ latitude, longitude });
  const geocodeUrl = new URL(GEOCODING_API_URL);

  geocodeUrl.searchParams.set(
    'latlng',
    `${coordinates.latitude},${coordinates.longitude}`
  );
  geocodeUrl.searchParams.set('language', 'en');
  geocodeUrl.searchParams.set('key', mapsKey);

  const response = await fetch(geocodeUrl);

  if (!response.ok) {
    throw new AppError(
      'Google Geocoding API request failed.',
      503,
      'reverse_geocode_failed'
    );
  }

  const payload = await response.json();

  if (payload.status === 'ZERO_RESULTS') {
    return null;
  }

  if (payload.status !== 'OK' || !Array.isArray(payload.results) || !payload.results.length) {
    throw new AppError(
      'Google Geocoding API did not return a valid address.',
      503,
      'reverse_geocode_failed',
      payload
    );
  }

  const result = payload.results[0];
  const addressComponents = Array.isArray(result.address_components)
    ? result.address_components
    : [];

  const locality =
    findAddressComponent(addressComponents, [
      'locality',
      'administrative_area_level_2',
      'sublocality',
      'sublocality_level_1',
    ]) ??
    findAddressComponent(addressComponents, ['administrative_area_level_1']);
  const neighborhood = findAddressComponent(addressComponents, [
    'neighborhood',
    'sublocality',
    'sublocality_level_1',
  ]);

  return {
    formatted_address: result.formatted_address ?? null,
    locality,
    neighborhood,
    place_id: result.place_id ?? null,
  };
};

const getRoute = async ({
  origin,
  destination,
  travelMode = 'DRIVE',
}) => {
  const mapsKey = requireMapsServerKey();
  const normalizedOrigin = normalizeCoordinates(origin);
  const normalizedDestination = normalizeCoordinates(destination);
  const response = await fetch(ROUTES_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': mapsKey,
      'X-Goog-FieldMask':
        'routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline,routes.legs.localizedValues',
    },
    body: JSON.stringify({
      origin: {
        location: {
          latLng: {
            latitude: normalizedOrigin.latitude,
            longitude: normalizedOrigin.longitude,
          },
        },
      },
      destination: {
        location: {
          latLng: {
            latitude: normalizedDestination.latitude,
            longitude: normalizedDestination.longitude,
          },
        },
      },
      travelMode,
      routingPreference: 'TRAFFIC_AWARE',
      polylineQuality: 'OVERVIEW',
      polylineEncoding: 'ENCODED_POLYLINE',
      units: 'METRIC',
    }),
  });

  if (!response.ok) {
    throw new AppError(
      'Google Routes API request failed.',
      503,
      'route_lookup_failed'
    );
  }

  const payload = await response.json();
  const route = payload.routes?.[0];

  if (!route) {
    return null;
  }

  const distanceMeters = Number(route.distanceMeters) || 0;
  const durationSeconds = parseDurationSeconds(route.duration);

  return {
    travel_mode: travelMode,
    distance_meters: distanceMeters,
    distance_text: formatDistance(distanceMeters),
    duration_seconds: durationSeconds,
    duration_text: formatDuration(durationSeconds),
    encoded_polyline: route.polyline?.encodedPolyline ?? null,
  };
};

module.exports = {
  getRoute,
  reverseGeocode,
};
