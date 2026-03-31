import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [
    Customer(
      id: 'c1',
      name: 'Ahmed Khan',
      phone: '0300-1234567',
      email: 'ahmed@example.com',
      totalOrders: 12,
      totalSpent: 8450,
      lastVisit: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    Customer(
      id: 'c2',
      name: 'Sara Ali',
      phone: '0321-9876543',
      email: 'sara@example.com',
      totalOrders: 7,
      totalSpent: 5200,
      lastVisit: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    Customer(
      id: 'c3',
      name: 'Bilal Hassan',
      phone: '0312-5551234',
      totalOrders: 5,
      totalSpent: 3100,
      lastVisit: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Customer(
      id: 'c4',
      name: 'Fatima Rizvi',
      phone: '0333-7778899',
      email: 'fatima@example.com',
      totalOrders: 3,
      totalSpent: 1350,
      lastVisit: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Customer(
      id: 'c5',
      name: 'Usman Malik',
      phone: '0345-1112233',
      totalOrders: 18,
      totalSpent: 12600,
      lastVisit: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

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
