import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import 'login_constants.dart';
import 'role_tabs.dart';
import 'service_branch_switcher.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.loginPhoneCtrl,
    required this.loginUserType,
    required this.onLoginUserTypeChanged,
    required this.loginServiceBranch,
    required this.onLoginServiceBranchChanged,
    required this.onLogin,
    required this.isSubmitting,
    required this.onSwitchToSignUp,
    this.onInvestorDemo,
    this.demoRunning = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController loginPhoneCtrl;
  final UserType loginUserType;
  final ValueChanged<UserType> onLoginUserTypeChanged;
  final ServiceBranch loginServiceBranch;
  final ValueChanged<ServiceBranch> onLoginServiceBranchChanged;
  final VoidCallback onLogin;
  final bool isSubmitting;
  final VoidCallback onSwitchToSignUp;
  /// Optional scripted app tour for investors / screen recording.
  final VoidCallback? onInvestorDemo;
  final bool demoRunning;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose who you are to continue',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'I am a...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RoleTabs(
            value: loginUserType,
            onChanged: onLoginUserTypeChanged,
          ),
          if (loginUserType == UserType.serviceWorker) ...[
            const SizedBox(height: 10),
            ServiceBranchSwitcher(
              value: loginServiceBranch,
              onChanged: onLoginServiceBranchChanged,
              riderComingSoon: true,
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 16),
          if (loginUserType == UserType.customer ||
              loginUserType == UserType.serviceWorker) ...[
            CustomTextField(
              label: 'Phone Number',
              hint: '03001234567',
              controller: loginPhoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Valid phone number daalen'
                  : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: AppStrings.password,
              hint: 'Account wala password (min 6)',
              controller: passwordCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  (v ?? '').trim().length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                loginUserType == UserType.serviceWorker
                    ? (loginServiceBranch == ServiceBranch.rider
                        ? 'Rider account — phone + password'
                        : 'Home service — phone + password')
                    : 'Phone se sign up karte waqt jo password diya tha',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            CustomTextField(
              label: AppStrings.email,
              hint: 'aapka@email.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.isEmpty ? 'Please enter your email' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: AppStrings.password,
              hint: 'Kamzori 6 characters',
              controller: passwordCtrl,
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
            builder: (context, auth, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomButton(
                  label: AppStrings.login,
                  onPressed: onLogin,
                  isLoading:
                      auth.isLoading || isSubmitting || demoRunning,
                ),
                if (onInvestorDemo != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: (auth.isLoading ||
                            isSubmitting ||
                            demoRunning)
                        ? null
                        : onInvestorDemo,
                    icon: demoRunning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.slideshow_outlined, size: 20),
                    label: Text(demoRunning ? 'Demo…' : 'Demo'),
                  ),
                ],
              ],
            ),
          ),
          if (loginUserType == UserType.businessOwner) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.riderLogin,
                ),
                child: const Text('Team Rider login (Rider ID)'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  AppStrings.orContinueWith,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: onSwitchToSignUp,
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
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
    );
  }
}
