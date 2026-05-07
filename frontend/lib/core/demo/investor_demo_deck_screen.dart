import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class InvestorDemoDeckScreen extends StatefulWidget {
  const InvestorDemoDeckScreen({super.key});

  @override
  State<InvestorDemoDeckScreen> createState() => _InvestorDemoDeckScreenState();
}

class _InvestorDemoDeckScreenState extends State<InvestorDemoDeckScreen> {
  final _merchantsCtrl = TextEditingController(text: '200');
  final _planPriceCtrl = TextEditingController(text: '49');
  final _ordersCtrl = TextEditingController(text: '12000');
  final _feePerOrderCtrl = TextEditingController(text: '0.20');
  final _featuredCtrl = TextEditingController(text: '30');
  final _featuredFeeCtrl = TextEditingController(text: '50');

  int _asInt(TextEditingController c, int fallback) =>
      int.tryParse(c.text.trim()) ?? fallback;

  double _asDouble(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  @override
  void dispose() {
    _merchantsCtrl.dispose();
    _planPriceCtrl.dispose();
    _ordersCtrl.dispose();
    _feePerOrderCtrl.dispose();
    _featuredCtrl.dispose();
    _featuredFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchants = _asInt(_merchantsCtrl, 200);
    final planPrice = _asDouble(_planPriceCtrl, 49);
    final orders = _asInt(_ordersCtrl, 12000);
    final feePerOrder = _asDouble(_feePerOrderCtrl, 0.20);
    final featured = _asInt(_featuredCtrl, 30);
    final featuredFee = _asDouble(_featuredFeeCtrl, 50);

    final subRev = merchants * planPrice;
    final txnRev = orders * feePerOrder;
    final featRev = featured * featuredFee;
    final total = subRev + txnRev + featRev;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Investor demo deck',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              const SizedBox(height: 14),
              _sectionTitle('How it works (one slide)'),
              const SizedBox(height: 10),
              _bullets(const [
                'Merchant sets up business type and adds items/deals.',
                'Customer discovers nearby options, places an order, and tracks status.',
                'Team rider delivers (merchant-owned riders using “Team rider login”).',
                'Service providers accept nearby jobs and complete work with live map support.',
              ]),
              const SizedBox(height: 16),
              _sectionTitle('Revenue model (simple)'),
              const SizedBox(height: 10),
              _bullets(const [
                'Subscriptions: monthly plans for merchants and service providers.',
                'Usage fees: per order / booking / delivery as volume grows.',
                'Paid promotions: featured listings and deal highlights.',
              ]),
              const SizedBox(height: 14),
              _sectionTitle('Quick calculator (edit numbers)'),
              const SizedBox(height: 10),
              _card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Active merchants',
                            ctrl: _merchantsCtrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            label: 'Plan price / month',
                            ctrl: _planPriceCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Monthly orders',
                            ctrl: _ordersCtrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            label: 'Fee per order',
                            ctrl: _feePerOrderCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            label: 'Featured merchants',
                            ctrl: _featuredCtrl,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            label: 'Featured fee / month',
                            ctrl: _featuredFeeCtrl,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statRow('Subscriptions', _fmt(subRev)),
                          const SizedBox(height: 6),
                          _statRow('Usage fees', _fmt(txnRev)),
                          const SizedBox(height: 6),
                          _statRow('Featured listings', _fmt(featRev)),
                          const Divider(height: 18),
                          _statRow(
                            'Total monthly revenue (example)',
                            _fmt(total),
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('12‑month plan (high-level)'),
              const SizedBox(height: 10),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _RoadmapRow(
                      title: 'Months 1–2',
                      body: 'Stabilize onboarding + demo mode + core ops.',
                    ),
                    SizedBox(height: 10),
                    _RoadmapRow(
                      title: 'Months 3–5',
                      body: 'Retention: dispatch flow, notifications, analytics, upgrades.',
                    ),
                    SizedBox(height: 10),
                    _RoadmapRow(
                      title: 'Months 6–9',
                      body: 'Growth: promotions, featured listings, service marketplace improvements.',
                    ),
                    SizedBox(height: 10),
                    _RoadmapRow(
                      title: 'Months 10–12',
                      body: 'Expansion: partnerships + optional platform-wide riders (phase 2).',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle('Final takeaway'),
              const SizedBox(height: 10),
              _card(
                child: const Text(
                  'One system that runs the loop: merchant setup → customer order → fulfilment → tracking → revenue.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Master demo summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: -0.25,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'A clean story you can narrate: what it is, how the flows work, and how it makes money.',
            style: TextStyle(
              color: Colors.white,
              height: 1.35,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.15,
        ),
      );

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _bullets(List<String> lines) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _field({required String label, required TextEditingController ctrl}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _statRow(String label, String value, {bool strong = false}) {
    final style = TextStyle(
      color: AppColors.textPrimary,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
      fontSize: strong ? 13.5 : 13,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }

  String _fmt(num v) {
    // Keep currency-agnostic: investors can map to their region.
    final s = v.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'\\B(?=(\\d{3})+(?!\\d))'),
      (m) => ',',
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

