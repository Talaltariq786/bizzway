import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [
    // ── Restaurant items ──────────────────────────────────────────────────
    Product(
      id: 'r1',
      businessTypeId: 'restaurant',
      name: 'Classic Beef Burger',
      description: 'Juicy beef patty with lettuce, tomato & cheese',
      price: 450,
      category: 'Food',
      discountPercent: 20,
    ),
    Product(
      id: 'r2',
      businessTypeId: 'restaurant',
      name: 'Chicken Karahi',
      description: 'Fresh chicken cooked in desi spices & tomato gravy',
      price: 950,
      category: 'Food',
    ),
    Product(
      id: 'r3',
      businessTypeId: 'restaurant',
      name: 'Fresh Lemonade',
      description: 'Chilled lemon juice with mint & shikanjvi taste',
      price: 180,
      category: 'Drinks',
    ),
    Product(
      id: 'r4',
      businessTypeId: 'restaurant',
      name: 'Family Deal',
      description: '2 karahi + 4 naans + 4 drinks + dessert',
      price: 2800,
      category: 'Combos',
      discountPercent: 15,
      bundleItems: const ['Chicken Karahi', 'Naan', 'Cold drink', 'Dessert'],
    ),
    Product(
      id: 'r5',
      businessTypeId: 'restaurant',
      name: 'Gulab Jamun',
      description: 'Soft khoya balls soaked in sugar syrup',
      price: 250,
      category: 'Desserts',
    ),

    // ── Gym packages (Memberships) ────────────────────────────────────────
    Product(
      id: 'gm1',
      businessTypeId: 'gym',
      name: 'Monthly Membership',
      description: 'Full access to gym floor, cardio & weights zone. No contract.',
      price: 3000,
      category: 'Memberships',
      unit: '1 Month',
      withTrainer: false,
    ),
    Product(
      id: 'gm2',
      businessTypeId: 'gym',
      name: 'Monthly + Personal Trainer',
      description: 'Dedicated trainer, customized workout plan & daily supervision.',
      price: 6500,
      category: 'Memberships',
      unit: '1 Month',
      withTrainer: true,
    ),
    Product(
      id: 'gm3',
      businessTypeId: 'gym',
      name: '3-Month Membership',
      description: 'Save more with quarterly plan. Full gym access included.',
      price: 8000,
      category: 'Memberships',
      unit: '3 Months',
      withTrainer: false,
      discountPercent: 11,
    ),
    Product(
      id: 'gm4',
      businessTypeId: 'gym',
      name: '3-Month + Personal Trainer',
      description: 'Quarterly plan with trainer — best for weight loss goals.',
      price: 17000,
      category: 'Memberships',
      unit: '3 Months',
      withTrainer: true,
      discountPercent: 13,
    ),
    Product(
      id: 'gm5',
      businessTypeId: 'gym',
      name: '6-Month Membership',
      description: 'Great value semi-annual plan. Lock in a lower monthly rate.',
      price: 14000,
      category: 'Memberships',
      unit: '6 Months',
      withTrainer: false,
      discountPercent: 22,
    ),
    Product(
      id: 'gm6',
      businessTypeId: 'gym',
      name: 'Annual Membership',
      description: 'Best value plan — full year unlimited access.',
      price: 25000,
      category: 'Memberships',
      unit: '12 Months',
      withTrainer: false,
      discountPercent: 30,
    ),
    Product(
      id: 'gm7',
      businessTypeId: 'gym',
      name: 'Annual + Personal Trainer',
      description: 'Full year with trainer — complete transformation package.',
      price: 55000,
      category: 'Memberships',
      unit: '12 Months',
      withTrainer: true,
      discountPercent: 29,
    ),

    // ── Gym personal training ─────────────────────────────────────────────
    Product(
      id: 'gpt1',
      businessTypeId: 'gym',
      name: 'Personal Training Session',
      description: 'One-on-one session with certified trainer. Customized workout.',
      price: 1500,
      category: 'Personal Training',
      durationMinutes: 60,
    ),
    Product(
      id: 'gpt2',
      businessTypeId: 'gym',
      name: '10-Session Pack',
      description: 'Pre-booked 10 personal training sessions. Save Rs. 2000.',
      price: 13000,
      category: 'Personal Training',
      durationMinutes: 60,
      discountPercent: 13,
    ),
    Product(
      id: 'gpt3',
      businessTypeId: 'gym',
      name: 'Strength & Conditioning',
      description: 'Advanced strength program for serious athletes.',
      price: 2000,
      category: 'Personal Training',
      durationMinutes: 90,
    ),

    // ── Gym group classes ─────────────────────────────────────────────────
    Product(
      id: 'gc1',
      businessTypeId: 'gym',
      name: 'Zumba Classes',
      description: 'High-energy dance fitness classes. 5 days a week.',
      price: 2500,
      category: 'Group Classes',
      unit: '1 Month',
      durationMinutes: 45,
    ),
    Product(
      id: 'gc2',
      businessTypeId: 'gym',
      name: 'CrossFit',
      description: 'Functional fitness training in a group. High intensity.',
      price: 3000,
      category: 'Group Classes',
      unit: '1 Month',
      durationMinutes: 60,
    ),
    Product(
      id: 'gc3',
      businessTypeId: 'gym',
      name: 'Boxing / MMA',
      description: 'Learn boxing basics & self-defense with pro coach.',
      price: 3500,
      category: 'Group Classes',
      unit: '1 Month',
      durationMinutes: 60,
    ),
    Product(
      id: 'gc4',
      businessTypeId: 'gym',
      name: 'Yoga & Stretching',
      description: 'Flexibility, balance & mental wellness sessions.',
      price: 2000,
      category: 'Group Classes',
      unit: '1 Month',
      durationMinutes: 50,
    ),

    // ── Gym diet plans ────────────────────────────────────────────────────
    Product(
      id: 'gd1',
      businessTypeId: 'gym',
      name: 'Weight Loss Diet Plan',
      description: 'Custom calorie-deficit meal plan by certified nutritionist.',
      price: 2000,
      category: 'Diet Plans',
      unit: '1 Month',
    ),
    Product(
      id: 'gd2',
      businessTypeId: 'gym',
      name: 'Muscle Gain Diet Plan',
      description: 'High-protein meal plan for bulking & muscle recovery.',
      price: 2500,
      category: 'Diet Plans',
      unit: '1 Month',
    ),
    Product(
      id: 'gd3',
      businessTypeId: 'gym',
      name: 'Full Transformation Package',
      description: 'Diet + workout plan combined — 3 month program.',
      price: 8000,
      category: 'Diet Plans',
      unit: '3 Months',
      discountPercent: 20,
    ),

    // ── Gym assessment ────────────────────────────────────────────────────
    Product(
      id: 'ga1',
      businessTypeId: 'gym',
      name: 'Body Composition Analysis',
      description: 'BMI, body fat %, muscle mass — full body assessment report.',
      price: 500,
      category: 'Assessment',
      durationMinutes: 30,
    ),
    Product(
      id: 'ga2',
      businessTypeId: 'gym',
      name: 'Fitness Level Test',
      description: 'Cardio, strength & flexibility baseline test for new members.',
      price: 800,
      category: 'Assessment',
      durationMinutes: 45,
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);

  List<Product> productsForBusiness(String businessTypeId) =>
      _products.where((p) => p.businessTypeId == businessTypeId).toList();

  List<Product> get activeDeals =>
      _products.where((p) => p.hasDiscount && p.isAvailable).toList();

  List<Product> activeDealsForBusiness(String businessTypeId) => _products
      .where((p) =>
          p.businessTypeId == businessTypeId && p.hasDiscount && p.isAvailable)
      .toList();

  List<Product> getByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  List<Product> getByCategoryForBusiness(String businessTypeId, String category) {
    final scoped = _products.where((p) => p.businessTypeId == businessTypeId);
    if (category == 'All') return scoped.toList();
    return scoped.where((p) => p.category == category).toList();
  }

  List<String> get categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    return ['All', ...cats];
  }

  List<String> categoriesForBusiness(String businessTypeId) {
    final cats = _products
        .where((p) => p.businessTypeId == businessTypeId)
        .map((p) => p.category)
        .toSet()
        .toList();
    return ['All', ...cats];
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// When an owner deletes a category, we must not leave products pointing to it.
  /// This migrates all products for a business from one category to another.
  void migrateCategoryForBusiness(
    String businessTypeId, {
    required String fromCategory,
    required String toCategory,
  }) {
    if (fromCategory.trim().isEmpty || toCategory.trim().isEmpty) return;
    if (fromCategory == toCategory) return;

    var changed = false;
    for (var i = 0; i < _products.length; i++) {
      final p = _products[i];
      if (p.businessTypeId == businessTypeId && p.category == fromCategory) {
        _products[i] = p.copyWith(category: toCategory);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void toggleAvailability(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index].isAvailable = !_products[index].isAvailable;
      notifyListeners();
    }
  }
}
