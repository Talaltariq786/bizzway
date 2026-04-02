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

    // ── Grocery items ─────────────────────────────────────────────────────
    Product(
      id: 'gr1',
      businessTypeId: 'grocery',
      name: 'Premium Basmati Rice',
      description: 'Long-grain basmati rice, 5kg pack. Premium quality.',
      price: 1500,
      category: 'Staples (Basic Food)',
      unit: 'per 5kg',
      discountPercent: 10,
    ),
    Product(
      id: 'gr2',
      businessTypeId: 'grocery',
      name: 'Pure Ghee (Desi)',
      description: 'Traditional desi ghee, made fresh. 1kg pack.',
      price: 800,
      category: 'Oil & Ghee',
      unit: 'per 1kg',
    ),
    Product(
      id: 'gr3',
      businessTypeId: 'grocery',
      name: 'Whole Wheat Flour',
      description: 'Fresh ground atta (wheat flour). 5kg bag.',
      price: 400,
      category: 'Staples (Basic Food)',
      unit: 'per 5kg',
    ),
    Product(
      id: 'gr4',
      businessTypeId: 'grocery',
      name: 'Fresh Milk (1L)',
      description: 'Fresh pasteurized milk daily delivery.',
      price: 140,
      category: 'Dairy & Drinks',
      unit: 'per litre',
    ),
    Product(
      id: 'gr5',
      businessTypeId: 'grocery',
      name: 'White Bread Loaf',
      description: 'Freshly baked white bread. Soft & fluffy.',
      price: 75,
      category: 'Snacks & Bakery',
      unit: 'per loaf',
    ),
    Product(
      id: 'gr6',
      businessTypeId: 'grocery',
      name: 'Orange Juice (1L)',
      description: 'Fresh squeezed orange juice. No added sugar.',
      price: 280,
      category: 'Dairy & Drinks',
      unit: 'per litre',
    ),
    Product(
      id: 'gr7',
      businessTypeId: 'grocery',
      name: 'Sugar (2kg)',
      description: 'Refined white sugar, crystalline grade.',
      price: 220,
      category: 'Spices & Sauces',
      unit: 'per 2kg',
    ),

    // ── Salon services ────────────────────────────────────────────────────
    Product(
      id: 'sl1',
      businessTypeId: 'salon',
      name: 'Classic Haircut',
      description: 'Professional haircut with styling advice.',
      price: 400,
      category: 'Haircuts',
      durationMinutes: 30,
    ),
    Product(
      id: 'sl2',
      businessTypeId: 'salon',
      name: 'Beard Trim & Shaping',
      description: 'Expert beard trim with hot towel treatment.',
      price: 300,
      category: 'Haircuts',
      durationMinutes: 20,
    ),
    Product(
      id: 'sl3',
      businessTypeId: 'salon',
      name: 'Hair Color Treatment',
      description: 'Premium hair coloring with conditioning treatment.',
      price: 1200,
      category: 'Coloring',
      durationMinutes: 90,
    ),
    Product(
      id: 'sl4',
      businessTypeId: 'salon',
      name: 'Hair Spa Treatment',
      description: 'Deep conditioning spa for damaged/dry hair.',
      price: 800,
      category: 'Treatments',
      durationMinutes: 60,
    ),
    Product(
      id: 'sl5',
      businessTypeId: 'salon',
      name: 'Bridal Hair Styling',
      description: 'Complete bridal hairstyle with makeup coordination.',
      price: 2500,
      category: 'Styling',
      durationMinutes: 120,
    ),

    // ── Cafe menu ──────────────────────────────────────────────────────────
    Product(
      id: 'cf1',
      businessTypeId: 'cafe',
      name: 'Espresso',
      description: 'Strong shot of fresh espresso coffee.',
      price: 180,
      category: 'Coffee',
    ),
    Product(
      id: 'cf2',
      businessTypeId: 'cafe',
      name: 'Cappuccino',
      description: 'Creamy cappuccino with perfect foam.',
      price: 250,
      category: 'Coffee',
    ),
    Product(
      id: 'cf3',
      businessTypeId: 'cafe',
      name: 'Iced Latte',
      description: 'Cold iced latte with ice cream.',
      price: 320,
      category: 'Coffee',
      discountPercent: 15,
    ),
    Product(
      id: 'cf4',
      businessTypeId: 'cafe',
      name: 'Green Tea',
      description: 'Fresh organic green tea with honey.',
      price: 150,
      category: 'Tea',
    ),
    Product(
      id: 'cf5',
      businessTypeId: 'cafe',
      name: 'Chocolate Croissant',
      description: 'Buttery croissant with dark chocolate filling.',
      price: 280,
      category: 'Pastries',
    ),
    Product(
      id: 'cf6',
      businessTypeId: 'cafe',
      name: 'Club Sandwich',
      description: 'Triple layer sandwich with turkey, bacon & cheese.',
      price: 450,
      category: 'Sandwiches',
    ),

    // ── Pharmacy items ────────────────────────────────────────────────────
    Product(
      id: 'ph1',
      businessTypeId: 'pharmacy',
      name: 'Vitamin D3 Supplement',
      description: '60 tablets, 1000 IU per tablet. Supports bone health.',
      price: 350,
      category: 'Supplements',
      unit: 'per bottle',
    ),
    Product(
      id: 'ph2',
      businessTypeId: 'pharmacy',
      name: 'Digital Thermometer',
      description: 'Fast & accurate digital thermometer with beep alert.',
      price: 450,
      category: 'Equipment',
      unit: 'per unit',
    ),
    Product(
      id: 'ph3',
      businessTypeId: 'pharmacy',
      name: 'Antiseptic Cream',
      description: '50g antibacterial cream. Healing wound care.',
      price: 180,
      category: 'Personal Care',
      unit: 'per tube',
    ),
    Product(
      id: 'ph4',
      businessTypeId: 'pharmacy',
      name: 'Medical Mask (50 pcs)',
      description: '3-ply surgical masks. box of 50.',
      price: 280,
      category: 'Equipment',
      unit: 'per box',
    ),

    // ── Clinic services ────────────────────────────────────────────────────
    Product(
      id: 'cl1',
      businessTypeId: 'clinic',
      name: 'General Consultation',
      description: 'Doctor consultation with prescription.',
      price: 500,
      category: 'Consultations',
      durationMinutes: 30,
    ),
    Product(
      id: 'cl2',
      businessTypeId: 'clinic',
      name: 'Blood Test Package',
      description: 'Complete blood count (CBC) with report.',
      price: 1200,
      category: 'Lab Tests',
      durationMinutes: 15,
    ),
    Product(
      id: 'cl3',
      businessTypeId: 'clinic',
      name: 'COVID Vaccination',
      description: 'Complete COVID-19 vaccination series.',
      price: 0,
      category: 'Vaccinations',
      durationMinutes: 10,
    ),
    Product(
      id: 'cl4',
      businessTypeId: 'clinic',
      name: 'Tetanus Shot',
      description: 'Tetanus vaccine for injury prevention.',
      price: 200,
      category: 'Vaccinations',
      durationMinutes: 5,
    ),

    // ── Beauty Parlor services ─────────────────────────────────────────────
    Product(
      id: 'be1',
      businessTypeId: 'beauty',
      name: 'Facial Treatment',
      description: 'Complete facial with cleaning & massage.',
      price: 1000,
      category: 'Facial',
      durationMinutes: 60,
    ),
    Product(
      id: 'be2',
      businessTypeId: 'beauty',
      name: 'Full Body Waxing',
      description: 'Professional waxing for smooth skin.',
      price: 800,
      category: 'Waxing',
      durationMinutes: 45,
    ),
    Product(
      id: 'be3',
      businessTypeId: 'beauty',
      name: 'Threading (Face)',
      description: 'Traditional threading for face & eyebrows.',
      price: 250,
      category: 'Threading',
      durationMinutes: 20,
    ),
    Product(
      id: 'be4',
      businessTypeId: 'beauty',
      name: 'Nail Art Manicure',
      description: 'Nail paint with artistic designs.',
      price: 600,
      category: 'Nails',
      durationMinutes: 45,
    ),
    Product(
      id: 'be5',
      businessTypeId: 'beauty',
      name: 'Bridal Mehndi',
      description: 'Traditional intricate bridal henna (mehndi).',
      price: 2000,
      category: 'Mehndi',
      durationMinutes: 120,
    ),
    Product(
      id: 'be6',
      businessTypeId: 'beauty',
      name: 'Bridal Makeup Package',
      description: 'Complete bridal makeup with trials. Party ready!',
      price: 3000,
      category: 'Bridal',
      durationMinutes: 90,
    ),

    // ── Flower Shop items ──────────────────────────────────────────────────
    Product(
      id: 'fl1',
      businessTypeId: 'flowers',
      name: 'Red Rose Bouquet',
      description: '12 fresh red roses with green leaves. Love & romance.',
      price: 1800,
      category: 'Bouquets',
      isValentinesSpecial: true,
      discountPercent: 15,
    ),
    Product(
      id: 'fl2',
      businessTypeId: 'flowers',
      name: 'Spring Flower Arrangement',
      description: 'Mixed seasonal flowers in a beautiful vase.',
      price: 2200,
      category: 'Arrangements',
    ),
    Product(
      id: 'fl3',
      businessTypeId: 'flowers',
      name: 'Green Indoor Plant',
      description: 'Potted green plant for office/home. Low maintenance.',
      price: 500,
      category: 'Plants',
    ),
    Product(
      id: 'fl4',
      businessTypeId: 'flowers',
      name: 'Wedding Reception Centerpiece',
      description: '10 floral centerpieces for wedding tables.',
      price: 8000,
      category: 'Wreaths',
      bundleItems: const ['Rose', 'Jasmine', 'Carnations', 'Greenery'],
    ),
    Product(
      id: 'fl5',
      businessTypeId: 'flowers',
      name: 'Gift Basket With Flowers',
      description: 'Beautiful gift basket with fresh flowers & chocolates.',
      price: 2500,
      category: 'Gift Baskets',
    ),
    Product(
      id: 'fl6',
      businessTypeId: 'flowers',
      name: 'Mehndi Ceremony Flowers',
      description: 'Complete floral decoration package for mehndi event.',
      price: 5000,
      category: 'Arrangements',
      bundleItems: const ['Roses', 'Marigolds', 'Jasmine', 'Backdrop'],
    ),

    // ── Rent a Car services ────────────────────────────────────────────────
    Product(
      id: 'rc1',
      businessTypeId: 'rentacar',
      name: 'Economy Sedan',
      description: 'Fuel efficient compact car. Perfect for daily use.',
      price: 2000,
      category: 'Economy',
      unit: 'per day',
      discountPercent: 10,
    ),
    Product(
      id: 'rc2',
      businessTypeId: 'rentacar',
      name: 'Premium Sedan',
      description: 'Comfortable luxury sedan with AC & power steering.',
      price: 3500,
      category: 'Sedan',
      unit: 'per day',
    ),
    Product(
      id: 'rc3',
      businessTypeId: 'rentacar',
      name: 'SUV (7-Seater)',
      description: 'Spacious SUV for family trips & group travel.',
      price: 5000,
      category: 'SUV',
      unit: 'per day',
    ),
    Product(
      id: 'rc4',
      businessTypeId: 'rentacar',
      name: 'Luxury Van',
      description: '12-seater van with AC, perfect for tours & events.',
      price: 7000,
      category: 'Van',
      unit: 'per day',
    ),
    Product(
      id: 'rc5',
      businessTypeId: 'rentacar',
      name: 'Sedan With Driver',
      description: 'Rental dengan driver professional & insurance included.',
      price: 2500,
      category: 'With Driver',
      unit: 'per hour',
    ),

    // ── Auto Workshop services ─────────────────────────────────────────────
    Product(
      id: 'mch1',
      businessTypeId: 'mechanic',
      name: 'Car Oil Change',
      description: 'Standard oil change with new filter. All car types.',
      price: 800,
      category: 'Oil Change',
      durationMinutes: 30,
    ),
    Product(
      id: 'mch2',
      businessTypeId: 'mechanic',
      name: 'Battery Replacement',
      description: 'Battery replacement with installation & warranty.',
      price: 2500,
      category: 'Battery',
      durationMinutes: 45,
    ),
    Product(
      id: 'mch3',
      businessTypeId: 'mechanic',
      name: 'Tyre Repair/Replace',
      description: 'Puncture repair or complete tyre replacement service.',
      price: 600,
      category: 'Tyre',
      durationMinutes: 30,
    ),
    Product(
      id: 'mch4',
      businessTypeId: 'mechanic',
      name: 'Car Wash & Polish',
      description: 'Complete car wash, interior clean & wax polish.',
      price: 1200,
      category: 'Car Repair',
      durationMinutes: 60,
    ),
    Product(
      id: 'mch5',
      businessTypeId: 'mechanic',
      name: 'Bike Repair Service',
      description: 'General bike repair, tune-up & maintenance.',
      price: 400,
      category: 'Bike Repair',
      durationMinutes: 45,
    ),
    Product(
      id: 'mch6',
      businessTypeId: 'mechanic',
      name: 'Engine Diagnostic',
      description: 'Full computer diagnostic scan with report.',
      price: 500,
      category: 'Car Repair',
      durationMinutes: 30,
    ),

    // ── Pet Care services ──────────────────────────────────────────────────
    Product(
      id: 'pc1',
      businessTypeId: 'petcare',
      name: 'Veterinary Consultation',
      description: 'Professional Vet consultation for your pet.',
      price: 600,
      category: 'Vet Consultation',
      durationMinutes: 30,
    ),
    Product(
      id: 'pc2',
      businessTypeId: 'petcare',
      name: 'Pet Grooming',
      description: 'Complete grooming - nail trim, bath & styling.',
      price: 1200,
      category: 'Grooming',
      durationMinutes: 60,
    ),
    Product(
      id: 'pc3',
      businessTypeId: 'petcare',
      name: 'Vaccination Package',
      description: 'Complete vaccination package for dogs & cats.',
      price: 2000,
      category: 'Vaccination',
      durationMinutes: 45,
    ),
    Product(
      id: 'pc4',
      businessTypeId: 'petcare',
      name: 'Pet Boarding (Per Day)',
      description: 'Safe & comfortable boarding for your pet. Daily care included.',
      price: 800,
      category: 'Boarding',
      unit: 'per day',
    ),
    Product(
      id: 'pc5',
      businessTypeId: 'petcare',
      name: 'Emergency Pet Care',
      description: '24/7 emergency vet services. Available anytime.',
      price: 1500,
      category: 'Emergency',
      durationMinutes: 60,
    ),

    // ── Others (Generic Products & Services) ───────────────────────────────
    Product(
      id: 'oth1',
      businessTypeId: 'others',
      name: 'Professional Service',
      description: 'Custom professional service adjusted to your needs.',
      price: 1000,
      category: 'Services',
      durationMinutes: 60,
    ),
    Product(
      id: 'oth2',
      businessTypeId: 'others',
      name: 'Standard Product',
      description: 'Quality product with proper after-sales support.',
      price: 500,
      category: 'Products',
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
