import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class RiderEditProfileScreen extends StatefulWidget {
  const RiderEditProfileScreen({super.key});

  @override
  State<RiderEditProfileScreen> createState() => _RiderEditProfileScreenState();
}

class _RiderEditProfileScreenState extends State<RiderEditProfileScreen> {
  late final TextEditingController _bikeCtrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _bikeCtrl = TextEditingController(text: auth.riderBike ?? '');
  }

  @override
  void dispose() {
    _bikeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _bikeCtrl,
              decoration: const InputDecoration(
                labelText: 'Bike number',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Minimal: profile details are stored via setRiderProfile during signup.
                  // For now we just close; deeper edit flow can be ported fully later.
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

