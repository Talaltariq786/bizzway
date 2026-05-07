import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io' show File;
import '../../core/constants/app_colors.dart';
import '../../core/constants/stock_photo_catalog.dart';
import '../../core/maps/map_location_picker_screen.dart';
import '../../core/maps/map_location_result.dart';
import '../../core/routes/app_routes.dart';
import '../../core/demo/demo_typewriter.dart';
import '../../models/business_type.dart';
import '../../providers/business_provider.dart';

class BusinessSelectionScreen extends StatelessWidget {
  const BusinessSelectionScreen({super.key});

  /// Live scope for owner flow: only these types are open for setup.
  static const Set<String> _liveOwnerTypes = {
    'restaurant',
    'grocery',
    'rentacar',
  };

  @override
  Widget build(BuildContext context) {
    final businesses = BusinessType.all
        .where((b) => !BusinessType.excludedFromOwnerSelection.contains(b.id))
        .toList()
      ..sort((a, b) {
        final aLive = _liveOwnerTypes.contains(a.id);
        final bLive = _liveOwnerTypes.contains(b.id);
        if (aLive != bLive) return aLive ? -1 : 1; // live types first
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 16),
                  const Text('What kind of\nbusiness do you run?',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2)),
                  const SizedBox(height: 8),
                  const Text(
                    'Pehli dafa setup — login alag hai. Yeh type baad mein profile se change nahi hoti.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimationLimiter(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: businesses.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 400),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _BusinessCard(business: businesses[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Business type card ────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  final BusinessType business;
  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final isComingSoon =
        !BusinessSelectionScreen._liveOwnerTypes.contains(business.id);
    return GestureDetector(
      onTap: isComingSoon
          ? null
          : () async {
              await context.read<BusinessProvider>().selectBusiness(business);
              if (!context.mounted) return;
              await _showSetupSheet(context, business);
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: business.color.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: business.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(business.icon, color: business.color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  business.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComingSoon
                      ? 'Coming soon'
                      : '${business.categories.length} categories',
                  style: TextStyle(
                    fontSize: 11,
                    color: isComingSoon ? AppColors.textSecondary : AppColors.textHint,
                    fontWeight: isComingSoon ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (isComingSoon)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Coming soon',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetupSheet(
      BuildContext context, BusinessType type) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BusinessSetupSheet(type: type),
    );
  }
}

/// Investor recording: same onboarding sheet as a live business tap, with auto-type + captions.
Future<void> openInvestorDemoBusinessSetupSheet(
  BuildContext context, {
  String businessTypeId = 'grocery',
}) async {
  final businesses = BusinessType.all
      .where((b) => !BusinessType.excludedFromOwnerSelection.contains(b.id))
      .toList();
  final match =
      businesses.where((b) => b.id == businessTypeId).toList();
  final type =
      match.isNotEmpty ? match.first : businesses.first;
  // Keep provider in sync so downstream screens (catalog/orders/team riders) have a business id.
  try {
    await context.read<BusinessProvider>().selectBusiness(type);
  } catch (_) {}
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BusinessSetupSheet(
      type: type,
      investorDemoFill: true,
    ),
  );
}

// ── Multi-step setup bottom sheet ─────────────────────────────────────────────

class _BusinessSetupSheet extends StatefulWidget {
  final BusinessType type;
  final bool investorDemoFill;

  const _BusinessSetupSheet({
    required this.type,
    this.investorDemoFill = false,
  });

  @override
  State<_BusinessSetupSheet> createState() => _BusinessSetupSheetState();
}

class _BusinessSetupSheetState extends State<_BusinessSetupSheet> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _coverValue; // file path OR https URL
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  double _radiusKm = BusinessProvider.maxDeliveryRadiusKm;
  double _pinLat = BusinessProvider.defaultBusinessLat;
  double _pinLng = BusinessProvider.defaultBusinessLng;
  bool _pinSet = false;
  bool _seededFromProvider = false;
  String _investorCaption = '';

  bool get _hasDelivery =>
      ['restaurant', 'cafe', 'grocery', 'pharmacy', 'others']
          .contains(widget.type.id);

  /// Name + address + map, hours, [delivery radius]. No paid plan — always free.
  int get _totalSteps => _hasDelivery ? 3 : 2;

  Color get _color => widget.type.color;

  @override
  void initState() {
    super.initState();
    if (widget.investorDemoFill) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runInvestorDemoFill();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededFromProvider) return;
    _seededFromProvider = true;
    final b = context.read<BusinessProvider>();
    _pinLat = b.businessLat;
    _pinLng = b.businessLng;
    if (b.businessName.trim().isNotEmpty) {
      _nameCtrl.text = b.businessName;
    }
    if (b.businessAddress.trim().isNotEmpty) {
      _addressCtrl.text = b.businessAddress;
    }
    if (b.businessPinConfirmed) {
      _pinSet = true;
    }
    if ((_coverValue ?? '').isEmpty && b.businessCoverImagePath.trim().isNotEmpty) {
      _coverValue = b.businessCoverImagePath.trim();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _runInvestorDemoFill() async {
    if (!widget.investorDemoFill || !mounted) return;

    Future<void> caption(String s) async {
      if (!mounted) return;
      setState(() => _investorCaption = s);
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }

    await caption(
      'Enter the display name — the cover image is the hero customers see first.',
    );
    await DemoTypewriter.fill(
      _nameCtrl,
      'Karachi Demo Mart',
      shouldAbort: () => !mounted,
    );
    await Future<void>.delayed(const Duration(milliseconds: 520));
    final urls = StockPhotoCatalog.coverSuggestionsForBusiness(widget.type.id);
    if (!mounted) return;
    if (urls.isNotEmpty) setState(() => _coverValue = urls.first);
    await Future<void>.delayed(const Duration(milliseconds: 900));

    await caption(
      'Address and map pin — fixes your listing on Near Me and dispatch distance.',
    );
    await DemoTypewriter.fill(
      _addressCtrl,
      'Block 6, Gulistan-e-Jauhar, Karachi',
      shouldAbort: () => !mounted,
    );
    if (!mounted) return;
    setState(() {
      _pinLat = 24.9056;
      _pinLng = 67.1483;
      _pinSet = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1600));

    if (!_hasDelivery) {
      await caption(
        'Demo ends here — you can close the sheet.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 3200));
      if (mounted) Navigator.pop(context);
      return;
    }

    await caption(
      'Operating hours — customers only see you as open inside this window.',
    );
    if (!mounted) return;
    setState(() {
      _step = 1;
      _openTime = const TimeOfDay(hour: 10, minute: 0);
      _closeTime = const TimeOfDay(hour: 23, minute: 30);
    });
    await Future<void>.delayed(const Duration(milliseconds: 3200));

    await caption(
      'Delivery radius — maximum distance you deliver (up to '
      '${BusinessProvider.maxDeliveryRadiusKm.toStringAsFixed(0)} km).',
    );
    if (!mounted) return;
    setState(() {
      _step = 2;
      _radiusKm = 4;
    });
    await Future<void>.delayed(const Duration(milliseconds: 4500));

    await caption(
      'Launch Business opens the dashboard — this demo closes the sheet automatically.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 3800));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickShopPin() async {
    final r = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute<MapLocationResult>(
        fullscreenDialog: true,
        builder: (_) => MapLocationPickerScreen(
          initialLat: _pinLat,
          initialLng: _pinLng,
          title: 'Shop location',
        ),
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      _pinLat = r.lat;
      _pinLng = r.lng;
      _pinSet = true;
      if (_addressCtrl.text.trim().isEmpty &&
          r.addressLine.trim().isNotEmpty) {
        _addressCtrl.text = r.addressLine.trim();
      }
    });
  }

  Future<void> _pickCoverImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    setState(() => _coverValue = file.path);
  }

  Future<void> _chooseCoverFromLibrary() async {
    final urls = StockPhotoCatalog.coverSuggestionsForBusiness(widget.type.id);
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose a cover (HD)',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pakistan-style food images — crisp header look.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: urls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, i) {
                final u = urls[i];
                return InkWell(
                  onTap: () => Navigator.pop(ctx, u),
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(u, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _coverValue = picked);
  }

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');

  ImageProvider? _coverProvider() {
    final v = (_coverValue ?? '').trim();
    if (v.isEmpty) return null;
    if (_isUrl(v)) return NetworkImage(v);
    return FileImage(File(v));
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _pickTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _openTime : _closeTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _color),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime = picked;
        } else {
          _closeTime = picked;
        }
      });
    }
  }

  Future<void> _finish() async {
    if ((_coverValue ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cover photo zaroor upload karein (shop/profile header).'),
          backgroundColor: widget.type.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _step = 0);
      return;
    }
    if (!_pinSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Map se shop ki location pin karein — Near Me ke liye zaroori.'),
          backgroundColor: widget.type.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _step = 0);
      return;
    }
    final biz = context.read<BusinessProvider>();
    await biz.updateBusinessName(
        _nameCtrl.text.trim().isEmpty ? widget.type.title : _nameCtrl.text.trim());
    await biz.updateBusinessAddress(_addressCtrl.text.trim());
    await biz.updateBusinessCoverImagePath(_coverValue!.trim());
    await biz.updateBusinessPin(_pinLat, _pinLng);
    await biz.updateHours(_openTime, _closeTime);
    if (_hasDelivery) await biz.updateDeliveryRadius(_radiusKm);
    await biz.updateSubscription('free');
    biz.debugLogLocalProfile('setupSheet_saved→prefs');
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Progress dots
          Row(
            children: List.generate(_totalSteps, (i) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _step ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _step ? _color : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
          const SizedBox(height: 20),

          // Step content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(_step),
          ),

          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: _color),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back',
                        style: TextStyle(color: _color, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _step < _totalSteps - 1
                      ? () => setState(() => _step++)
                      : _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _step < _totalSteps - 1 ? 'Continue' : 'Launch Business 🚀',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!widget.investorDemoFill) return sheet;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        sheet,
        if (_investorCaption.trim().isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  _investorCaption,
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 1.42,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _stepNameAddress();
      case 1:
        return _stepHours();
      case 2:
        return _stepDelivery();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Name + Address ────────────────────────────────────────────────
  Widget _stepNameAddress() {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(widget.type.icon, color: _color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.type.title,
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const Text('Setup your business',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ]),
        ]),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              image: _coverProvider() == null
                  ? null
                  : DecorationImage(image: _coverProvider()!, fit: BoxFit.cover),
            ),
            child: (_coverValue ?? '').trim().isNotEmpty
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Change cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_camera_back_rounded,
                          color: _color,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload cover photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Yeh customer ko header me nazar aayegi',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _chooseCoverFromLibrary,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose Food HD'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _field(
          controller: _nameCtrl,
          label: 'Business Name',
          hint: 'e.g. BBQ Tonight, Glamour Studio',
          icon: Icons.store_rounded,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _addressCtrl,
          label: 'Business Address',
          hint: 'Street, Area, City',
          icon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickShopPin,
          icon: const Icon(Icons.map_rounded, size: 20),
          label: Text(
            _pinSet ? 'Update map pin' : 'Set location on map',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            side: BorderSide(color: _color.withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _pinSet
              ? 'Pin: ${_pinLat.toStringAsFixed(5)}, ${_pinLng.toStringAsFixed(5)}'
              : 'Map par pin zaroor set karein taake Near Me sahi kaam kare.',
          style: TextStyle(
            fontSize: 12,
            color: _pinSet ? AppColors.textSecondary : _color,
            fontWeight: _pinSet ? FontWeight.w500 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Step 2: Operating Hours ───────────────────────────────────────────────
  Widget _stepHours() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Operating Hours',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('When is your business open?',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _timeTile('Opens at', _openTime, true)),
          const SizedBox(width: 12),
          Expanded(child: _timeTile('Closes at', _closeTime, false)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, color: _color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Customers will see your business as "Open" only during these hours',
                style: TextStyle(
                    fontSize: 12, color: _color),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _timeTile(String label, TimeOfDay time, bool isOpen) {
    return GestureDetector(
      onTap: () => _pickTime(isOpen),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(14),
          color: _color.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(_fmt(time),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _color)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.edit_rounded, size: 12, color: _color),
              const SizedBox(width: 4),
              Text('Tap to change',
                  style: TextStyle(fontSize: 10, color: _color)),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Delivery Radius ───────────────────────────────────────────────
  Widget _stepDelivery() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Area',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        const Text('How far can you deliver?',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_color, _color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_radiusKm.toStringAsFixed(0),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const Text('km radius',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _color,
            thumbColor: _color,
            inactiveTrackColor: _color.withValues(alpha: 0.2),
            overlayColor: _color.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: _radiusKm,
            min: BusinessProvider.minDeliveryRadiusKm,
            max: BusinessProvider.maxDeliveryRadiusKm,
            divisions: 4,
            label: '${_radiusKm.toStringAsFixed(0)} km',
            onChanged: (v) => setState(() => _radiusKm = v.clamp(
                  BusinessProvider.minDeliveryRadiusKm,
                  BusinessProvider.maxDeliveryRadiusKm,
                )),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${BusinessProvider.minDeliveryRadiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            Text('${BusinessProvider.maxDeliveryRadiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        _radiusTip(),
      ],
    );
  }

  // ── (Paid plans removed — MVP subscription is always free.) ─────────────────

  Widget _radiusTip() {
    final r = _radiusKm;
    String tip;
    if (r <= 2) {
      tip = 'Hyperlocal — perfect for walk-in area only';
    } else if (r <= 4) {
      tip = 'Neighborhood delivery — most popular';
    } else {
      tip = 'Large area — consider delivery charges';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(tip,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.primary)),
        ),
      ]),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _color, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
