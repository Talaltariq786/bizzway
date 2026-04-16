import 'package:flutter/material.dart';
import '../models/customer.dart';

/// Owner-side customer list — populate from order/analytics API when available.
class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];

  String _searchQuery = '';

  List<Customer> get customers {
    if (_searchQuery.isEmpty) return List.unmodifiable(_customers);
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery))
        .toList();
  }

  int get totalCustomers => _customers.length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
  }
}
