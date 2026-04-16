import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
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
