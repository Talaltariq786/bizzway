import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/customers/customer_card.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.customers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined,
                color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: customerProv.setSearchQuery,
              decoration: InputDecoration(
                hintText: AppStrings.searchCustomers,
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                suffixIcon: const Icon(Icons.tune_outlined,
                    color: AppColors.textHint),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${customerProv.customers.length} Customers',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: customerProv.customers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'No customers found',
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: customerProv.customers.length,
                    itemBuilder: (_, i) =>
                        CustomerCard(customer: customerProv.customers[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
