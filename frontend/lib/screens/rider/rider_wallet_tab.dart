// Ported from your `Bizzway_rider_sercices` app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

const double _navClearance = 88;

/// Wallet tab — balance, minimum pocket rule, demo top-up.
class RiderWalletTab extends StatelessWidget {
  const RiderWalletTab({super.key});

  static const double minPocketPkr = 5000;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bal = auth.riderWallet ?? 0;
    final ok = bal >= minPocketPkr;

    return ColoredBox(
      color: AppColors.backgroundLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, _navClearance),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pocket balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs. ${bal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      ok ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ok
                            ? 'Meets minimum Rs. ${minPocketPkr.toStringAsFixed(0)} (demo rule)'
                            : 'Below minimum Rs. ${minPocketPkr.toStringAsFixed(0)} — top up (demo)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Add funds (demo)',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap an amount — saved on this device only.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [500, 1000, 2000, 5000].map((amt) {
              return ActionChip(
                label: Text('+ Rs. $amt'),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await context
                      .read<AuthProvider>()
                      .addRiderWalletTopUp(amt.toDouble());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added Rs. $amt (demo)'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primary),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Production mein JazzCash / bank / wallet APIs yahan lagti hain. '
                'Abhi sirf local balance demo hai.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

