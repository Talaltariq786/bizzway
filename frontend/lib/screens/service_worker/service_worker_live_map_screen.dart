import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/location_api.dart';
import '../../core/config/offline_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service_provider_profile.dart';
import '../../providers/service_provider_directory_provider.dart';

class ServiceWorkerLiveMapScreen extends StatefulWidget {
  const ServiceWorkerLiveMapScreen({super.key});

  @override
  State<ServiceWorkerLiveMapScreen> createState() =>
      _ServiceWorkerLiveMapScreenState();
}

class _ServiceWorkerLiveMapScreenState extends State<ServiceWorkerLiveMapScreen> {
  GoogleMapController? _map;
  StreamSubscription<Position>? _sub;
  String? _error;
  LatLng? _pos;

  static const LatLng _fallback = LatLng(24.8607, 67.0011); // Karachi approx

  @override
  void initState() {
    super.initState();
    Future.microtask(_start);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _error = 'Location services OFF hain');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        if (!mounted) return;
        setState(() => _error = 'Location permission denied');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _error = 'Location permission permanently denied');
        return;
      }

      if (!mounted) return;

      final settings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // meters
      );

      _sub?.cancel();
      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (p) async {
          final next = LatLng(p.latitude, p.longitude);
          if (!mounted) return;
          final directory = context.read<ServiceProviderDirectoryProvider>();
          setState(() {
            _pos = next;
            _error = null;
          });

          // Smoothly follow.
          await _map?.animateCamera(CameraUpdate.newLatLng(next));
          if (!mounted) return;

          // Persist to local directory so customer "Near Me" updates.
          final prefs = await SharedPreferences.getInstance();
          final providerId = (prefs.getString('active_provider_id') ?? '').trim();
          if (providerId.isEmpty) return;
          if (!mounted) return;

          final current = directory.providers
              .where((x) => x.id == providerId)
              .cast<ServiceProviderProfile?>()
              .firstWhere((x) => x != null, orElse: () => null);
          if (current == null) return;

          directory.upsert(
            ServiceProviderProfile(
              id: current.id,
              name: current.name,
              phone: current.phone,
              profession: current.profession,
              nic: current.nic,
              imagePath: current.imagePath,
              plan: current.plan,
              isOnline: true,
              areaLabel: current.areaLabel,
              lat: p.latitude,
              lng: p.longitude,
              updatedAt: DateTime.now(),
              createdAt: current.createdAt,
              scrapRatesDisplay: current.scrapRatesDisplay,
            ),
          );
          if (!OfflineMode.enabled) {
            try {
              await LocationApi(ApiClient()).postServiceProviderLocation(
                lat: p.latitude,
                lng: p.longitude,
              );
            } catch (_) {}
          }
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _error = e.toString());
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = _pos ?? _fallback;
    final marker = Marker(
      markerId: const MarkerId('me'),
      position: pos,
      infoWindow: const InfoWindow(title: 'You'),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: {marker},
              onMapCreated: (c) => _map = c,
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _pos == null
                        ? 'Waiting for GPS...'
                        : 'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

