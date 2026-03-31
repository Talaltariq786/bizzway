import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/async_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

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
  String _selectedProfession = 'Electrician';
  String _selectedWorkerPlan = 'monthly';
  static const List<String> _workerProfessions = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Mechanic',
    'AC Technician',
  ];
  static const List<_WorkerPlanInfo> _workerPlans = [
    _WorkerPlanInfo(
      id: 'monthly',
      title: 'Monthly',
      price: 750,
      subtitle: 'Rs 750 / month',
      saveText: 'Standard',
    ),
    _WorkerPlanInfo(
      id: 'six_months',
      title: '6 Months',
      price: 4050,
      subtitle: 'Rs 4,050 / 6 months',
      saveText: 'Save Rs 450',
    ),
    _WorkerPlanInfo(
      id: 'yearly',
      title: 'Yearly',
      price: 7200,
      subtitle: 'Rs 7,200 / year',
      saveText: 'Save Rs 1,800',
    ),
  ];
  UserType _selectedUserType = UserType.customer;
  UserType _loginUserType = UserType.customer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginFormKey.currentState?.validate() != true) return;
    final auth = context.read<AuthProvider>();

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      bool success;
      if (_loginUserType == UserType.customer ||
          _loginUserType == UserType.serviceWorker) {
        success = await AsyncGuard.withTimeout(
          auth.loginWithPhone(_loginPhoneCtrl.text),
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
          await auth.setUserType(UserType.serviceWorker);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, AppRoutes.serviceWorkerHome);
        } else {
          await auth.setUserType(UserType.businessOwner);
          if (!mounted) return;
          final business = context.read<BusinessProvider>();
          await AsyncGuard.withTimeout(business.loadBusiness());
          if (!mounted) return;
          if (business.selectedBusiness == null) {
            Navigator.pushReplacementNamed(context, AppRoutes.businessSelection);
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
    final isWorker = _selectedUserType == UserType.serviceWorker;
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
    setState(() => _isSubmitting = true);
    try {
      final success = await AsyncGuard.withTimeout(
        auth.signUp(
          isCustomer || _selectedUserType == UserType.serviceWorker
              ? _phoneCtrl.text
              : _signupEmailCtrl.text,
          isCustomer || _selectedUserType == UserType.serviceWorker
              ? ''
              : _signupPasswordCtrl.text,
          userType: _selectedUserType,
        ),
      );
      if (!mounted) return;
      if (success) {
        if (_selectedUserType == UserType.customer) {
          Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
        } else if (_selectedUserType == UserType.serviceWorker) {
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
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;
    setState(() => _workerImage = file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Gradient header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 28,
              bottom: 32,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppStrings.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── Tab + Forms ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientPrimary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Login'),
                        Tab(text: 'Sign Up'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Forms - no fixed height, let content expand
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return _buildLoginForm();
                      }
                      return _buildSignUpForm();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Login form ────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose who you are to continue',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── User type selector ─────────────────────────────────────────
          Center(
            child: Text(
              'I am a...',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _loginTypeCard(
                type: UserType.businessOwner,
                icon: Icons.store_rounded,
                title: 'Business Owner',
                subtitle: 'Manage your business',
              ),
              const SizedBox(width: 8),
              _loginTypeCard(
                type: UserType.customer,
                icon: Icons.person_rounded,
                title: 'Customer',
                subtitle: 'Book services nearby',
              ),
              const SizedBox(width: 8),
              _loginTypeCard(
                type: UserType.serviceWorker,
                icon: Icons.handyman_rounded,
                title: 'Service',
                subtitle: 'Get nearby jobs',
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loginUserType == UserType.customer ||
              _loginUserType == UserType.serviceWorker) ...[
            CustomTextField(
              label: 'Phone Number',
              hint: '03xx-xxxxxxx',
              controller: _loginPhoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  (v ?? '').trim().length < 10 ? 'Valid phone number daalen' : null,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _loginUserType == UserType.serviceWorker
                    ? 'Phone se service worker login hoga'
                    : 'Sirf number se login hoga',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            CustomTextField(
              label: AppStrings.email,
              hint: 'you@example.com',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.isEmpty ? 'Please enter your email' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: AppStrings.password,
              hint: '••••••••',
              controller: _passwordCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  v!.length < 6 ? 'Min 6 characters required' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(AppStrings.forgotPassword),
              ),
            ),
          ],
          Consumer<AuthProvider>(
            builder: (context, auth, _) => CustomButton(
              label: AppStrings.login,
              onPressed: _login,
              isLoading: auth.isLoading || _isSubmitting,
              icon: Icons.login_rounded,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AppStrings.orContinueWith,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(1);
                setState(() {});
              },
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sign Up form ──────────────────────────────────────────────────────────

  Widget _buildSignUpForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose your account type to get started',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── User type selector ─────────────────────────────────────────
          Center(
            child: Text(
              'I am a...',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _userTypeCard(
                type: UserType.businessOwner,
                icon: Icons.store_rounded,
                title: 'Business Owner',
                subtitle: 'Manage your business',
              ),
              const SizedBox(width: 8),
              _userTypeCard(
                type: UserType.customer,
                icon: Icons.person_rounded,
                title: 'Customer',
                subtitle: 'Book services nearby',
              ),
              const SizedBox(width: 8),
              _userTypeCard(
                type: UserType.serviceWorker,
                icon: Icons.handyman_rounded,
                title: 'Service',
                subtitle: 'Get nearby jobs',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Fields ─────────────────────────────────────────────────────
          CustomTextField(
            label: 'Full Name',
            hint: 'Your name',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 14),

          if (_selectedUserType == UserType.customer) ...[
            // Customer: phone + area only
            CustomTextField(
              label: 'Phone Number',
              hint: '03xx-xxxxxxx',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  v!.isEmpty ? 'Please enter your phone number' : null,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Area / Location',
              hint: 'e.g. Gulshan-e-Iqbal, Karachi',
              controller: _areaCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'Please enter your area' : null,
            ),
          ] else ...[
            if (_selectedUserType == UserType.serviceWorker) ...[
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickWorkerImage,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        image: _workerImage == null
                            ? null
                            : DecorationImage(
                                image: FileImage(File(_workerImage!.path)),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: _workerImage == null
                          ? const Icon(Icons.camera_alt_rounded,
                              color: AppColors.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _workerImage == null
                          ? 'Add profile photo'
                          : 'Photo selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Phone Number',
                hint: '03xx-xxxxxxx',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'CNIC Number',
                hint: 'xxxxx-xxxxxxx-x',
                controller: _workerNicCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter CNIC number' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedProfession,
                items: _workerProfessions
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedProfession = v);
                },
                decoration: InputDecoration(
                  labelText: 'Profession',
                  prefixIcon: const Icon(Icons.handyman_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Subscription Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ..._workerPlans.map((p) {
                final selected = _selectedWorkerPlan == p.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedWorkerPlan = p.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: selected ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                p.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          p.saveText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              // Business Owner: email + password
              CustomTextField(
                label: AppStrings.email,
                hint: 'you@example.com',
                controller: _signupEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: AppStrings.password,
                hint: 'Min 6 characters',
                controller: _signupPasswordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    v!.length < 6 ? 'Min 6 characters required' : null,
              ),
            ],
          ],
          const SizedBox(height: 20),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => CustomButton(
              label: AppStrings.signUp,
              onPressed: _signUp,
              isLoading: auth.isLoading || _isSubmitting,
              icon: Icons.person_add_outlined,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
                setState(() {});
              },
              child: RichText(
                text: const TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginTypeCard({
    required UserType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _loginUserType == type;
    return Expanded(
      child: SizedBox(
        height: 150,
        child: GestureDetector(
          onTap: () => setState(() => _loginUserType = type),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          color:
                              isSelected ? Colors.white : AppColors.primary,
                          size: 22),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 12),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _userTypeCard({
    required UserType type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedUserType == type;
    return Expanded(
      child: SizedBox(
        height: 150,
        child: GestureDetector(
          onTap: () => setState(() => _selectedUserType = type),
          child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: AppColors.gradientPrimary,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon,
                          color: isSelected ? Colors.white : AppColors.primary,
                          size: 22),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: AppColors.primary, size: 12),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.82)
                      : AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

}

class _WorkerPlanInfo {
  final String id;
  final String title;
  final int price;
  final String subtitle;
  final String saveText;

  const _WorkerPlanInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.saveText,
  });
}
