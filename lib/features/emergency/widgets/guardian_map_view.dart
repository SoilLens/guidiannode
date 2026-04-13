import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GuardianMapView extends StatefulWidget {
  const GuardianMapView({
    super.key,
    required this.markers,
    this.polylines = const <Polyline>{},
    this.focusPoints = const <LatLng>[],
    this.initialCenter,
    this.initialZoom = 14,
    this.borderRadius = BorderRadius.zero,
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final List<LatLng> focusPoints;
  final LatLng? initialCenter;
  final double initialZoom;
  final BorderRadius borderRadius;

  @override
  State<GuardianMapView> createState() => _GuardianMapViewState();
}

class _GuardianMapViewState extends State<GuardianMapView> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant GuardianMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  Future<void> _fitBounds() async {
    final controller = _controller;
    final points = widget.focusPoints;

    if (controller == null || points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: widget.initialZoom),
        ),
      );
      return;
    }

    final latitudes = points.map((point) => point.latitude);
    final longitudes = points.map((point) => point.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(
        latitudes.reduce((value, element) => value < element ? value : element),
        longitudes.reduce(
          (value, element) => value < element ? value : element,
        ),
      ),
      northeast: LatLng(
        latitudes.reduce((value, element) => value > element ? value : element),
        longitudes.reduce(
          (value, element) => value > element ? value : element,
        ),
      ),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target:
              widget.initialCenter ??
              widget.focusPoints.firstOrNull ??
              const LatLng(5.9631, 10.1591),
          zoom: widget.initialZoom,
        ),
        markers: widget.markers,
        polylines: widget.polylines,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        onMapCreated: (controller) {
          _controller = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
        },
      ),
    );
  }
}

extension on List<LatLng> {
  LatLng? get firstOrNull => isEmpty ? null : first;
}
