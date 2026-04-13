import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> decodeEncodedPolyline(String? encodedPolyline) {
  if (encodedPolyline == null || encodedPolyline.isEmpty) {
    return const <LatLng>[];
  }

  final coordinates = <LatLng>[];
  var index = 0;
  var latitude = 0;
  var longitude = 0;

  while (index < encodedPolyline.length) {
    var result = 0;
    var shift = 0;
    int byte;

    do {
      byte = encodedPolyline.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final latitudeChange = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    latitude += latitudeChange;

    result = 0;
    shift = 0;

    do {
      byte = encodedPolyline.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    final longitudeChange = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    longitude += longitudeChange;

    coordinates.add(LatLng(latitude / 1e5, longitude / 1e5));
  }

  return coordinates;
}
