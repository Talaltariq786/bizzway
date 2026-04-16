import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_colors.dart';
import 'geocode_format.dart';
import 'map_location_result.dart';

/// Full-screen map: drag pin or tap map, confirm with reverse geocoding.
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    this.title = 'Pin your location',
  });

  final double initialLat;
  final double initialLng;
  final String title;

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  GoogleMapController? _map;
  late LatLng _markerPosition;
  bool _busy = false;
  bool _mapReady = false;

  static const _fallbackZoom = 15.0;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat.isFinite ? widget.initialLat : 24.8607;
    final lng = widget.initialLng.isFinite ? widget.initialLng : 67.0011;
    _markerPosition = LatLng(lat, lng);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isEmpty) {
        return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
      }
      return formatPlacemarkLine(list.first, lat: lat, lng: lng);
    } catch (_) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
  }

  Future<void> _myLocation() async {
    setState(() => _busy = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission chahiye. Settings se allow karein.',
              ),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _markerPosition = ll);
      await _map?.animateCamera(
        CameraUpdate.newLatLngZoom(ll, _fallbackZoom),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location nahi mil saki: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final lat = _markerPosition.latitude;
      final lng = _markerPosition.longitude;
      final line = await _reverseGeocode(lat, lng);
      if (!mounted) return;
      Navigator.pop<MapLocationResult>(
        context,
        MapLocationResult(lat: lat, lng: lng, addressLine: line),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Confirm nahi ho saka: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _markerPosition,
              zoom: _fallbackZoom,
            ),
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('pick'),
                position: _markerPosition,
                draggable: true,
                onDragEnd: (LatLng p) => setState(() => _markerPosition = p),
              ),
            },
            onMapCreated: (c) {
              _map = c;
              setState(() => _mapReady = true);
            },
            onTap: (LatLng p) => setState(() => _markerPosition = p),
          ),
          if (!_mapReady)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Map load ho rahi hai…'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'myLoc',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: _busy ? null : _myLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pin drag karein ya map tap karein',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _confirm,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_busy ? '…' : 'Yeh location use karein'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
