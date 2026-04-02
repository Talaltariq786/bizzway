import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/business.dart';
import '../../models/job_request.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import 'business_detail_screen.dart';

// ── Near-me category definition ───────────────────────────────────────────────

class _NearCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<String> typeIds; // maps to Business.businessTypeId
  const _NearCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.typeIds,
  });
}

const _categories = [
  _NearCategory(id: 'all',     label: 'All',          icon: Icons.grid_view_rounded,      color: Color(0xFF6C63FF), typeIds: []),
  _NearCategory(id: 'medical', label: 'Medical',      icon: Icons.local_hospital_rounded, color: Color(0xFFE53935), typeIds: ['clinic', 'pharmacy']),
  _NearCategory(id: 'auto',    label: 'Auto',         icon: Icons.build_rounded,          color: Color(0xFF455A64), typeIds: ['mechanic']),

];

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
  String _selectedCat = 'all';

  // Fake distance for demo (index → km)
  static const _fakeDist = [
    0.4, 0.8, 1.2, 1.5, 1.9, 2.1, 2.4, 2.7, 3.0, 3.4,
    3.6, 3.9, 4.1, 4.5, 4.8, 5.0,
  ];

  double _distFor(int index) => _fakeDist[index % _fakeDist.length];

  List<Business> get _filtered {
    // Medical (clinics/pharmacy) always show; mechanic only when online (isOpen)
    var list = allDummyBusinesses.where((b) {
      if (b.businessTypeId == 'clinic' || b.businessTypeId == 'pharmacy') {
        return true;
      }
      if (b.businessTypeId == 'mechanic') {
        return b.isOpen; // isOpen acts as "provider is online"
      }
      return false;
    }).toList();

    if (_selectedCat != 'all') {
      final cat = _categories.firstWhere((c) => c.id == _selectedCat);
      list = list.where((b) => cat.typeIds.contains(b.businessTypeId)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final addr = loc.selectedAddress;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader(addr)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickDials(),
                _buildCategoryFilter(),
                _buildList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Near Me',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(addr.address,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
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
                  Text('5 km radius',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ]),
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

  // ── Category filter ───────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nearby Services',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
              Text('${_filtered.length} found',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = _selectedCat == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCat = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? cat.color : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cat.icon,
                        size: 13,
                        color: sel ? Colors.white : cat.color),
                    const SizedBox(width: 5),
                    Text(cat.label,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : cat.color)),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Service list ──────────────────────────────────────────────────────────

  Widget _buildList() {
    final list = _filtered;
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_off_rounded,
                size: 52, color: AppColors.textHint),
            SizedBox(height: 10),
            Text('No services found nearby',
                style: TextStyle(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    return Column(
      children: list.indexed.map((e) {
        final index = e.$1;
        final biz = e.$2;
        return _ServiceCard(
          biz: biz,
          distanceKm: _distFor(index),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BusinessDetailScreen(business: biz)),
          ),
          onCall: () => _dial(biz.name, biz.phone ?? '—'),
          onRequest: () => _showRequestSheet(biz),
        );
      }).toList(),
    );
  }

  String _getHintText(String businessTypeId) {
    switch (businessTypeId) {
      case 'mechanic':
        return 'Describe your vehicle issue... (e.g., Car tyre puncture, Oil change needed, AC not working)';
      case 'beauty':
        return 'Describe your requirement... (e.g., Facial treatment, Waxing, Threading)';
      case 'salon':
        return 'Describe your service need... (e.g., Haircut, Hair coloring, Spa treatment)';
      case 'petcare':
        return 'Describe your pet care need... (e.g., Vet consultation, Grooming, Vaccination)';
      default:
        return 'Describe your issue or service need...';
    }
  }

  void _showRequestSheet(Business biz) {
    final issueCtrl = TextEditingController();
    final loc = context.read<LocationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: biz.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(biz.typeIcon, color: biz.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request Service',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.textPrimary)),
                    Text(biz.name,
                        style: TextStyle(
                            fontSize: 12, color: biz.color)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 18),
            // Delivery address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(loc.selectedAddress.address,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: issueCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _getHintText(biz.businessTypeId),
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: biz.color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: biz.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (issueCtrl.text.trim().isEmpty) return;
                  final req = JobRequest(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userAddress: loc.selectedAddress.address,
                    issue: issueCtrl.text.trim(),
                    serviceTypeId: biz.businessTypeId,
                    serviceTypeName: biz.name,
                    createdAt: DateTime.now(),
                  );
                  context.read<JobProvider>().addRequest(req);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Row(children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Request sent! Provider will respond soon.',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                },
                child: const Text('Send Request',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dial(String name, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.call_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Calling $name — $phone',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: const Color(0xFF1A3A5C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final Business biz;
  final double distanceKm;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onRequest;

  const _ServiceCard({
    required this.biz,
    required this.distanceKm,
    required this.onTap,
    required this.onCall,
    required this.onRequest,
  });

  bool get _canRequest =>
      biz.businessTypeId == 'mechanic' ||
      biz.businessTypeId == 'beauty' ||
      biz.businessTypeId == 'salon' ||
      biz.businessTypeId == 'petcare';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          // ── Icon ──────────────────────────────────────────────────
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [biz.color, biz.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(biz.typeIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),

          // ── Info ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(biz.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: biz.isOpen
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      biz.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: biz.isOpen
                              ? Colors.green.shade700
                              : Colors.red.shade700),
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 11, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(biz.address,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 13),
                  const SizedBox(width: 2),
                  Text('${biz.rating}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary)),
                  Text('  (${biz.reviewCount})',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: biz.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.near_me_rounded,
                          size: 10, color: biz.color),
                      const SizedBox(width: 3),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: biz.color),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  if (biz.phone != null) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: onCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: biz.color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('Call Now',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_canRequest) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: onRequest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.build_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text('Request',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        color: biz.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: biz.color.withValues(alpha: 0.3)),
                      ),
                      child: Text('View',
                          style: TextStyle(
                              color: biz.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
