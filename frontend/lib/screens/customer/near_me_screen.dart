import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/location_api.dart';
import '../../core/config/offline_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/geo.dart';
import '../../models/job_request.dart';
import '../../models/service_provider_profile_mapper.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/service_provider_directory_provider.dart';
import '../../models/service_provider_profile.dart';
import 'dart:io' show File;
import 'package:url_launcher/url_launcher.dart';

// ── Emergency quick-dial entries ──────────────────────────────────────────────

class _QuickDial {
  final String label;
  final IconData icon;
  final Color color;
  final String phone;
  const _QuickDial(this.label, this.icon, this.color, this.phone);
}

const _quickDials = [
  _QuickDial('Ambulance',   Icons.emergency_rounded,        Color(0xFFE53935), '115'),
  _QuickDial('Hospital',    Icons.local_hospital_rounded,   Color(0xFFD32F2F), '1122'),
  _QuickDial('Police',      Icons.local_police_rounded,     Color(0xFF1E88E5), '15'),
  _QuickDial('Electrician', Icons.electrical_services,      Color(0xFF5C6BC0), '1737'),
  _QuickDial('Plumber',     Icons.plumbing_rounded,         Color(0xFF00897B), '1020'),
  _QuickDial('Fire',        Icons.local_fire_department_rounded, Color(0xFFFF6F00), '16'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  static const double _radiusKm = 5.0;

  List<ServiceProviderProfile>? _apiProviders;
  double? _lastFetchedLat;
  double? _lastFetchedLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefreshApiProviders());
  }

  Future<void> _maybeRefreshApiProviders() async {
    if (OfflineMode.enabled || !mounted) return;
    final loc = context.read<LocationProvider>();
    final lat = loc.selectedAddress.lat;
    final lng = loc.selectedAddress.lng;
    if (lat == null || lng == null) return;
    if (lat == _lastFetchedLat && lng == _lastFetchedLng && _apiProviders != null) {
      return;
    }
    try {
      final api = LocationApi(ApiClient());
      final raw = await api.searchServiceProviders(
        nearLat: lat,
        nearLng: lng,
        radiusKm: _radiusKm,
      );
      if (!mounted) return;
      final mapped =
          raw.map(ServiceProviderProfileMapper.fromSearchApi).toList(growable: false);
      setState(() {
        _apiProviders = mapped;
        _lastFetchedLat = lat;
        _lastFetchedLng = lng;
      });
    } catch (_) {}
  }

  String _dedupeKey(ServiceProviderProfile p) {
    final ph = p.phone.trim();
    if (ph.isNotEmpty && ph != '—') return ph;
    return p.id.trim().isNotEmpty ? p.id : p.hashCode.toString();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final addr = loc.selectedAddress;
    final directory = context.watch<ServiceProviderDirectoryProvider>();

    final lat = addr.lat;
    final lng = addr.lng;
    if (!OfflineMode.enabled &&
        lat != null &&
        lng != null &&
        (lat != _lastFetchedLat || lng != _lastFetchedLng)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefreshApiProviders());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () async {
          _lastFetchedLat = null;
          _lastFetchedLng = null;
          await _maybeRefreshApiProviders();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(addr)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickDials(),
                _buildServiceProviders(directory),
                _buildComingSoonBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildComingSoonBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More services coming soon',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Workshops, medical, pet care, etc. next phase mein enable honge.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProviders(ServiceProviderDirectoryProvider directory) {
    final loc = context.read<LocationProvider>();
    final userLat = loc.selectedAddress.lat;
    final userLng = loc.selectedAddress.lng;

    final merged = <String, ServiceProviderProfile>{};
    for (final p in directory.providers) {
      merged[_dedupeKey(p)] = p;
    }
    final apiSlice = _apiProviders;
    if (apiSlice != null) {
      for (final p in apiSlice) {
        merged[_dedupeKey(p)] = p;
      }
    }

    final list = merged.values.where((p) {
      if (!p.isOnline) return false;
      if (userLat == null || userLng == null) return true; // fallback (no coords)
      if (p.lat == null || p.lng == null) return false;
      final km = distanceKm(userLat, userLng, p.lat!, p.lng!);
      return km <= _radiusKm;
    }).toList();

    list.sort((a, b) {
      if (userLat == null || userLng == null) return 0;
      final akm = (a.lat != null && a.lng != null)
          ? distanceKm(userLat, userLng, a.lat!, a.lng!)
          : 1e9;
      final bkm = (b.lat != null && b.lng != null)
          ? distanceKm(userLat, userLng, b.lat!, b.lng!)
          : 1e9;
      return akm.compareTo(bkm);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Providers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${list.length} near you',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'No providers yet. Service workers will appear here after signup.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          )
        else
          ...list.map((p) {
            final userLat2 = userLat;
            final userLng2 = userLng;
            final dist = (userLat2 != null &&
                    userLng2 != null &&
                    p.lat != null &&
                    p.lng != null)
                ? distanceKm(userLat2, userLng2, p.lat!, p.lng!)
                : null;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _ServiceProviderDetailScreen(
                      profile: p,
                      distanceKmFromUser: dist,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(p.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Available',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            p.profession,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (p.scrapRatesDisplay.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'PKR rates on profile · plastic, paper, iron…',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.call_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p.phone.trim().isEmpty ? '—' : p.phone.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dist == null
                                    ? '—'
                                    : '${dist.toStringAsFixed(1)} km away',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  p.areaLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _ServiceProviderDetailScreen(
                                        profile: p,
                                        distanceKmFromUser: dist,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_rounded,
                                            color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showDirectRequestSheet(p),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.build_rounded,
                                            color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Request',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showDirectRequestSheet(ServiceProviderProfile providerProfile) {
    final issueCtrl = TextEditingController();
    final loc = context.read<LocationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handyman_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Request Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        providerProfile.profession,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.selectedAddress.address,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: issueCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Describe your issue... (e.g., Wiring, fan, leakage, AC cooling)',
                hintStyle: const TextStyle(fontSize: 13),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (issueCtrl.text.trim().isEmpty) return;
                  final req = JobRequest(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userAddress: loc.selectedAddress.address,
                    issue: issueCtrl.text.trim(),
                    serviceTypeId: 'homeservice',
                    serviceTypeName: providerProfile.profession,
                    createdAt: DateTime.now(),
                  );
                  context.read<JobProvider>().addRequest(req);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Request sent! Provider will respond soon.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ]),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Send Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(SavedAddress addr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 14,
        left: 20, right: 20, bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Near Me',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  addr.address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.my_location_rounded,
                        color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      '5 km radius',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Emergency quick-dial ──────────────────────────────────────────────────

  Widget _buildQuickDials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(children: [
            Icon(Icons.emergency_rounded, color: Colors.red, size: 18),
            SizedBox(width: 6),
            Text('Emergency Numbers',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
          ]),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _quickDials.length,
            itemBuilder: (_, i) {
              final q = _quickDials[i];
              return GestureDetector(
                onTap: () => _dial(q.label, q.phone),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: q.color.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: q.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(q.icon, color: q.color, size: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(q.label,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(q.phone,
                          style: TextStyle(
                              fontSize: 9,
                              color: q.color,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _dial(String name, String phone) {
    final raw = phone.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ServiceProviderDetailScreen extends StatelessWidget {
  final ServiceProviderProfile profile;
  final double? distanceKmFromUser;
  const _ServiceProviderDetailScreen({
    required this.profile,
    this.distanceKmFromUser,
  });

  @override
  Widget build(BuildContext context) {
    final expYears = _experienceYears(profile.createdAt);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Provider Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientPrimary),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _providerAvatar(profile),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.profession,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (expYears != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Experience: $expYears year${expYears == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        profile.phone,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _row('Area', profile.areaLabel),
                if (distanceKmFromUser != null)
                  _row('Distance', '${distanceKmFromUser!.toStringAsFixed(1)} km'),
                if (expYears != null)
                  _row(
                    'Experience',
                    '$expYears year${expYears == 1 ? '' : 's'}',
                  ),
              ],
            ),
          ),
          if (profile.scrapRatesDisplay.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_outlined,
                          size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Scrap / kabar rates (PKR)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Indicative rates — quality & daily market move kar sakti hai. '
                    'Final weight pe call par confirm karein.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...profile.scrapRatesDisplay.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              e.value,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final raw = profile.phone.trim();
                    final digits = raw.replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty) return;
                    final uri = Uri(scheme: 'tel', path: digits);
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static int? _experienceYears(DateTime createdAt) {
    // If we don't have a real "experience" field yet, we approximate using profile age.
    final now = DateTime.now();
    final days = now.difference(createdAt).inDays;
    if (days < 30) return null; // too new → hide rather than show 0 years
    final years = (days / 365).floor();
    return years < 1 ? 1 : years;
  }

  static Widget _providerAvatar(ServiceProviderProfile p) {
    final path = (p.imagePath ?? '').trim();
    if (path.isEmpty) {
      return Center(child: Icon(p.icon, color: Colors.white, size: 30));
    }
    final isUrl = path.startsWith('http://') || path.startsWith('https://');
    if (isUrl) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Center(child: Icon(p.icon, color: Colors.white, size: 30)),
      );
    }
    // Local file path (best-effort). If file doesn't exist on this device, fallback.
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Center(child: Icon(p.icon, color: Colors.white, size: 30)),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
