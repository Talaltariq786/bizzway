import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/service_providers_api.dart';
import '../../core/config/api_config.dart';
import '../../core/config/offline_mode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/async_guard.dart';
import '../../core/maps/map_location_picker_screen.dart';
import '../../core/maps/map_location_result.dart';
import '../../core/utils/dev_log.dart';
import '../../core/demo/investor_demo_walkthrough.dart';
import '../../core/demo/demo_voice.dart';
import '../../core/demo/presenter_mode.dart';
import '../../core/widgets/app_loading_dim.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/service_provider_directory_provider.dart';
import '../../models/service_provider_profile.dart';
import 'login/auth_header_section.dart';
import 'login/login_constants.dart';
import 'login/login_form.dart';
import 'login/signup_form.dart';

/// Starter rate lines when a worker signs up as kabari/scrap buyer (editable later via profile).
Map<String, String> _scrapRateCardDemoForProfession(String profession) {
  final p = profession.toLowerCase();
  if (!p.contains('kabari') &&
      !p.contains('scrap') &&
      !p.contains('kabadi')) {
    return {};
  }
  return {
    'Plastic (PET / bottles)': 'Rs 80 – 95 / kg',
    'Paper / cardboard': 'Rs 28 – 35 / kg',
    'Iron / steel scrap': 'Rs 85 – 110 / kg',
    'Aluminium': 'Rs 260 – 300 / kg',
    'Bossi / mixed kabar': 'Rs 40 – 55 / kg',
    'Glass bottles': 'Rs 8 – 14 / kg',
  };
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _demoRunning = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _loginPhoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  double? _signupLat;
  double? _signupLng;
  final _workerNicCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _workerImage;
  XFile? _workerNicFrontImage;
  XFile? _workerNicBackImage;
  XFile? _riderLicenseImage;
  XFile? _riderNicImage;
  String _selectedProfession = 'Electrician';
  String _selectedWorkerPlan = 'monthly';

  ServiceBranch _loginServiceBranch = ServiceBranch.home;
  ServiceBranch _signupServiceBranch = ServiceBranch.home;

  final _riderLicenseCtrl = TextEditingController();
  final _riderNicCtrl = TextEditingController();
  final _riderBikeCtrl = TextEditingController();
  String _selectedRiderPlan = 'rider_monthly';
  bool _riderAgreeMinWallet = false;

  UserType _selectedUserType = UserType.customer;
  UserType _loginUserType = UserType.businessOwner;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _loginPhoneCtrl.dispose();
    _areaCtrl.dispose();
    _workerNicCtrl.dispose();
    _riderLicenseCtrl.dispose();
    _riderNicCtrl.dispose();
    _riderBikeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWorkerNicImage({required bool front}) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 82,
      );
      if (file == null || !mounted) return;
      setState(() {
        if (front) {
          _workerNicFrontImage = file;
        } else {
          _workerNicBackImage = file;
        }
      });
    } catch (e, st) {
      devLog('ImagePicker worker NIC', e, st);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gallery nahi khuli. Photos / Storage permission dein, phir dubara try karein.',
        kind: AppSnackKind.error,
        detail: e.toString(),
        duration: const Duration(seconds: 6),
      );
    }
  }

  Widget _presenterDemoTrackCard({
    required BuildContext sheetContext,
    required DemoTrack track,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> accent,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(sheetContext, track),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: accent,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accent.first.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runInvestorDemo() async {
    if (_demoRunning || _isSubmitting) return;
    setState(() => _demoRunning = true);
    try {
      // Default: enable voice for a more professional investor demo.
      // Presenter can turn it off from the sheet before starting.
      DemoVoice.enabled = true;
      // If user tapped "Demo", auto-enable Presenter Mode so options are visible.
      // Keeps the UI clean for normal users while remaining zero-friction for demos.
      if (!PresenterMode.enabled) {
        await PresenterMode.setEnabled(true);
        if (!mounted) return;
        setState(() {});
      }
      final track = await showModalBottomSheet<DemoTrack>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Material(
              elevation: 28,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientPrimary,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.slideshow_rounded,
                              color: Colors.white.withValues(alpha: 0.95),
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onLongPress: () async {
                                  // Hidden toggle: keeps production UX clean.
                                  await PresenterMode.setEnabled(!PresenterMode.enabled);
                                  if (mounted) setState(() {});
                                },
                                child: const Text(
                                  'Guided product tour',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.35,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Replay anytime — short captions, optional voice. '
                          'Quick (~2–3 min) or Complete (~10–14 min): merchant → customer → team rider → services → revenue.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!PresenterMode.enabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                            ),
                            child: const Text(
                              'Demo is hidden (Presenter mode is OFF).\n'
                              'Long‑press “Guided product tour” title to enable it.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.35,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        StatefulBuilder(
                          builder: (ctx2, setSheetState) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.record_voice_over_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Demo voiceover (TTS)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: DemoVoice.enabled,
                                  onChanged: (v) async {
                                    setSheetState(() => DemoVoice.enabled = v);
                                    if (!v) await DemoVoice.stop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (PresenterMode.enabled)
                          _presenterDemoTrackCard(
                            sheetContext: ctx,
                            track: DemoTrack.complete,
                            icon: Icons.auto_awesome_rounded,
                            title: 'Master demo (full story)',
                            subtitle:
                                '10–15 minutes. Runs the whole system end-to-end, then explains revenue and the 12‑month plan.',
                            accent: const [
                              Color(0xFF1E88E5),
                              Color(0xFF8E24AA),
                            ],
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Not now',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!mounted) return;
      if (track == null) return;

      await InvestorDemoWalkthrough.run(
        context,
        demo: LoginDemoControls(
          syncAuthTab: (tabIndex) {
            if (!mounted) return;
            _tabController.animateTo(tabIndex);
            setState(() {});
          },
          shellSetState: setState,
          isMounted: () => mounted,
          emailCtrl: _emailCtrl,
          passwordCtrl: _passwordCtrl,
          loginPhoneCtrl: _loginPhoneCtrl,
          nameCtrl: _nameCtrl,
          phoneCtrl: _phoneCtrl,
          signupEmailCtrl: _signupEmailCtrl,
          signupPasswordCtrl: _signupPasswordCtrl,
          areaCtrl: _areaCtrl,
          setLoginUserType: (t) => setState(() => _loginUserType = t),
          setLoginServiceBranch: (b) => setState(() => _loginServiceBranch = b),
          setSignupUserType: (t) => setState(() => _selectedUserType = t),
          setSignupServiceBranch: (b) =>
              setState(() => _signupServiceBranch = b),
        ),
        track: track,
      );
    } finally {
      if (mounted) setState(() => _demoRunning = false);
    }
  }

  Future<void> _login() async {
    if (_loginFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthProvider>();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      bool success;
      if (_loginUserType == UserType.customer) {
        success = await AsyncGuard.withTimeout(
          auth.loginWithPhone(
            _loginPhoneCtrl.text,
            password: _passwordCtrl.text,
          ),
        );
      } else if (_loginUserType == UserType.serviceWorker) {
        success = await AsyncGuard.withTimeout(
          auth.loginWithPhone(
            _loginPhoneCtrl.text,
            password: _passwordCtrl.text,
          ),
        );
      } else {
        success = await AsyncGuard.withTimeout(
          auth.login(_emailCtrl.text, _passwordCtrl.text),
        );
      }

      if (!mounted) return;
      if (success) {
        await context.read<AuthProvider>().persistLoginTabIntent(
          loginTab: _loginUserType,
          serviceBranchHome: _loginServiceBranch == ServiceBranch.home,
        );
        if (!mounted) return;
        final u = context.read<AuthProvider>();
        if (u.userType == UserType.customer) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else if (u.userType == UserType.serviceWorker) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.serviceWorkerHome,
          );
        } else if (u.userType == UserType.rider) {
          Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
        } else {
          if (!mounted) return;
          final business = context.read<BusinessProvider>();
          await AsyncGuard.withTimeout(business.loadBusiness());
          if (!mounted) return;
          if (business.selectedBusiness == null) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.businessSelection,
            );
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          }
        }
      } else {
        showAppSnackBar(
          context,
          'Email/phone ya password check karein (min 6 characters).',
          kind: AppSnackKind.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signUp() async {
    if (_signupFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthProvider>();
    final isCustomer = _selectedUserType == UserType.customer;
    final isWorker = _selectedUserType == UserType.serviceWorker &&
        _signupServiceBranch == ServiceBranch.home;
    final isRider = _selectedUserType == UserType.serviceWorker &&
        _signupServiceBranch == ServiceBranch.rider;
    if (_isSubmitting) return;
    if (isWorker && _workerImage == null) {
      showAppSnackBar(
        context,
        'Please add profile image',
        kind: AppSnackKind.warning,
      );
      return;
    }
    if (isWorker && (_workerNicFrontImage == null || _workerNicBackImage == null)) {
      showAppSnackBar(
        context,
        'CNIC front aur back dono ki clear photo upload karein.',
        kind: AppSnackKind.warning,
      );
      return;
    }
    if (isRider) {
      if (_riderLicenseImage == null || _riderNicImage == null) {
        showAppSnackBar(
          context,
          'Driving license aur CNIC dono ki clear photo upload karein.',
          kind: AppSnackKind.warning,
        );
        return;
      }
      if (!_riderAgreeMinWallet) {
        showAppSnackBar(
          context,
          'Neeche diye gaye box par tick karein: Rs 5,000 ka wada.',
          kind: AppSnackKind.warning,
        );
        return;
      }
      if (_riderLicenseCtrl.text.trim().length < 4 ||
          _riderNicCtrl.text.trim().length < 13 ||
          _riderBikeCtrl.text.trim().length < 2) {
        showAppSnackBar(
          context,
          'License, CNIC aur bike number sahi bharein',
          kind: AppSnackKind.warning,
        );
        return;
      }
    }
    setState(() => _isSubmitting = true);
    try {
      final success = await AsyncGuard.withTimeout(
        auth.signUp(
          isCustomer || isWorker || isRider
              ? _phoneCtrl.text
              : _signupEmailCtrl.text,
          _signupPasswordCtrl.text,
          userType: isRider ? UserType.rider : _selectedUserType,
          name: _nameCtrl.text,
        ),
      );
      if (!mounted) return;
      if (success) {
        await auth.persistLoginTabIntent(
          loginTab: _selectedUserType,
          serviceBranchHome: !isRider && _signupServiceBranch == ServiceBranch.home,
        );
        if (!mounted) return;
        final u = context.read<AuthProvider>();
        if (u.userType == UserType.customer) {
          await context.read<LocationProvider>().applyCustomerSignupAddress(
            address: _areaCtrl.text.trim(),
            lat: _signupLat,
            lng: _signupLng,
          );
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else if (u.userType == UserType.rider) {
          await auth.setRiderProfile(
            licenseNo: _riderLicenseCtrl.text.trim(),
            nic: _riderNicCtrl.text.trim(),
            bikeNumber: _riderBikeCtrl.text.trim(),
            walletAmount: 5000,
            planId: _selectedRiderPlan,
            licenseImagePath: _riderLicenseImage!.path,
            nicImagePath: _riderNicImage!.path,
          );
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
        } else if (u.userType == UserType.serviceWorker) {
          await auth.setServiceWorkerProfile(
            profession: _selectedProfession,
            nic: _workerNicCtrl.text.trim(),
            imagePath: _workerImage!.path,
            nicFrontImagePath: _workerNicFrontImage!.path,
            nicBackImagePath: _workerNicBackImage!.path,
            plan: _selectedWorkerPlan,
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'active_provider_id',
            u.userEmail?.trim().isNotEmpty == true
                ? u.userEmail!.trim()
                : _phoneCtrl.text.trim(),
          );
          if (!mounted) return;
          final loc = context.read<LocationProvider>();
          final baseLat = loc.selectedAddress.lat ?? 24.8607;
          final baseLng = loc.selectedAddress.lng ?? 67.0011;
          // Small deterministic jitter so multiple providers don't overlap exactly.
          final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
          final seed = digits.isEmpty ? 7 : digits.codeUnits.fold<int>(0, (a, c) => a + c);
          final jLat = ((seed % 17) - 8) * 0.0012; // ~0.1 km
          final jLng = (((seed ~/ 3) % 17) - 8) * 0.0012;
          // Add/Update in local directory so customers can see providers in Near Me.
          if (!mounted) return;
          context.read<ServiceProviderDirectoryProvider>().upsert(
                ServiceProviderProfile(
                  id: _phoneCtrl.text.trim(),
                  name: _nameCtrl.text.trim().isEmpty
                      ? 'Service Provider'
                      : _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  profession: _selectedProfession,
                  nic: _workerNicCtrl.text.trim(),
                  imagePath: _workerImage?.path,
                  plan: _selectedWorkerPlan,
                  isOnline: true,
                  lat: baseLat + jLat,
                  lng: baseLng + jLng,
                  updatedAt: DateTime.now(),
                  createdAt: DateTime.now(),
                  scrapRatesDisplay:
                      _scrapRateCardDemoForProfession(_selectedProfession),
                ),
              );
          if (!mounted) return;
          if (!OfflineMode.enabled) {
            try {
              final nicRaw = _workerNicCtrl.text.trim();
              await ServiceProvidersApi(ApiClient()).putMe(
                profession: _selectedProfession,
                nic: nicRaw.length >= 5 ? nicRaw : null,
                planId: _selectedWorkerPlan,
                scrapRatesDisplay:
                    _scrapRateCardDemoForProfession(_selectedProfession),
              );
            } catch (e, st) {
              devLog('service provider PUT after signup', e, st);
            }
          }
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.serviceWorkerHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.businessSelection);
        }
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickSignupLocation() async {
    final loc = context.read<LocationProvider>();
    final a = loc.selectedAddress;
    try {
      final r = await Navigator.of(context).push<MapLocationResult>(
        MaterialPageRoute<MapLocationResult>(
          fullscreenDialog: true,
          builder: (_) => MapLocationPickerScreen(
            initialLat: _signupLat ?? a.lat ?? 24.8607,
            initialLng: _signupLng ?? a.lng ?? 67.0011,
            title: 'Delivery location',
          ),
        ),
      );
      if (r == null || !mounted) return;
      setState(() {
        _signupLat = r.lat;
        _signupLng = r.lng;
        _areaCtrl.text = r.addressLine;
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    }
  }

  Future<void> _pickWorkerImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 75,
      );
      if (file == null || !mounted) return;
      setState(() => _workerImage = file);
    } catch (e, st) {
      devLog('ImagePicker worker', e, st);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Photo select nahi ho saki. Settings → App → Photos permission check karein.',
        kind: AppSnackKind.error,
        detail: e.toString(),
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _pickRiderDocImage({required bool setLicense}) async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 82,
      );
      if (file == null || !mounted) return;
      setState(() {
        if (setLicense) {
          _riderLicenseImage = file;
        } else {
          _riderNicImage = file;
        }
      });
    } catch (e, st) {
      devLog('ImagePicker rider doc', e, st);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gallery nahi khuli. Photos / Storage permission dein, phir dubara try karein.',
        kind: AppSnackKind.error,
        detail: e.toString(),
        duration: const Duration(seconds: 6),
      );
    }
  }

  Future<void> _showDevApiDialog() async {
    final ctrl = TextEditingController(text: ApiConfig.baseUrl);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend API URL'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Phone par 127.0.0.1 kaam nahi karega. Mac ka Wi‑Fi IP likhein, '
                'e.g. http://192.168.1.10:8080',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://192.168.1.10:8080',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ApiConfig.clearDevBaseUrl();
              ApiClient.resetShared();
              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {});
              showAppSnackBar(
                context,
                'Default URL use ho rahi hai',
                kind: AppSnackKind.info,
              );
            },
            child: const Text('Default'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ApiConfig.setDevBaseUrl(ctrl.text);
                ApiClient.resetShared();
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                setState(() {});
                showAppSnackBar(
                  context,
                  'API URL save ho gayi',
                  kind: AppSnackKind.success,
                );
              } catch (e) {
                if (!mounted) return;
                showAppSnackBar(
                  context,
                  e is ArgumentError ? e.message.toString() : '$e',
                  kind: AppSnackKind.error,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Widget _devApiUrlBar() {
    final warn = ApiConfig.shouldPromptForLanHost;
    final label = ApiConfig.devBaseUrlDisplay.isNotEmpty
        ? ApiConfig.devBaseUrlDisplay
        : ApiConfig.baseUrl;
    return Material(
      color: warn ? const Color(0xFFFFF3E0) : AppColors.backgroundLight,
      child: InkWell(
        onTap: _showDevApiDialog,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (warn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Real device: yahan Mac/PC ka Wi‑Fi IP lagao (127.0.0.1 nahi)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 16,
                    color: warn ? const Color(0xFFE65100) : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API: $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: warn ? const Color(0xFFBF360C) : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final authBusy = context.watch<AuthProvider>().isLoading;
    final overlayBusy = _isSubmitting || authBusy;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
        children: [
          AuthHeaderSection(
            tabController: _tabController,
            topPadding: topPad,
          ),
          Expanded(
            child: ClipRect(
              child: ColoredBox(
                color: AppColors.backgroundLight,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final isLogin = _tabController.index == 0;
                      final child = isLogin
                          ? LoginForm(
                              key: const ValueKey('loginForm'),
                              formKey: _loginFormKey,
                              emailCtrl: _emailCtrl,
                              passwordCtrl: _passwordCtrl,
                              loginPhoneCtrl: _loginPhoneCtrl,
                              loginUserType: _loginUserType,
                              onLoginUserTypeChanged: (t) =>
                                  setState(() => _loginUserType = t),
                              loginServiceBranch: _loginServiceBranch,
                              onLoginServiceBranchChanged: (b) =>
                                  setState(() => _loginServiceBranch = b),
                              onLogin: _login,
                              isSubmitting: _isSubmitting,
                              onSwitchToSignUp: () {
                                _tabController.animateTo(1);
                                setState(() {});
                              },
                              onInvestorDemo: _runInvestorDemo,
                              demoRunning: _demoRunning,
                            )
                          : SignupForm(
                              key: const ValueKey('signupForm'),
                              formKey: _signupFormKey,
                              nameCtrl: _nameCtrl,
                              phoneCtrl: _phoneCtrl,
                              areaCtrl: _areaCtrl,
                              signupEmailCtrl: _signupEmailCtrl,
                              signupPasswordCtrl: _signupPasswordCtrl,
                              workerNicCtrl: _workerNicCtrl,
                              riderLicenseCtrl: _riderLicenseCtrl,
                              riderNicCtrl: _riderNicCtrl,
                              riderBikeCtrl: _riderBikeCtrl,
                              workerImage: _workerImage,
                              workerNicFrontImage: _workerNicFrontImage,
                              workerNicBackImage: _workerNicBackImage,
                              riderLicenseImage: _riderLicenseImage,
                              riderNicImage: _riderNicImage,
                              selectedUserType: _selectedUserType,
                              onUserTypeChanged: (t) =>
                                  setState(() => _selectedUserType = t),
                              signupServiceBranch: _signupServiceBranch,
                              onSignupServiceBranchChanged: (b) =>
                                  setState(() => _signupServiceBranch = b),
                              selectedProfession: _selectedProfession,
                              onProfessionChanged: (v) =>
                                  setState(() => _selectedProfession = v),
                              selectedWorkerPlan: _selectedWorkerPlan,
                              onWorkerPlanChanged: (v) =>
                                  setState(() => _selectedWorkerPlan = v),
                              selectedRiderPlan: _selectedRiderPlan,
                              onRiderPlanChanged: (v) =>
                                  setState(() => _selectedRiderPlan = v),
                              riderAgreeMinWallet: _riderAgreeMinWallet,
                              onRiderAgreeToggle: () => setState(
                                () => _riderAgreeMinWallet = !_riderAgreeMinWallet,
                              ),
                              onRiderAgreeCheckbox: (v) => setState(
                                () => _riderAgreeMinWallet = v ?? false,
                              ),
                              onPickWorkerImage: _pickWorkerImage,
                              onPickWorkerNicFrontImage: () =>
                                  _pickWorkerNicImage(front: true),
                              onPickWorkerNicBackImage: () =>
                                  _pickWorkerNicImage(front: false),
                              onPickRiderLicenseImage: () =>
                                  _pickRiderDocImage(setLicense: true),
                              onPickRiderNicImage: () =>
                                  _pickRiderDocImage(setLicense: false),
                              onPickMapLocation: _selectedUserType == UserType.customer
                                  ? _pickSignupLocation
                                  : null,
                              mapLocationSet:
                                  _signupLat != null && _signupLng != null,
                              onSignUp: _signUp,
                              isSubmitting: _isSubmitting,
                              onSwitchToLogin: () {
                                _tabController.animateTo(0);
                                setState(() {});
                              },
                            );

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          final fade = CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOut,
                          );
                          final slide = Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(position: slide, child: child),
                          );
                        },
                        child: child,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (!kReleaseMode || ApiConfig.shouldPromptForLanHost) _devApiUrlBar(),
        ],
          ),
          Positioned.fill(
            child: AppLoadingDim(
              visible: overlayBusy,
              message: overlayBusy
                  ? (_tabController.index == 1
                      ? 'Account setup ho raha hai…'
                      : 'Sign in ho raha hai…')
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
