import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import 'login_constants.dart';
import 'service_branch_switcher.dart';
import 'user_type_cards.dart';

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
          const SizedBox(height: 10),
          Row(
            children: [
              UserTypeToggleCard(
                title: 'Business Owner',
                subtitle: 'Manage your business',
                isSelected: loginUserType == UserType.businessOwner,
                onTap: () => onLoginUserTypeChanged(UserType.businessOwner),
              ),
              const SizedBox(width: 8),
              UserTypeToggleCard(
                title: 'Customer',
                subtitle: 'Book services nearby',
                isSelected: loginUserType == UserType.customer,
                onTap: () => onLoginUserTypeChanged(UserType.customer),
              ),
              const SizedBox(width: 8),
              UserTypeToggleCard(
                title: 'Service',
                subtitle: 'Get nearby jobs',
                isSelected: loginUserType == UserType.serviceWorker,
                onTap: () => onLoginUserTypeChanged(UserType.serviceWorker),
              ),
            ],
          ),
          if (loginUserType == UserType.serviceWorker) ...[
            const SizedBox(height: 12),
            ServiceBranchSwitcher(
              value: loginServiceBranch,
              onChanged: onLoginServiceBranchChanged,
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 20),
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                loginUserType == UserType.serviceWorker
                    ? (loginServiceBranch == ServiceBranch.rider
                        ? 'Rider login — phone se'
                        : 'Home service worker — phone se')
                    : 'Sirf number se login hoga',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            CustomTextField(
              label: AppStrings.email,
              hint: 'aapka@email.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => v!.isEmpty ? 'Please enter your email' : null,
            ),
            const SizedBox(height: 16),
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
            builder: (context, auth, _) => CustomButton(
              label: AppStrings.login,
              onPressed: onLogin,
              isLoading: auth.isLoading || isSubmitting,
            ),
          ),
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
