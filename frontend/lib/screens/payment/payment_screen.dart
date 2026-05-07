import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/subscription_api.dart';
import '../../core/config/offline_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/custom_button.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPlanId = 'pro';
  String _provider = 'jazzcash';
  bool _loadingPlans = true;
  String? _plansError;
  List<Map<String, dynamic>> _plans = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final biz = context.read<BusinessProvider>();
    await biz.syncRemoteBusinessWithApi();
    await biz.ensureRemoteBusinessExists();
    await biz.syncSubscriptionFromApi();
    await _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (OfflineMode.enabled) {
      setState(() {
        _loadingPlans = false;
        _plans = _fallbackPlanMaps();
        _plansError = 'OFFLINE_MODE=true — backend plans nahi aaye. Yeh default prices hain; live ke liye `OFFLINE_MODE=false` run karein.';
      });
      return;
    }
    setState(() {
      _loadingPlans = true;
      _plansError = null;
    });
    try {
      final list = await SubscriptionApi.fetchPlans();
      if (list.isEmpty) {
        setState(() {
          _plans = _fallbackPlanMaps();
          _loadingPlans = false;
          _plansError = 'Server se plan list khaali — default dikha rahe hain.';
        });
      } else {
        setState(() {
          _plans = list;
          _loadingPlans = false;
        });
        if (!_plans.any((p) => p['id']?.toString() == _selectedPlanId)) {
          _selectedPlanId = _plans.first['id']?.toString() ?? 'pro';
        }
      }
    } catch (e) {
      setState(() {
        _plans = _fallbackPlanMaps();
        _loadingPlans = false;
        _plansError = e is ApiException
            ? e.message
            : 'Plans load nahi ho sake — default dikha rahe hain.';
      });
    }
  }

  /// Matches backend [MERCHANT_SUBSCRIPTION_PLANS] when API is down.
  List<Map<String, dynamic>> _fallbackPlanMaps() {
    return [
      {
        'id': 'starter',
        'label': 'Starter',
        'amountPkr': 999,
        'periodDays': 30,
        'description': 'Ziyada products + support',
      },
      {
        'id': 'pro',
        'label': 'Pro',
        'amountPkr': 2499,
        'periodDays': 30,
        'description': 'Advanced tools',
      },
      {
        'id': 'business',
        'label': 'Business',
        'amountPkr': 4999,
        'periodDays': 30,
        'description': 'Full suite',
      },
    ];
  }

  int _amountPkr(Map<String, dynamic> p) {
    final a = p['amountPkr'];
    if (a is int) return a;
    if (a is num) return a.round();
    return int.tryParse(a?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final biz = context.watch<BusinessProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.subscription),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () async {
              await _bootstrap();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (OfflineMode.enabled) _offlineBanner(),
            if (_plansError != null) _errorBanner(_plansError!),
            _buildCurrentPlanBanner(biz),
            const SizedBox(height: 20),
            Text('Payment method', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'jazzcash',
                  label: Text('JazzCash'),
                  icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                ),
                ButtonSegment(
                  value: 'easypaisa',
                  label: Text('EasyPaisa'),
                  icon: Icon(Icons.payments_outlined, size: 18),
                ),
              ],
              selected: {_provider},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) setState(() => _provider = s.first);
              },
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.upgradePlan,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_loadingPlans)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              ..._plans.map((p) {
                final id = p['id']?.toString() ?? '';
                return _PlanCard(
                  planId: id,
                  label: p['label']?.toString() ?? id,
                  pricePkr: _amountPkr(p),
                  periodDays: p['periodDays'] is int
                      ? p['periodDays'] as int
                      : int.tryParse('${p['periodDays'] ?? 30}') ?? 30,
                  features: _featuresFor(id),
                  isPopular: id == 'pro',
                  color: _colorFor(id),
                  isSelected: _selectedPlanId == id,
                  onSelect: () => setState(() => _selectedPlanId = id),
                );
              }),
            const SizedBox(height: 16),
            CustomButton(
              label:
                  'Pay (Rs. ${_amountForSelected()}/mo) — $_provider',
              onPressed: _loadingPlans ? null : () => _onPayNow(context, biz),
              icon: Icons.lock_outline,
            ),
            if (!OfflineMode.enabled) ...[
              const SizedBox(height: 8),
              Text(
                'Payment secure gateway par open hoga (JazzCash / Telenor). '
                'Return ke baad yahan "Refresh" dabayein agar plan update na ho.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction list server se jald — abhi yahan sirf aapka current plan dikh raha hai.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  int _amountForSelected() {
    final p = _plans.firstWhere(
      (e) => e['id']?.toString() == _selectedPlanId,
      orElse: () => _plans.isNotEmpty ? _plans.first : {},
    );
    return _amountPkr(p);
  }

  Widget _offlineBanner() {
    return Card(
      color: AppColors.info.withValues(alpha: 0.12),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'App OFFLINE mode mein hai. Subscription ke liye '
          '`flutter run --dart-define=OFFLINE_MODE=false` + API URL set karein.',
          style: TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(msg, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildCurrentPlanBanner(BusinessProvider biz) {
    final ex = biz.subscriptionExpiresAt;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.currentPlan,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  _planLabel(biz.subscriptionPlan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ex != null
                      ? 'Renew / valid: ${DateFormat('MMM d, y').format(ex)}'
                      : 'No expiry on device (server sync karein)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _planLabel(String id) {
    switch (id) {
      case 'free':
        return 'Free';
      case 'starter':
        return 'Starter';
      case 'pro':
        return 'Pro';
      case 'business':
        return 'Business';
      default:
        return id.isEmpty ? '—' : id;
    }
  }

  Color _colorFor(String id) {
    switch (id) {
      case 'starter':
        return AppColors.info;
      case 'pro':
        return AppColors.primary;
      case 'business':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  List<String> _featuresFor(String planId) {
    switch (planId) {
      case 'starter':
        return const [
          'Ziyada products list',
          'Basic support',
        ];
      case 'pro':
        return const [
          'Riders + advanced tools',
          'Priority help',
        ];
      case 'business':
        return const [
          'Full suite',
          'Ziyada growth options',
        ];
      default:
        return const [];
    }
  }

  Future<void> _onPayNow(BuildContext context, BusinessProvider biz) async {
    if (OfflineMode.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pehle OFFLINE_MODE=false + backend URL set karein, phir payment chalega.',
          ),
        ),
      );
      return;
    }
    var bid = biz.remoteBusinessMongoId;
    if (bid == null || bid.isEmpty) {
      await biz.ensureRemoteBusinessExists();
      await biz.syncRemoteBusinessWithApi();
      bid = biz.remoteBusinessMongoId;
    }
    if (bid == null || bid.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pehle business profile / setup complete karein (Mongo business id)'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 16),
                Text('Server se checkout…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final res = await SubscriptionApi.checkout(
        businessId: bid,
        planId: _selectedPlanId,
        provider: _provider,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      if (res['mock'] == true) {
        await biz.updateSubscription(_selectedPlanId);
        await biz.syncSubscriptionFromApi();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock: plan activate (PAYMENTS_MOCK_SUCCESS)'),
            backgroundColor: AppColors.success,
          ),
        );
        return;
      }

      if (_provider == 'jazzcash') {
        final jazz = res['jazzcash'];
        if (jazz is! Map) {
          _showErr(context, 'JazzCash response sahi nahi aaya');
          return;
        }
        final jazzMap = Map<String, dynamic>.from(jazz);
        final data = jazzMap['response'];
        final url = firstHttpUrlInJson(data) ??
            firstHttpUrlInJson(jazzMap['responseRaw']) ??
            firstHttpUrlInJson(res);
        if (url == null) {
          await _showJazzNoUrlSheet(context, data, jazzMap);
          return;
        }
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              initialUrl: Uri.parse(url),
              title: 'JazzCash',
            ),
          ),
        );
        if (!context.mounted) return;
        await biz.syncSubscriptionFromApi();
        return;
      }

      if (_provider == 'easypaisa') {
        final ep = res['easypaisa'];
        if (ep is! Map) {
          _showErr(context, 'EasyPaisa response nahi aaya');
          return;
        }
        final epMap = Map<String, dynamic>.from(ep);
        final postUrl = epMap['postUrl']?.toString() ?? '';
        final fields = epMap['fields'];
        if (postUrl.isEmpty || fields is! Map) {
          _showErr(context, 'postUrl/fields missing');
          return;
        }
        final f = Map<String, dynamic>.from(fields);
        final html = buildEasypaisaFormHtml(postUrl, f);
        final base = _originOnly(postUrl);
        if (!context.mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              html: html,
              baseUrl: base,
              title: 'EasyPaisa',
            ),
          ),
        );
        if (!context.mounted) return;
        await biz.syncSubscriptionFromApi();
        return;
      }

      _showErr(context, 'Unknown checkout response');
    } catch (e) {
      if (context.mounted) {
        final nav = Navigator.of(context);
        if (nav.canPop()) nav.pop();
      }
      if (!context.mounted) return;
      final msg = e is ApiException
          ? e.message
          : (e is DioException ? ApiClient.messageFromDio(e) : e.toString());
      _showErr(context, msg);
    }
  }

  void _showErr(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _originOnly(String postUrl) {
    try {
      final u = Uri.parse(postUrl);
      return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}/';
    } catch (_) {
      return 'https://easypaisa.com.pk/';
    }
  }

  Future<void> _showJazzNoUrlSheet(
    BuildContext context,
    Object? data,
    Map<String, dynamic> jazz,
  ) async {
    final raw = jazz['responseRaw']?.toString() ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(c).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'JazzCash ne URL wapas nahi bheja (sandbox / response alag format).'
                ' Neeche raw response dekhain — `pp_ResponseCode` check karein ya Jazz portal help.',
              ),
              const SizedBox(height: 12),
              SelectableText(
                (data?.toString() ?? '') + (raw.isNotEmpty ? '\n$raw' : ''),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.planId,
    required this.label,
    required this.pricePkr,
    required this.periodDays,
    required this.features,
    required this.isPopular,
    required this.color,
    required this.isSelected,
    required this.onSelect,
  });

  final String planId;
  final String label;
  final int pricePkr;
  final int periodDays;
  final List<String> features;
  final bool isPopular;
  final Color color;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey(planId),
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          if (isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Rs. $pricePkr / $periodDays days',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: features
                  .map(
                    (f) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          f,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
