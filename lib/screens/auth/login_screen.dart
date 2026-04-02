import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/async_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import 'login/auth_header_section.dart';
import 'login/login_constants.dart';
import 'login/login_form.dart';
import 'login/signup_form.dart';

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

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _signupEmailCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _loginPhoneCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _workerNicCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _workerImage;
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

  Future<void> _login() async {
    if (_loginFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthProvider>();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      bool success;
      if (_loginUserType == UserType.customer) {
        success = await AsyncGuard.withTimeout(
          auth.loginWithPhone(_loginPhoneCtrl.text),
        );
      } else if (_loginUserType == UserType.serviceWorker) {
        final role = _loginServiceBranch == ServiceBranch.rider
            ? UserType.rider
            : UserType.serviceWorker;
        success = await AsyncGuard.withTimeout(
          auth.loginWithPhone(_loginPhoneCtrl.text, phoneRole: role),
        );
      } else {
        success = await AsyncGuard.withTimeout(
          auth.login(_emailCtrl.text, _passwordCtrl.text),
        );
      }

      if (!mounted) return;
      if (success) {
        if (_loginUserType == UserType.customer) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else if (_loginUserType == UserType.serviceWorker) {
          if (!mounted) return;
          if (_loginServiceBranch == ServiceBranch.rider) {
            Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
          } else {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.serviceWorkerHome,
            );
          }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid credentials. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AsyncGuard.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add profile image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (isRider) {
      if (_riderLicenseImage == null || _riderNicImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Driving license aur CNIC dono ki clear photo upload karein.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!_riderAgreeMinWallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Neeche diye gaye box par tick karein: Rs 5,000 ka wada.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_riderLicenseCtrl.text.trim().length < 4 ||
          _riderNicCtrl.text.trim().length < 13 ||
          _riderBikeCtrl.text.trim().length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('License, CNIC aur bike number sahi bharein'),
            backgroundColor: AppColors.error,
          ),
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
          isCustomer || isWorker || isRider
              ? ''
              : _signupPasswordCtrl.text,
          userType: isRider ? UserType.rider : _selectedUserType,
        ),
      );
      if (!mounted) return;
      if (success) {
        if (_selectedUserType == UserType.customer) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else if (isRider) {
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
        } else if (isWorker) {
          await auth.setServiceWorkerProfile(
            profession: _selectedProfession,
            nic: _workerNicCtrl.text.trim(),
            imagePath: _workerImage!.path,
            plan: _selectedWorkerPlan,
          );
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.serviceWorkerHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.businessSelection);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AsyncGuard.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      debugPrint('ImagePicker worker: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Photo select nahi ho saki. Settings → App → Photos / Files permission check karein.\n(${e.toString()})',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
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
      debugPrint('ImagePicker rider doc: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gallery nahi khuli. App ko Photos / Storage ki permission dein, phir dubara try karein.\n(${e.toString()})',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
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
                  padding: const EdgeInsets.fromLTRB(24, 44, 24, 40),
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return LoginForm(
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
                        );
                      }
                      return SignupForm(
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
                        onPickRiderLicenseImage: () =>
                            _pickRiderDocImage(setLicense: true),
                        onPickRiderNicImage: () =>
                            _pickRiderDocImage(setLicense: false),
                        onSignUp: _signUp,
                        isSubmitting: _isSubmitting,
                        onSwitchToLogin: () {
                          _tabController.animateTo(0);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
