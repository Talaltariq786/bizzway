import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

/// Minimal customer auth gate (ported concept from `Bizzway_customer_flow`).
///
/// Use this when a customer must be signed in before proceeding (checkout,
/// confirm booking, etc.).
class CustomerAuthGate {
  CustomerAuthGate._();

  static Future<bool> ensureSignedIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.isCustomer) return true;

    final go = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SignInRequiredSheet(
        onContinue: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (go == true && context.mounted) {
      Navigator.pushNamed(context, AppRoutes.login);
    }
    return false;
  }
}

class _SignInRequiredSheet extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  const _SignInRequiredSheet({
    required this.onContinue,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign in required',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Is action ko complete karne ke liye customer login zaroori hai.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onContinue,
                        child: const Text('Sign in'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

