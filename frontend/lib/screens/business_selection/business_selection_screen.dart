import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
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

// ── Multi-step setup bottom sheet ─────────────────────────────────────────────

class _BusinessSetupSheet extends StatefulWidget {
  final BusinessType type;
  const _BusinessSetupSheet({required this.type});

  @override
  State<_BusinessSetupSheet> createState() => _BusinessSetupSheetState();
}

class _BusinessSetupSheetState extends State<_BusinessSetupSheet> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  double _radiusKm = BusinessProvider.maxDeliveryRadiusKm;
  String _selectedPlan = 'free';

  bool get _hasDelivery =>
      ['restaurant', 'cafe', 'grocery', 'pharmacy', 'others']
          .contains(widget.type.id);

  // Subscription is always the last step for everyone
  int get _totalSteps => _hasDelivery ? 4 : 3;

  Color get _color => widget.type.color;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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
    final biz = context.read<BusinessProvider>();
    await biz.updateBusinessName(
        _nameCtrl.text.trim().isEmpty ? widget.type.title : _nameCtrl.text.trim());
    await biz.updateBusinessAddress(_addressCtrl.text.trim());
    await biz.updateHours(_openTime, _closeTime);
    if (_hasDelivery) await biz.updateDeliveryRadius(_radiusKm);
    await biz.updateSubscription(_selectedPlan);
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
  }

  Widget _buildStep(int step) {
    // Subscription is always the last step
    if (step == _totalSteps - 1) return _stepSubscription();
    switch (step) {
      case 0: return _stepNameAddress();
      case 1: return _stepHours();
      case 2: return _stepDelivery();
      default: return const SizedBox.shrink();
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

  // ── Step: Subscription Plan ───────────────────────────────────────────────
  Widget _stepSubscription() {
    final plans = [
      _PlanInfo('free',     'Free',       'Rs. 0',        '/month', Icons.store_outlined,        const Color(0xFF9E9E9E), ['Basic listing', '5 requests/month', 'Standard ranking']),
      _PlanInfo('starter',  'Starter',    'Rs. 999',      '/month', Icons.rocket_launch_rounded, const Color(0xFF43A047), ['20 requests/month', 'Basic analytics', 'Email support']),
      _PlanInfo('pro',      'Pro',        'Rs. 2,499',    '/month', Icons.workspace_premium,     const Color(0xFF6C63FF), ['Unlimited requests', 'Priority ranking', 'Push notifications']),
      _PlanInfo('business', 'Business',   'Rs. 4,999',    '/month', Icons.diamond_rounded,       const Color(0xFFFF9800), ['Featured listing', 'Multiple staff', 'Dedicated support']),
    ];

    return Column(
      key: const ValueKey('stepSub'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Plan',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Start free, upgrade anytime',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 18),
        ...plans.map((p) {
          final sel = _selectedPlan == p.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPlan = p.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sel ? p.color.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? p.color : AppColors.border,
                    width: sel ? 2 : 1),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: sel ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p.icon, color: p.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(p.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: sel ? p.color : AppColors.textPrimary)),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                  text: p.price,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: p.color)),
                              TextSpan(
                                  text: p.period,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textHint)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: p.features
                            .map((f) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 11, color: p.color),
                                const SizedBox(width: 2),
                                Text(f, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (sel)
                  Icon(Icons.check_circle_rounded, color: p.color, size: 22),
              ]),
            ),
          );
        }),
      ],
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

// ── Plan info data class ───────────────────────────────────────────────────────

class _PlanInfo {
  final String id;
  final String name;
  final String price;
  final String period;
  final IconData icon;
  final Color color;
  final List<String> features;

  const _PlanInfo(
      this.id, this.name, this.price, this.period,
      this.icon, this.color, this.features);
}
