import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/custom_text_field.dart';
import 'login_constants.dart';
import 'rider_signup_widgets.dart';
import 'role_tabs.dart';
import 'service_branch_switcher.dart';

String? _validateFullName(String? v) {
  final t = (v ?? '').trim();
  if (t.length < 2) return 'Poora naam likhein (kam az kam 2 characters)';
  return null;
}

String? _validatePkPhone(String? v) {
  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 15) {
    return 'Valid phone: 10–15 digits (e.g. 03001234567)';
  }
  return null;
}

String? _validateBusinessEmail(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Email zaroori hai';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
    return 'Sahi email format (e.g. naam@gmail.com)';
  }
  return null;
}

class _NicDocTile extends StatelessWidget {
  const _NicDocTile({
    required this.label,
    required this.file,
    required this.onTap,
  });

  final String label;
  final XFile? file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final picked = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: picked ? AppColors.primary : AppColors.border,
            width: picked ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: picked
                    ? AppColors.primaryLight
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                picked ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                color: picked ? AppColors.primary : AppColors.textSecondary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked ? 'Photo selected' : 'Tap to upload',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.upload_rounded, color: AppColors.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}

class SignupForm extends StatelessWidget {
  const SignupForm({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.areaCtrl,
    required this.signupEmailCtrl,
    required this.signupPasswordCtrl,
    required this.workerNicCtrl,
    required this.riderLicenseCtrl,
    required this.riderNicCtrl,
    required this.riderBikeCtrl,
    required this.workerImage,
    required this.workerNicFrontImage,
    required this.workerNicBackImage,
    required this.riderLicenseImage,
    required this.riderNicImage,
    required this.selectedUserType,
    required this.onUserTypeChanged,
    required this.signupServiceBranch,
    required this.onSignupServiceBranchChanged,
    required this.selectedProfession,
    required this.onProfessionChanged,
    required this.selectedWorkerPlan,
    required this.onWorkerPlanChanged,
    required this.selectedRiderPlan,
    required this.onRiderPlanChanged,
    required this.riderAgreeMinWallet,
    required this.onRiderAgreeToggle,
    required this.onRiderAgreeCheckbox,
    required this.onPickWorkerImage,
    required this.onPickWorkerNicFrontImage,
    required this.onPickWorkerNicBackImage,
    required this.onPickRiderLicenseImage,
    required this.onPickRiderNicImage,
    required this.onSignUp,
    required this.isSubmitting,
    required this.onSwitchToLogin,
    this.onPickMapLocation,
    this.mapLocationSet = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController areaCtrl;
  final TextEditingController signupEmailCtrl;
  final TextEditingController signupPasswordCtrl;
  final TextEditingController workerNicCtrl;
  final TextEditingController riderLicenseCtrl;
  final TextEditingController riderNicCtrl;
  final TextEditingController riderBikeCtrl;
  final XFile? workerImage;
  final XFile? workerNicFrontImage;
  final XFile? workerNicBackImage;
  final XFile? riderLicenseImage;
  final XFile? riderNicImage;
  final UserType selectedUserType;
  final ValueChanged<UserType> onUserTypeChanged;
  final ServiceBranch signupServiceBranch;
  final ValueChanged<ServiceBranch> onSignupServiceBranchChanged;
  final String selectedProfession;
  final ValueChanged<String> onProfessionChanged;
  final String selectedWorkerPlan;
  final ValueChanged<String> onWorkerPlanChanged;
  final String selectedRiderPlan;
  final ValueChanged<String> onRiderPlanChanged;
  final bool riderAgreeMinWallet;
  final VoidCallback onRiderAgreeToggle;
  final ValueChanged<bool?> onRiderAgreeCheckbox;
  final VoidCallback onPickWorkerImage;
  final VoidCallback onPickWorkerNicFrontImage;
  final VoidCallback onPickWorkerNicBackImage;
  final VoidCallback onPickRiderLicenseImage;
  final VoidCallback onPickRiderNicImage;
  final VoidCallback onSignUp;
  final bool isSubmitting;
  final VoidCallback onSwitchToLogin;

  /// Customer: open map picker for delivery pin.
  final VoidCallback? onPickMapLocation;
  final bool mapLocationSet;

  @override
  Widget build(BuildContext context) {
    final isWorker = selectedUserType == UserType.serviceWorker &&
        signupServiceBranch == ServiceBranch.home;
    final isRider = selectedUserType == UserType.serviceWorker &&
        signupServiceBranch == ServiceBranch.rider;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your account type to get started',
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
            value: selectedUserType,
            onChanged: onUserTypeChanged,
          ),
          const SizedBox(height: 8),
          if (selectedUserType == UserType.serviceWorker) ...[
            ServiceBranchSwitcher(
              value: signupServiceBranch,
              onChanged: onSignupServiceBranchChanged,
              riderComingSoon: true,
            ),
            const SizedBox(height: 8),
          ],
          CustomTextField(
            label: 'Full Name',
            hint: 'e.g. Muhammad Ali Khan',
            controller: nameCtrl,
            prefixIcon: Icons.person_outline,
            validator: _validateFullName,
          ),
          const SizedBox(height: 10),
          if (selectedUserType == UserType.customer) ...[
            CustomTextField(
              label: 'Phone Number',
              hint: '03001234567',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: _validatePkPhone,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Area / Location',
              hint: 'e.g. Defence, Lahore — ya map se pin',
              controller: areaCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 3) {
                  return 'Area likhein ya map se location chunein';
                }
                return null;
              },
            ),
            if (onPickMapLocation != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onPickMapLocation,
                  icon: Icon(
                    mapLocationSet
                        ? Icons.check_circle_rounded
                        : Icons.map_rounded,
                    size: 20,
                    color: mapLocationSet ? Colors.green : AppColors.primary,
                  ),
                  label: Text(
                    mapLocationSet
                        ? 'Map location set'
                        : 'Map se pin karein',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: mapLocationSet ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            CustomTextField(
              label: AppStrings.password,
              hint: 'Min 6 characters',
              controller: signupPasswordCtrl,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              validator: (v) =>
                  (v ?? '').trim().length < 6 ? 'Min 6 characters' : null,
            ),
          ] else ...[
            if (isWorker) ...[
              Row(
                children: [
                  GestureDetector(
                    onTap: onPickWorkerImage,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        image: workerImage == null
                            ? null
                            : DecorationImage(
                                image: FileImage(File(workerImage!.path)),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: workerImage == null
                          ? const Icon(
                              Icons.camera_alt_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      workerImage == null
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
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NicDocTile(
                      label: 'CNIC front',
                      file: workerNicFrontImage,
                      onTap: onPickWorkerNicFrontImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _NicDocTile(
                      label: 'CNIC back',
                      file: workerNicBackImage,
                      onTap: onPickWorkerNicBackImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Phone Number',
                hint: '03001234567',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: _validatePkPhone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStrings.password,
                hint: 'Min 6 characters',
                controller: signupPasswordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    (v ?? '').trim().length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'CNIC Number',
                hint: '12345-1234567-1',
                controller: workerNicCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Please enter CNIC number';
                  // basic sanity: 13 digits (with or without dashes)
                  final digits = t.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 13) return 'Valid CNIC daalen';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>(selectedProfession),
                initialValue: selectedProfession,
                items: kWorkerProfessions
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onProfessionChanged(v);
                },
                decoration: InputDecoration(
                  labelText: 'Profession',
                  prefixIcon: const Icon(Icons.handyman_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 4),
              ...kWorkerPlans.map((p) {
                final selected = selectedWorkerPlan == p.id;
                return GestureDetector(
                  onTap: () => onWorkerPlanChanged(p.id),
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
            ] else if (isRider) ...[
              CustomTextField(
                label: 'Phone Number',
                hint: '03001234567',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: _validatePkPhone,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStrings.password,
                hint: 'Min 6 characters',
                controller: signupPasswordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    (v ?? '').trim().length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RiderDocPickerTile(
                      label: 'License photo',
                      file: riderLicenseImage,
                      onTap: onPickRiderLicenseImage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RiderDocPickerTile(
                      label: 'CNIC photo',
                      file: riderNicImage,
                      onTap: onPickRiderNicImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Driving license number',
                hint: 'License / LTV as per card',
                controller: riderLicenseCtrl,
                prefixIcon: Icons.credit_card_rounded,
                validator: (v) => (v ?? '').trim().length < 4
                    ? 'License number daalen'
                    : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'CNIC',
                hint: '12345-1234567-1',
                controller: riderNicCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    (v ?? '').trim().length < 13 ? 'Valid CNIC daalen' : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Bike registration number',
                hint: 'e.g. KHI-1234',
                controller: riderBikeCtrl,
                prefixIcon: Icons.two_wheeler_rounded,
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Bike number daalen' : null,
              ),
              const SizedBox(height: 10),
              RiderWalletAgreementCard(
                agree: riderAgreeMinWallet,
                onToggle: onRiderAgreeToggle,
                onCheckboxChanged: onRiderAgreeCheckbox,
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rider subscription',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              ...kRiderPlans.map((p) {
                final selected = selectedRiderPlan == p.id;
                return GestureDetector(
                  onTap: () => onRiderPlanChanged(p.id),
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
                          p.badge,
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
              CustomTextField(
                label: AppStrings.email,
                hint: 'aapka@email.com',
                controller: signupEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: _validateBusinessEmail,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                label: AppStrings.password,
                hint: 'Kamzori 6 characters (letters + numbers)',
                controller: signupPasswordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) =>
                    (v ?? '').trim().length < 6
                        ? 'Min 6 characters required'
                        : null,
              ),
            ],
          ],
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => CustomButton(
              label: AppStrings.signUp,
              onPressed: onSignUp,
              isLoading: auth.isLoading || isSubmitting,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: onSwitchToLogin,
              child: RichText(
                text: const TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: 'Login',
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
