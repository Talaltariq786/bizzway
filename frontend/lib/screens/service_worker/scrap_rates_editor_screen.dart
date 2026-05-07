import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/service_providers_api.dart';
import '../../core/config/offline_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../models/service_provider_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider_directory_provider.dart';
import '../auth/login/login_constants.dart';

/// Kabariwala sets PKR rates — **local cache + backend** (`PUT /api/service-providers/me`)
/// so Near Me customers get the same lines from the server on AWS.
class ScrapRatesEditorScreen extends StatefulWidget {
  const ScrapRatesEditorScreen({super.key});

  @override
  State<ScrapRatesEditorScreen> createState() => _ScrapRatesEditorScreenState();
}

class _ScrapRatesEditorScreenState extends State<ScrapRatesEditorScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final List<TextEditingController> _customMaterialCtrls = [];
  final List<TextEditingController> _customRateCtrls = [];

  bool _loading = true;
  ServiceProviderProfile? _profile;

  @override
  void initState() {
    super.initState();
    for (final label in kKabariScrapMaterialRows) {
      _controllers[label] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _customMaterialCtrls) {
      c.dispose();
    }
    for (final c in _customRateCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final dir = context.read<ServiceProviderDirectoryProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final id =
        (prefs.getString('active_provider_id') ?? '').trim().isNotEmpty
            ? prefs.getString('active_provider_id')!.trim()
            : auth.userEmail?.trim() ?? '';
    ServiceProviderProfile? hit;
    try {
      hit = dir.providers.firstWhere((p) => p.id == id);
    } catch (_) {}

    Map<String, String> mergedRates = Map<String, String>.from(hit?.scrapRatesDisplay ?? {});
    if (!OfflineMode.enabled) {
      try {
        final api = ServiceProvidersApi(ApiClient());
        final remote = await api.getMeProvider();
        final sr = remote?['scrapRatesDisplay'];
        if (sr is Map && sr.isNotEmpty) {
          mergedRates = Map<String, String>.from(
            sr.map((k, v) => MapEntry(k.toString(), v.toString())),
          );
        }
      } catch (_) {}
    }

    final fallbackId = id.isNotEmpty ? id : (auth.userEmail?.trim() ?? '');
    final profile = hit != null
        ? ServiceProviderProfile(
            id: hit.id,
            name: hit.name,
            phone: hit.phone,
            profession:
                auth.serviceProfession ?? hit.profession,
            nic: hit.nic,
            imagePath: hit.imagePath,
            plan: hit.plan,
            isOnline: hit.isOnline,
            areaLabel: hit.areaLabel,
            lat: hit.lat,
            lng: hit.lng,
            updatedAt: hit.updatedAt,
            createdAt: hit.createdAt,
            scrapRatesDisplay: mergedRates,
          )
        : ServiceProviderProfile(
            id: fallbackId.isNotEmpty ? fallbackId : 'worker',
            name: 'Service Provider',
            phone: fallbackId.isNotEmpty ? fallbackId : '',
            profession:
                auth.serviceProfession ?? 'Kabariwala · scrap buyer',
            createdAt: DateTime.now(),
            scrapRatesDisplay: mergedRates,
          );

    setState(() {
      _profile = profile;
      _loading = false;
      for (final e in mergedRates.entries) {
        if (_controllers.containsKey(e.key)) {
          _controllers[e.key]!.text = e.value;
        } else {
          final m = TextEditingController(text: e.key);
          final r = TextEditingController(text: e.value);
          _customMaterialCtrls.add(m);
          _customRateCtrls.add(r);
        }
      }
    });
  }

  Future<void> _save() async {
    final dir = context.read<ServiceProviderDirectoryProvider>();
    final profile = _profile;
    if (profile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile load nahi hui — dubara login karke try karein.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final out = <String, String>{};
    for (final label in kKabariScrapMaterialRows) {
      final t = _controllers[label]?.text.trim() ?? '';
      if (t.isNotEmpty) out[label] = t;
    }
    for (var i = 0; i < _customMaterialCtrls.length; i++) {
      final k = _customMaterialCtrls[i].text.trim();
      final v = _customRateCtrls[i].text.trim();
      if (k.isNotEmpty && v.isNotEmpty) out[k] = v;
    }

    dir.upsert(
      ServiceProviderProfile(
        id: profile.id,
        name: profile.name,
        phone: profile.phone,
        profession: profile.profession,
        nic: profile.nic,
        imagePath: profile.imagePath,
        plan: profile.plan,
        isOnline: profile.isOnline,
        areaLabel: profile.areaLabel,
        lat: profile.lat,
        lng: profile.lng,
        updatedAt: DateTime.now(),
        createdAt: profile.createdAt,
        scrapRatesDisplay: out,
      ),
    );

    var serverOk = false;
    if (!OfflineMode.enabled && out.isNotEmpty) {
      try {
        final nic = profile.nic?.trim();
        await ServiceProvidersApi(ApiClient()).putMe(
          profession: profile.profession,
          nic: (nic != null && nic.length >= 5) ? nic : null,
          planId: profile.plan,
          scrapRatesDisplay: out,
        );
        serverOk = true;
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          out.isEmpty
              ? 'Koi rate fill nahi — kam az kam ek line likhein.'
              : serverOk || OfflineMode.enabled
                  ? 'Rates save ho gaye — customer Near Me server se bhi yehi dekhe ga.'
                  : 'Phone par save ho gaye — server tak nahi pohanche (network/API check).',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: out.isEmpty ? AppColors.warning : AppColors.success,
      ),
    );
    if (out.isNotEmpty) Navigator.of(context).maybePop();
  }

  void _addCustomRow() {
    setState(() {
      _customMaterialCtrls.add(TextEditingController());
      _customRateCtrls.add(TextEditingController());
    });
  }

  void _removeCustomRow(int i) {
    setState(() {
      _customMaterialCtrls[i].dispose();
      _customRateCtrls[i].dispose();
      _customMaterialCtrls.removeAt(i);
      _customRateCtrls.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Scrap / kabar rates (PKR)'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jo rates yahan save karen ge, customer Near Me se aap ka card khol kar '
                          'yahi dekhe ga — plastic, paper, iron, bossi waghera. Range ya “Rs X / kg” '
                          'likh sakte hain.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.38,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Standard materials',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...kKabariScrapMaterialRows.map((label) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _controllers[label],
                          decoration: InputDecoration(
                            hintText: 'e.g. Rs 85 / kg ya Rs 80 – 95 / kg',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Custom lines',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addCustomRow,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const Text(
                  'Aur cheezen (roti / steel mix / etc.) — naam + rate',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_customMaterialCtrls.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _customMaterialCtrls[i],
                            decoration: InputDecoration(
                              labelText: 'Material',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _customRateCtrls[i],
                            decoration: InputDecoration(
                              labelText: 'PKR rate',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeCustomRow(i),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save rates — customer ko dikhe ga'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
