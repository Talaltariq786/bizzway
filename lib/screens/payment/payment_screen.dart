import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/common/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedPlan = 1;

  final _plans = [
    _Plan(
      id: 0,
      name: 'Starter',
      price: 999,
      period: 'month',
      features: [
        'Up to 50 products',
        'Basic analytics',
        'Email support',
        '1 business type',
      ],
      color: AppColors.info,
    ),
    _Plan(
      id: 1,
      name: 'Professional',
      price: 2499,
      period: 'month',
      features: [
        'Unlimited products',
        'Advanced analytics',
        'Priority support',
        'All business types',
        'Custom branding',
      ],
      color: AppColors.primary,
      isPopular: true,
    ),
    _Plan(
      id: 2,
      name: 'Enterprise',
      price: 4999,
      period: 'month',
      features: [
        'Everything in Pro',
        'Multiple locations',
        'API access',
        'Dedicated support',
        'White-label export',
      ],
      color: AppColors.accent,
    ),
  ];

  final _transactions = [
    _Transaction(
        date: DateTime.now().subtract(const Duration(days: 5)),
        amount: 2499,
        plan: 'Professional',
        status: 'Paid'),
    _Transaction(
        date: DateTime.now().subtract(const Duration(days: 35)),
        amount: 2499,
        plan: 'Professional',
        status: 'Paid'),
    _Transaction(
        date: DateTime.now().subtract(const Duration(days: 65)),
        amount: 999,
        plan: 'Starter',
        status: 'Paid'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.subscription)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentPlanBanner(),
            const SizedBox(height: 24),
            Text(AppStrings.upgradePlan,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._plans.map((plan) => _PlanCard(
                  plan: plan,
                  isSelected: _selectedPlan == plan.id,
                  onSelect: () => setState(() => _selectedPlan = plan.id),
                )),
            const SizedBox(height: 20),
            CustomButton(
              label: '${AppStrings.payNow} — Rs. ${_plans[_selectedPlan].price}/mo',
              onPressed: () => _showPaymentDialog(context),
              icon: Icons.payment,
            ),
            const SizedBox(height: 28),
            Text(AppStrings.transactionHistory,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._transactions.map((tx) => _TransactionTile(tx: tx)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPlanBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.currentPlan,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
              const Text(
                'Professional Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Renews on Apr 25, 2026',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final plan = _plans[_selectedPlan];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Checkout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${plan.name} Plan',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Rs. ${plan.price}/mo',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            CustomButton(
              label: 'Pay Rs. ${plan.price}',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment successful! Plan activated.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'Payments are secured & encrypted',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final int id;
  final String name;
  final int price;
  final String period;
  final List<String> features;
  final Color color;
  final bool isPopular;

  _Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.color,
    this.isPopular = false,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? plan.color.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: plan.color,
                            ),
                          ),
                          if (plan.isPopular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: plan.color,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Rs. ${plan.price}/${plan.period}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? plan.color : AppColors.border,
                      width: 2,
                    ),
                    color: isSelected
                        ? plan.color
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: plan.features
                  .map((f) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: plan.color),
                          const SizedBox(width: 4),
                          Text(f,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Transaction {
  final DateTime date;
  final int amount;
  final String plan;
  final String status;

  _Transaction({
    required this.date,
    required this.amount,
    required this.plan,
    required this.status,
  });
}

class _TransactionTile extends StatelessWidget {
  final _Transaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.completed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_outlined,
                color: AppColors.completedText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tx.plan} Plan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('MMM d, y').format(tx.date),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${tx.amount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.completed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.completedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
