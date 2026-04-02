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
import 'service_branch_switcher.dart';
import 'user_type_cards.dart';

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
    required this.onPickRiderLicenseImage,
    required this.onPickRiderNicImage,
    required this.onSignUp,
    required this.isSubmitting,
    required this.onSwitchToLogin,
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
  final VoidCallback onPickRiderLicenseImage;
  final VoidCallback onPickRiderNicImage;
  final VoidCallback onSignUp;
  final bool isSubmitting;
  final VoidCallback onSwitchToLogin;

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
          const SizedBox(height: 20),
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
                isSelected: selectedUserType == UserType.businessOwner,
                onTap: () => onUserTypeChanged(UserType.businessOwner),
              ),
              const SizedBox(width: 8),
              UserTypeToggleCard(
                title: 'Customer',
                subtitle: 'Book services nearby',
                isSelected: selectedUserType == UserType.customer,
                onTap: () => onUserTypeChanged(UserType.customer),
              ),
              const SizedBox(width: 8),
              UserTypeToggleCard(
                title: 'Service',
                subtitle: 'Get nearby jobs',
                isSelected: selectedUserType == UserType.serviceWorker,
                onTap: () => onUserTypeChanged(UserType.serviceWorker),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedUserType == UserType.serviceWorker) ...[
            ServiceBranchSwitcher(
              value: signupServiceBranch,
              onChanged: onSignupServiceBranchChanged,
            ),
            const SizedBox(height: 10),
          ],
          CustomTextField(
            label: 'Full Name',
            hint: 'e.g. Muhammad Ali Khan',
            controller: nameCtrl,
            prefixIcon: Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 10),
          if (selectedUserType == UserType.customer) ...[
            CustomTextField(
              label: 'Phone Number',
              hint: '03001234567',
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              validator: (v) =>
                  v!.isEmpty ? 'Please enter your phone number' : null,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'Area / Location',
              hint: 'e.g. Defence, Lahore',
              controller: areaCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => v!.isEmpty ? 'Please enter your area' : null,
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
              const SizedBox(height: 10),
              CustomTextField(
                label: 'Phone Number',
                hint: '03001234567',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'CNIC Number',
                hint: '12345-1234567-1',
                controller: workerNicCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter CNIC number' : null,
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 5),
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
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Driving license number',
                hint: 'License / LTV as per card',
                controller: riderLicenseCtrl,
                prefixIcon: Icons.credit_card_rounded,
                validator: (v) => (v ?? '').trim().length < 4
                    ? 'License number daalen'
                    : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'CNIC',
                hint: '12345-1234567-1',
                controller: riderNicCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    (v ?? '').trim().length < 13 ? 'Valid CNIC daalen' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Bike registration number',
                hint: 'e.g. KHI-1234',
                controller: riderBikeCtrl,
                prefixIcon: Icons.two_wheeler_rounded,
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Bike number daalen' : null,
              ),
              const SizedBox(height: 12),
              RiderWalletAgreementCard(
                agree: riderAgreeMinWallet,
                onToggle: onRiderAgreeToggle,
                onCheckboxChanged: onRiderAgreeCheckbox,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 6),
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
                validator: (v) =>
                    v!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                label: AppStrings.password,
                hint: 'Kamzori 6 characters (letters + numbers)',
                controller: signupPasswordCtrl,
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
