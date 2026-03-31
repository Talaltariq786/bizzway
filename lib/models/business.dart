import 'package:flutter/material.dart';
import '../models/product.dart';

// ── BusinessItem (menu item / service / product / package) ──────────────────

class BusinessItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final double? originalPrice; // when discounted, keep original for UI
  final double discountPercent; // 0..100
  final String category;
  final int? durationMinutes; // for services / appointments
  final String? unit;         // "per month", "per kg", "per session"
  final List<String> includes; // bundle/package contents (names)

  const BusinessItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl = '',
    this.originalPrice,
    this.discountPercent = 0,
    required this.category,
    this.durationMinutes,
    this.unit,
    this.includes = const [],
  });

  bool get isBundle => includes.isNotEmpty;
  bool get hasDiscount =>
      discountPercent > 0 && originalPrice != null && originalPrice! > price;

  /// Convert owner's Product → BusinessItem (live bridge)
  factory BusinessItem.fromProduct(Product p) => BusinessItem(
        id: p.id,
        name: p.name,
        description: p.description,
        price: p.hasDiscount ? p.discountedPrice : p.price,
        imageUrl: p.imageUrl,
        originalPrice: p.hasDiscount ? p.price : null,
        discountPercent: p.hasDiscount ? p.discountPercent : 0,
        category: p.category,
        durationMinutes: p.durationMinutes,
        unit: p.unit,
        includes: p.bundleItems,
      );
}

// ── Business ─────────────────────────────────────────────────────────────────

class Business {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String businessTypeId;
  final bool isOpen;
  final List<BusinessItem> items;
  final String? tagline;
  final Color color;
  final String? phone;
  final double? deliveryBaseCharge;   // Rs. fixed base fee
  final double? deliveryPerKmCharge;  // Rs. per km
  final double? deliveryRadiusKm;     // Owner-defined delivery radius (used for tiered pricing)

  const Business({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.businessTypeId,
    required this.isOpen,
    required this.items,
    required this.color,
    this.tagline,
    this.phone,
    this.deliveryBaseCharge,
    this.deliveryPerKmCharge,
    this.deliveryRadiusKm,
  });

  bool get hasDelivery =>
      deliveryRadiusKm != null || deliveryBaseCharge != null;

  double deliveryFeeFor(double km) {
    if (!hasDelivery) return 0;
    // Grocery: tiered delivery fees depending on the owner's radius/distance.
    if (businessTypeId == 'grocery' && deliveryRadiusKm != null) {
      final d = km.clamp(0, deliveryRadiusKm!);
      // 1–2 km => 80, 5 km => 150, 20 km => 300 (as requested)
      if (d <= 2) return 80;
      if (d <= 5) return 150;
      return 300;
    }

    // Default: linear base + per-km.
    if (deliveryBaseCharge != null) {
      return deliveryBaseCharge! + (deliveryPerKmCharge ?? 0) * km;
    }
    return 0;
  }

  /// Live bridge: build a Business from the owner's provider data
  factory Business.fromOwner({
    required String businessName,
    required String businessTypeId,
    required Color color,
    required List<Product> products,
    double? deliveryBaseCharge,
    double? deliveryPerKmCharge,
    double? deliveryRadiusKm,
  }) {
    return Business(
      id: 'owner_live',
      name: businessName,
      address: 'Your Location • Live on BizzWay',
      rating: 5.0,
      reviewCount: 0,
      businessTypeId: businessTypeId,
      isOpen: true,
      color: color,
      tagline: 'Powered by BizzWay',
      items: products
          .where((p) => p.isAvailable)
          .map((p) => BusinessItem.fromProduct(p))
          .toList(),
      deliveryBaseCharge: deliveryBaseCharge,
      deliveryPerKmCharge: deliveryPerKmCharge,
      deliveryRadiusKm: deliveryRadiusKm,
    );
  }

  String get actionLabel {
    switch (businessTypeId) {
      case 'restaurant':
      case 'cafe':        return 'Reserve';
      case 'gym':         return 'Enroll';
      case 'grocery':
      case 'pharmacy':
      case 'flowers':     return 'Order';
      case 'rentacar':    return 'Book Car';
      default:            return 'Book';
    }
  }

  String get bookingTitle {
    switch (businessTypeId) {
      case 'restaurant':
      case 'cafe':        return 'Reserve a Table';
      case 'gym':         return 'Enroll / Book Session';
      case 'grocery':
      case 'pharmacy':
      case 'flowers':     return 'Place Order';
      case 'rentacar':    return 'Book a Vehicle';
      default:            return 'Book Appointment';
    }
  }

  IconData get typeIcon {
    switch (businessTypeId) {
      case 'restaurant':  return Icons.restaurant_rounded;
      case 'grocery':     return Icons.local_grocery_store_rounded;
      case 'salon':       return Icons.content_cut_rounded;
      case 'gym':         return Icons.fitness_center_rounded;
      case 'clinic':      return Icons.local_hospital_rounded;
      case 'pharmacy':    return Icons.medication_rounded;
      case 'cafe':        return Icons.local_cafe_rounded;
      case 'beauty':      return Icons.face_retouching_natural;
      case 'flowers':     return Icons.local_florist_rounded;
      case 'rentacar':    return Icons.directions_car_rounded;
      case 'mechanic':    return Icons.build_rounded;
      case 'homeservice': return Icons.handyman_rounded;
      case 'petcare':     return Icons.pets_rounded;
      default:            return Icons.store_rounded;
    }
  }
}

// ── CustomerBooking ──────────────────────────────────────────────────────────

class CustomerBooking {
  final String id;
  final String businessId;
  final String businessName;
  final String businessTypeId;
  final String itemId;
  final String itemName;
  final double price;
  final int? durationMinutes;
  final DateTime dateTime;
  String status; // pending, confirmed, completed, cancelled
  final String? notes;

  CustomerBooking({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessTypeId,
    required this.itemId,
    required this.itemName,
    required this.price,
    this.durationMinutes,
    required this.dateTime,
    this.status = 'pending',
    this.notes,
  });

  factory CustomerBooking.fromJson(Map<String, dynamic> json) {
    return CustomerBooking(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      businessName: (json['businessName'] ?? '').toString(),
      businessTypeId: (json['businessTypeId'] ?? '').toString(),
      itemId: (json['itemId'] ?? '').toString(),
      itemName: (json['itemName'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      dateTime: DateTime.tryParse((json['dateTime'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['status'] ?? 'pending').toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'businessName': businessName,
      'businessTypeId': businessTypeId,
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'durationMinutes': durationMinutes,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  String get actionLabel {
    switch (businessTypeId) {
      case 'restaurant':
      case 'cafe':    return 'Reservation';
      case 'gym':     return 'Session';
      case 'grocery':
      case 'pharmacy':return 'Order';
      default:        return 'Appointment';
    }
  }
}

// ── Dummy data for ALL 8 business types ──────────────────────────────────────

final List<Business> allDummyBusinesses = [

  // ── RESTAURANTS ────────────────────────────────────────────────────────────
  Business(
    id: 'r1', businessTypeId: 'restaurant', isOpen: true,
    deliveryBaseCharge: 50, deliveryPerKmCharge: 20,
    name: 'BBQ Tonight', address: 'Clifton Block 5, Karachi',
    rating: 4.7, reviewCount: 312, color: const Color(0xFFFF6B6B),
    tagline: 'Best BBQ in the city',
    items: const [
      BusinessItem(id: 'r1i1', name: 'Seekh Kabab Platter', description: '8 pcs seekh kabab with naan & raita', price: 850, category: 'BBQ'),
      BusinessItem(id: 'r1i2', name: 'Mix Grill', description: 'Chicken + mutton + seekh combo', price: 1400, category: 'BBQ'),
      BusinessItem(id: 'r1i3', name: 'Biryani (Full)', description: 'Dum biryani with raita & salad', price: 950, category: 'Rice'),
      BusinessItem(id: 'r1i4', name: 'Chicken Karahi', description: '1/2 kg karahi with naan', price: 780, category: 'Main Course'),
      BusinessItem(id: 'r1i5', name: 'Cold Drinks', description: 'Pepsi / 7up / Dew 500ml', price: 120, category: 'Drinks'),
      BusinessItem(id: 'r1i6', name: 'Gulab Jamun', description: '4 pieces with syrup', price: 200, category: 'Desserts'),
      BusinessItem(
        id: 'r1d1',
        name: 'Burger + Fries + Drink Combo',
        description: 'Best value combo for 1 person',
        price: 799,
        category: 'Deals',
        includes: ['Burger', 'Fries', 'Cold drink'],
      ),
    ],
  ),
  Business(
    id: 'r2', businessTypeId: 'restaurant', isOpen: true,
    deliveryBaseCharge: 60, deliveryPerKmCharge: 15,
    name: 'Savour Foods', address: 'F-10 Markaz, Islamabad',
    rating: 4.9, reviewCount: 520, color: const Color(0xFFFF6B6B),
    tagline: 'Legendary taste since 1990',
    items: const [
      BusinessItem(id: 'r2i1', name: 'Chicken Karahi', description: 'Signature karahi recipe', price: 900, category: 'Main Course'),
      BusinessItem(id: 'r2i2', name: 'Mutton Karahi', description: 'Tender mutton karahi', price: 1600, category: 'Main Course'),
      BusinessItem(id: 'r2i3', name: 'Daal Makhni', description: 'Slow-cooked black lentils', price: 350, category: 'Main Course'),
      BusinessItem(id: 'r2i4', name: 'Naan (Plain)', description: 'Freshly baked naan', price: 40, category: 'Breads'),
      BusinessItem(id: 'r2i5', name: 'Mango Lassi', description: 'Thick chilled lassi', price: 250, category: 'Drinks'),
      BusinessItem(id: 'r2i6', name: 'Kheer', description: 'Creamy rice pudding', price: 180, category: 'Desserts'),
    ],
  ),
  Business(
    id: 'r3', businessTypeId: 'restaurant', isOpen: false,
    name: 'Tuscany Courtyard', address: 'DHA Phase 6, Lahore',
    rating: 4.5, reviewCount: 198, color: const Color(0xFFFF6B6B),
    tagline: 'Italian dining experience',
    items: const [
      BusinessItem(id: 'r3i1', name: 'Margherita Pizza', description: 'Classic tomato + mozzarella', price: 1100, category: 'Pizza'),
      BusinessItem(id: 'r3i2', name: 'Pasta Alfredo', description: 'Creamy white sauce pasta', price: 850, category: 'Pasta'),
      BusinessItem(id: 'r3i3', name: 'Caesar Salad', description: 'Romaine + croutons + dressing', price: 600, category: 'Salads'),
      BusinessItem(id: 'r3i4', name: 'Tiramisu', description: 'Classic Italian dessert', price: 450, category: 'Desserts'),
    ],
  ),

  // ── GROCERY ────────────────────────────────────────────────────────────────
  Business(
    id: 'g1', businessTypeId: 'grocery', isOpen: true,
    deliveryBaseCharge: 80, deliveryPerKmCharge: 20,
    name: 'Metro Cash & Carry', address: 'Gulberg III, Lahore',
    rating: 4.3, reviewCount: 89, color: const Color(0xFF4CAF50),
    tagline: 'Fresh everyday essentials',
    items: const [
      BusinessItem(id: 'g1i1', name: 'Fresh Milk (1L)', description: 'Pasteurized full-cream milk', price: 180, category: 'Dairy', unit: 'per litre'),
      BusinessItem(id: 'g1i2', name: 'Eggs (30 pcs)', description: 'Farm fresh eggs', price: 650, category: 'Dairy'),
      BusinessItem(id: 'g1i3', name: 'Basmati Rice (5kg)', description: 'Premium long grain rice', price: 1200, category: 'Staples', unit: 'per bag'),
      BusinessItem(id: 'g1i4', name: 'Cooking Oil (5L)', description: 'Sunflower / canola oil', price: 2100, category: 'Staples'),
      BusinessItem(id: 'g1i5', name: 'Tomatoes (1kg)', description: 'Fresh locally sourced', price: 120, category: 'Vegetables', unit: 'per kg'),
      BusinessItem(id: 'g1i6', name: 'Onion (1kg)', description: 'Red onion fresh', price: 80, category: 'Vegetables', unit: 'per kg'),
      BusinessItem(
        id: 'g1p1',
        name: 'Monthly Ration Pack (Mini)',
        description: 'Essentials bundle for small family',
        price: 4999,
        category: 'Packages',
        includes: ['Basmati rice', 'Cooking oil', 'Daal', 'Tea'],
        unit: 'per pack',
      ),
    ],
  ),
  Business(
    id: 'g2', businessTypeId: 'grocery', isOpen: true,
    deliveryBaseCharge: 70, deliveryPerKmCharge: 20,
    name: 'Al-Fatah Stores', address: 'MM Alam Road, Lahore',
    rating: 4.1, reviewCount: 64, color: const Color(0xFF4CAF50),
    tagline: 'Your neighbourhood store',
    items: const [
      BusinessItem(id: 'g2i1', name: 'Bread Loaf', description: 'Soft white sandwich bread', price: 120, category: 'Bakery'),
      BusinessItem(id: 'g2i2', name: 'Butter (200g)', description: 'Salted / unsalted', price: 350, category: 'Dairy'),
      BusinessItem(id: 'g2i3', name: 'Chicken (1kg)', description: 'Fresh broiler chicken', price: 520, category: 'Meat', unit: 'per kg'),
      BusinessItem(id: 'g2i4', name: 'Mineral Water (6 pack)', description: '500ml bottles', price: 280, category: 'Beverages'),
    ],
  ),

  // ── SALON ──────────────────────────────────────────────────────────────────
  Business(
    id: 's1', businessTypeId: 'salon', isOpen: true,
    name: 'Glamour Studio', address: 'Block 7, Gulshan-e-Iqbal, Karachi',
    rating: 4.8, reviewCount: 124, color: const Color(0xFFE91E63),
    tagline: 'Where beauty meets perfection',
    items: const [
      BusinessItem(id: 's1i1', name: 'Haircut & Styling', description: 'Professional cut with blow dry', price: 800, category: 'Hair', durationMinutes: 45),
      BusinessItem(id: 's1i2', name: 'Hair Coloring', description: 'Full color, highlights or balayage', price: 3500, category: 'Hair', durationMinutes: 120),
      BusinessItem(id: 's1i3', name: 'Deep Conditioning Spa', description: 'Nourishing mask + scalp massage', price: 1500, category: 'Spa', durationMinutes: 60),
      BusinessItem(id: 's1i4', name: 'Facial Treatment', description: 'Cleansing + toning + moisturizing', price: 1200, category: 'Skin', durationMinutes: 60),
      BusinessItem(id: 's1i5', name: 'Manicure', description: 'Classic nail care with polish', price: 600, category: 'Nails', durationMinutes: 40),
      BusinessItem(
        id: 's1p1',
        name: 'Glow Package',
        description: 'Best value package (popular)',
        price: 2499,
        category: 'Packages',
        durationMinutes: 120,
        includes: ['Facial', 'Manicure', 'Head massage'],
      ),
    ],
  ),
  Business(
    id: 's2', businessTypeId: 'salon', isOpen: true,
    name: 'The Beauty Lounge', address: 'DHA Phase 5, Lahore',
    rating: 4.6, reviewCount: 89, color: const Color(0xFFE91E63),
    tagline: 'Feel your best self',
    items: const [
      BusinessItem(id: 's2i1', name: 'Bridal Makeup', description: 'Full bridal look with airbrush', price: 8000, category: 'Makeup', durationMinutes: 180),
      BusinessItem(id: 's2i2', name: 'Gel Nails', description: 'Long-lasting gel polish', price: 1800, category: 'Nails', durationMinutes: 75),
      BusinessItem(id: 's2i3', name: 'Waxing (Full Body)', description: 'Complete waxing session', price: 2500, category: 'Waxing', durationMinutes: 90),
      BusinessItem(id: 's2i4', name: 'Eyebrow Threading', description: 'Precision shaping', price: 200, category: 'Eyebrows', durationMinutes: 15),
    ],
  ),
  Business(
    id: 's3', businessTypeId: 'salon', isOpen: false,
    name: 'Zen Wellness Spa', address: 'F-7 Markaz, Islamabad',
    rating: 4.9, reviewCount: 210, color: const Color(0xFFE91E63),
    tagline: 'Relax. Rejuvenate. Restore.',
    items: const [
      BusinessItem(id: 's3i1', name: 'Swedish Massage', description: 'Relaxing full body massage', price: 2500, category: 'Massage', durationMinutes: 60),
      BusinessItem(id: 's3i2', name: 'Hot Stone Therapy', description: 'Deep muscle relaxation', price: 3500, category: 'Massage', durationMinutes: 90),
      BusinessItem(id: 's3i3', name: 'Gold Facial', description: 'Anti-aging gold leaf facial', price: 3000, category: 'Skin', durationMinutes: 75),
    ],
  ),

  // ── GYM ────────────────────────────────────────────────────────────────────
  Business(
    id: 'gy1', businessTypeId: 'gym', isOpen: true,
    name: 'Fitness Force', address: 'Gulberg, Lahore',
    rating: 4.6, reviewCount: 143, color: const Color(0xFFFF9800),
    tagline: 'Your transformation starts here',
    items: const [
      BusinessItem(id: 'gy1i1', name: 'Monthly Membership', description: 'Unlimited gym access', price: 3500, category: 'Memberships', unit: 'per month'),
      BusinessItem(id: 'gy1i2', name: 'Quarterly Plan', description: '3 months unlimited access', price: 9000, category: 'Memberships', unit: '3 months'),
      BusinessItem(id: 'gy1i3', name: 'Personal Training (1 session)', description: '1-on-1 trainer session 60 min', price: 2000, category: 'Personal Training', durationMinutes: 60),
      BusinessItem(id: 'gy1i4', name: 'Zumba Class', description: 'Group fitness dance class', price: 500, category: 'Classes', durationMinutes: 45),
      BusinessItem(id: 'gy1i5', name: 'Diet Plan', description: 'Customized nutrition plan by expert', price: 1500, category: 'Diet Plans', unit: 'per month'),
    ],
  ),
  Business(
    id: 'gy2', businessTypeId: 'gym', isOpen: true,
    name: 'Gold\'s Gym Karachi', address: 'Clifton, Karachi',
    rating: 4.8, reviewCount: 287, color: const Color(0xFFFF9800),
    tagline: 'The gym of champions',
    items: const [
      BusinessItem(id: 'gy2i1', name: 'Monthly Membership', description: 'All facilities included', price: 5000, category: 'Memberships', unit: 'per month'),
      BusinessItem(id: 'gy2i2', name: 'Yoga Class', description: 'Morning & evening yoga', price: 600, category: 'Classes', durationMinutes: 60),
      BusinessItem(id: 'gy2i3', name: 'Swimming Pool Access', description: 'Per entry or monthly', price: 300, category: 'Pool', unit: 'per entry'),
      BusinessItem(id: 'gy2i4', name: 'Sauna & Steam', description: 'Relaxation + recovery', price: 400, category: 'Wellness', durationMinutes: 30),
    ],
  ),

  // ── CLINIC ─────────────────────────────────────────────────────────────────
  Business(
    id: 'c1', businessTypeId: 'clinic', isOpen: true,
    name: 'Shifa Clinic', address: 'F-8 Markaz, Islamabad',
    rating: 4.7, reviewCount: 203, color: const Color(0xFF2196F3),
    tagline: 'Your health, our priority',
    items: const [
      BusinessItem(id: 'c1i1', name: 'General Consultation', description: 'OPD consultation with GP', price: 500, category: 'Consultations', durationMinutes: 20),
      BusinessItem(id: 'c1i2', name: 'Specialist Consultation', description: 'Cardiologist / Dermatologist / ENT', price: 1500, category: 'Consultations', durationMinutes: 30),
      BusinessItem(id: 'c1i3', name: 'Blood Test (CBC)', description: 'Complete blood count', price: 600, category: 'Lab Tests', durationMinutes: 10),
      BusinessItem(id: 'c1i4', name: 'X-Ray', description: 'Digital X-ray with report', price: 800, category: 'Lab Tests', durationMinutes: 15),
      BusinessItem(id: 'c1i5', name: 'Flu Vaccination', description: 'Annual influenza vaccine', price: 1200, category: 'Vaccinations', durationMinutes: 10),
    ],
  ),
  Business(
    id: 'c2', businessTypeId: 'clinic', isOpen: false,
    name: 'Doctors Hospital', address: 'Canal Bank Road, Lahore',
    rating: 4.5, reviewCount: 412, color: const Color(0xFF2196F3),
    tagline: 'Excellence in healthcare',
    items: const [
      BusinessItem(id: 'c2i1', name: 'OPD Consultation', description: 'General physician', price: 700, category: 'Consultations', durationMinutes: 20),
      BusinessItem(id: 'c2i2', name: 'Dental Checkup', description: 'Cleaning + examination', price: 1200, category: 'Dental', durationMinutes: 45),
      BusinessItem(id: 'c2i3', name: 'Ultrasound', description: 'Abdomen ultrasound with report', price: 2500, category: 'Lab Tests', durationMinutes: 20),
    ],
  ),

  // ── PHARMACY ───────────────────────────────────────────────────────────────
  Business(
    id: 'ph1', businessTypeId: 'pharmacy', isOpen: true,
    deliveryBaseCharge: 50, deliveryPerKmCharge: 10,
    name: 'Servaid Pharmacy', address: 'Multiple locations, Lahore',
    rating: 4.4, reviewCount: 156, color: const Color(0xFF00BCD4),
    tagline: 'Health at your doorstep',
    items: const [
      BusinessItem(id: 'ph1i1', name: 'Panadol (10 tabs)', description: 'Paracetamol 500mg', price: 45, category: 'Medicines'),
      BusinessItem(id: 'ph1i2', name: 'Vitamin C (30 tabs)', description: '500mg effervescent tablets', price: 380, category: 'Supplements'),
      BusinessItem(id: 'ph1i3', name: 'Face Wash (100ml)', description: 'Gentle daily cleanser', price: 320, category: 'Personal Care'),
      BusinessItem(id: 'ph1i4', name: 'Blood Pressure Monitor', description: 'Digital automatic BP machine', price: 4500, category: 'Equipment'),
      BusinessItem(id: 'ph1i5', name: 'Glucometer Kit', description: 'Blood sugar testing kit', price: 3200, category: 'Equipment'),
    ],
  ),
  Business(
    id: 'ph2', businessTypeId: 'pharmacy', isOpen: true,
    deliveryBaseCharge: 50, deliveryPerKmCharge: 10,
    name: 'Fazal Din Pharmacy', address: 'Davis Road, Lahore',
    rating: 4.2, reviewCount: 98, color: const Color(0xFF00BCD4),
    tagline: 'Trusted since decades',
    items: const [
      BusinessItem(id: 'ph2i1', name: 'Antibiotic Course', description: 'Amoxicillin 500mg (10 caps)', price: 280, category: 'Medicines'),
      BusinessItem(id: 'ph2i2', name: 'Omega 3 (30 caps)', description: 'Fish oil capsules', price: 650, category: 'Supplements'),
      BusinessItem(id: 'ph2i3', name: 'Moisturizer (200ml)', description: 'Daily body lotion', price: 450, category: 'Personal Care'),
    ],
  ),

  // ── CAFÉ ────────────────────────────────────────────────────────────────────
  Business(
    id: 'cf1', businessTypeId: 'cafe', isOpen: true,
    deliveryBaseCharge: 50, deliveryPerKmCharge: 15,
    name: 'Espresso Yourself', address: 'Zamzama, Karachi',
    rating: 4.8, reviewCount: 267, color: const Color(0xFF795548),
    tagline: 'Life\'s too short for bad coffee',
    items: const [
      BusinessItem(id: 'cf1i1', name: 'Cappuccino', description: 'Espresso with steamed milk foam', price: 380, category: 'Coffee'),
      BusinessItem(id: 'cf1i2', name: 'Caramel Latte', description: 'Espresso + caramel + steamed milk', price: 450, category: 'Coffee'),
      BusinessItem(id: 'cf1i3', name: 'Chai Latte', description: 'Spiced chai with steamed milk', price: 350, category: 'Tea'),
      BusinessItem(id: 'cf1i4', name: 'Club Sandwich', description: 'Triple layer chicken sandwich', price: 550, category: 'Sandwiches'),
      BusinessItem(id: 'cf1i5', name: 'Croissant', description: 'Butter / chocolate / almond', price: 280, category: 'Pastries'),
      BusinessItem(id: 'cf1i6', name: 'Red Velvet Slice', description: 'Signature red velvet cake', price: 350, category: 'Pastries'),
    ],
  ),
  Business(
    id: 'cf2', businessTypeId: 'cafe', isOpen: true,
    deliveryBaseCharge: 50, deliveryPerKmCharge: 15,
    name: 'The Coffee Bean', address: 'Gulberg Main Blvd, Lahore',
    rating: 4.6, reviewCount: 189, color: const Color(0xFF795548),
    tagline: 'Crafted with love & beans',
    items: const [
      BusinessItem(id: 'cf2i1', name: 'Cold Brew', description: '12-hour steeped cold coffee', price: 420, category: 'Coffee'),
      BusinessItem(id: 'cf2i2', name: 'Frappuccino', description: 'Blended iced coffee drink', price: 480, category: 'Coffee'),
      BusinessItem(id: 'cf2i3', name: 'Avocado Toast', description: 'Sourdough + avocado + eggs', price: 620, category: 'Sandwiches'),
      BusinessItem(id: 'cf2i4', name: 'Blueberry Muffin', description: 'Freshly baked daily', price: 250, category: 'Pastries'),
    ],
  ),

  // ── OTHERS ─────────────────────────────────────────────────────────────────
  Business(
    id: 'o1', businessTypeId: 'others', isOpen: true,
    name: 'Fix It Workshop', address: 'Saddar, Karachi',
    rating: 4.3, reviewCount: 45, color: const Color(0xFF9C27B0),
    tagline: 'We fix everything',
    items: const [
      BusinessItem(id: 'o1i1', name: 'Phone Screen Repair', description: 'Any model, same day', price: 2500, category: 'Services', durationMinutes: 60),
      BusinessItem(id: 'o1i2', name: 'Laptop Servicing', description: 'Cleaning + thermal paste', price: 1500, category: 'Services', durationMinutes: 120),
      BusinessItem(id: 'o1i3', name: 'AC Servicing', description: 'Full clean + gas check', price: 2000, category: 'Services', durationMinutes: 90),
    ],
  ),

  // ── BEAUTY PARLOR ───────────────────────────────────────────────────────────
  Business(
    id: 'bp1', businessTypeId: 'beauty', isOpen: true,
    name: 'Nadia\'s Beauty Lounge', address: 'Gulshan-e-Iqbal Block 13, Karachi',
    rating: 4.9, reviewCount: 312, color: const Color(0xFFFF4081),
    tagline: 'Glow up with confidence',
    phone: '0312-3456789',
    items: const [
      BusinessItem(id: 'bp1i1', name: 'Facial (Basic)', description: 'Deep cleansing + moisturizing', price: 800, category: 'Facial', durationMinutes: 45),
      BusinessItem(id: 'bp1i2', name: 'Gold Facial', description: 'Anti-aging gold leaf treatment', price: 2500, category: 'Facial', durationMinutes: 75),
      BusinessItem(id: 'bp1i3', name: 'Full Body Waxing', description: 'Smooth finish with soothing lotion', price: 2000, category: 'Waxing', durationMinutes: 90),
      BusinessItem(id: 'bp1i4', name: 'Eyebrow Threading', description: 'Precise shaping + tinting', price: 250, category: 'Threading', durationMinutes: 15),
      BusinessItem(id: 'bp1i5', name: 'Manicure + Pedicure', description: 'Complete nail care combo', price: 1500, category: 'Nails', durationMinutes: 90),
      BusinessItem(id: 'bp1i6', name: 'Bridal Makeup', description: 'Full bridal look with airbrush + saree draping', price: 12000, category: 'Bridal', durationMinutes: 240),
      BusinessItem(id: 'bp1i7', name: 'Mehndi (Haath)', description: 'Arabic / Bridal mehndi design', price: 1500, category: 'Mehndi', durationMinutes: 120),
    ],
  ),
  Business(
    id: 'bp2', businessTypeId: 'beauty', isOpen: true,
    name: 'Sana Safinaz Beauty Studio', address: 'DHA Phase 5, Lahore',
    rating: 4.7, reviewCount: 198, color: const Color(0xFFFF4081),
    tagline: 'Premium beauty services',
    phone: '0321-7654321',
    items: const [
      BusinessItem(id: 'bp2i1', name: 'Party Makeup', description: 'Glam look for events & parties', price: 3500, category: 'Facial', durationMinutes: 90),
      BusinessItem(id: 'bp2i2', name: 'Keratin Treatment', description: 'Smooth & frizz-free hair for 3 months', price: 8000, category: 'Facial', durationMinutes: 180),
      BusinessItem(id: 'bp2i3', name: 'Gel Nails (Full Set)', description: 'Nail extensions with gel polish', price: 2500, category: 'Nails', durationMinutes: 90),
    ],
  ),

  // ── FLOWER SHOP ─────────────────────────────────────────────────────────────
  Business(
    id: 'fl1', businessTypeId: 'flowers', isOpen: true,
    deliveryBaseCharge: 100, deliveryPerKmCharge: 20,
    name: 'Gulzar Flowers', address: 'Zamzama, Karachi',
    rating: 4.6, reviewCount: 87, color: const Color(0xFF8BC34A),
    tagline: 'Fresh flowers, fresh feelings',
    phone: '0333-2345678',
    items: const [
      BusinessItem(id: 'fl1i1', name: 'Red Rose Bouquet (12)', description: '12 fresh red roses with ribbon', price: 800, category: 'Bouquets'),
      BusinessItem(id: 'fl1i2', name: 'Mixed Seasonal Bouquet', description: 'Colorful arrangement with seasonal blooms', price: 1200, category: 'Bouquets'),
      BusinessItem(id: 'fl1i3', name: 'Table Arrangement', description: 'Decorative flower arrangement for table', price: 2000, category: 'Arrangements'),
      BusinessItem(id: 'fl1i4', name: 'Wedding Decoration Package', description: 'Full venue + car decoration', price: 15000, category: 'Arrangements'),
      BusinessItem(id: 'fl1i5', name: 'Money Plant (Pot)', description: 'Indoor lucky plant with ceramic pot', price: 450, category: 'Plants'),
      BusinessItem(id: 'fl1i6', name: 'Gift Basket (Flowers + Chocolates)', description: 'Beautiful basket with roses & Ferrero Rocher', price: 2500, category: 'Gift Baskets'),
    ],
  ),

  // ── RENT A CAR ─────────────────────────────────────────────────────────────
  Business(
    id: 'rc1', businessTypeId: 'rentacar', isOpen: true,
    name: 'Pak Rent a Car', address: 'Clifton, Karachi',
    rating: 4.4, reviewCount: 156, color: const Color(0xFF607D8B),
    tagline: 'Drive your journey',
    phone: '0311-4567890',
    items: const [
      BusinessItem(id: 'rc1i1', name: 'Suzuki Mehran', description: 'Economy car, fuel efficient', price: 2500, category: 'Economy', unit: 'per day'),
      BusinessItem(id: 'rc1i2', name: 'Toyota Corolla', description: 'Comfortable sedan for city travel', price: 4000, category: 'Sedan', unit: 'per day'),
      BusinessItem(id: 'rc1i3', name: 'Honda Civic', description: 'Premium sedan with AC', price: 5000, category: 'Sedan', unit: 'per day'),
      BusinessItem(id: 'rc1i4', name: 'Toyota Fortuner', description: 'SUV for outstation travel', price: 9000, category: 'SUV', unit: 'per day'),
      BusinessItem(id: 'rc1i5', name: 'Hiace Van (12 seats)', description: 'For group travel & events', price: 8000, category: 'Van', unit: 'per day'),
      BusinessItem(id: 'rc1i6', name: 'City Ride (With Driver)', description: 'In-city ride with driver — anywhere within city limits', price: 1200, category: 'With Driver', unit: 'per hour'),
      BusinessItem(id: 'rc1i7', name: 'Airport Transfer', description: 'Pick & drop from airport (city)', price: 2000, category: 'With Driver', unit: 'per trip'),
    ],
  ),
  Business(
    id: 'rc2', businessTypeId: 'rentacar', isOpen: true,
    name: 'Travel Ease Autos', address: 'Gulberg, Lahore',
    rating: 4.2, reviewCount: 93, color: const Color(0xFF607D8B),
    tagline: 'Outstation & city tours',
    phone: '0345-6789012',
    items: const [
      BusinessItem(id: 'rc2i1', name: 'Corolla Self Drive', description: '2020 model, full insurance', price: 4500, category: 'Self Drive', unit: 'per day'),
      BusinessItem(id: 'rc2i2', name: 'City Ride (With Driver)', description: 'In-city ride with driver — anywhere within city limits', price: 1200, category: 'With Driver', unit: 'per hour'),
      BusinessItem(id: 'rc2i3', name: 'Islamabad Trip', description: 'LHR to ISB one way with driver', price: 12000, category: 'With Driver', unit: 'per trip'),
    ],
  ),

  // ── AUTO WORKSHOP (MECHANIC) ────────────────────────────────────────────────
  Business(
    id: 'mec1', businessTypeId: 'mechanic', isOpen: true,
    name: 'Ali Auto Workshop', address: 'Liaquatabad, Karachi',
    rating: 4.5, reviewCount: 234, color: const Color(0xFF455A64),
    tagline: 'Car & bike experts',
    phone: '0300-1234567',
    items: const [
      BusinessItem(id: 'mec1i1', name: 'Car Engine Service', description: 'Oil change + filter + checkup', price: 2500, category: 'Car Repair', durationMinutes: 60),
      BusinessItem(id: 'mec1i2', name: 'Tyre Puncture (Car)', description: 'On-spot puncture repair', price: 200, category: 'Puncture', durationMinutes: 15),
      BusinessItem(id: 'mec1i3', name: 'Car Battery Replacement', description: 'Osaka / AGS battery with fitting', price: 8000, category: 'Battery', durationMinutes: 30),
      BusinessItem(id: 'mec1i4', name: 'Bike Engine Service', description: 'Honda / Yamaha / CD service', price: 800, category: 'Bike Repair', durationMinutes: 45),
      BusinessItem(id: 'mec1i5', name: 'Tyre Puncture (Bike)', description: 'Tube + tubeless puncture', price: 100, category: 'Puncture', durationMinutes: 10),
      BusinessItem(id: 'mec1i6', name: 'Wheel Alignment', description: 'Full car wheel alignment', price: 1500, category: 'Tyre', durationMinutes: 45),
    ],
  ),
  Business(
    id: 'mec2', businessTypeId: 'mechanic', isOpen: true,
    name: 'Usman Motors', address: 'Johar Town, Lahore',
    rating: 4.3, reviewCount: 167, color: const Color(0xFF455A64),
    tagline: '24/7 roadside assistance',
    phone: '0322-9876543',
    items: const [
      BusinessItem(id: 'mec2i1', name: 'AC Gas Refill', description: 'Car AC gas recharge', price: 3500, category: 'Car Repair', durationMinutes: 45),
      BusinessItem(id: 'mec2i2', name: 'Brake Service', description: 'Brake pads + oil flush', price: 3000, category: 'Car Repair', durationMinutes: 60),
      BusinessItem(id: 'mec2i3', name: 'Mobile Puncture (Doorstep)', description: 'We come to you', price: 400, category: 'Puncture', durationMinutes: 20),
    ],
  ),

  // ── HOME SERVICES ──────────────────────────────────────────────────────────
  Business(
    id: 'hs1', businessTypeId: 'homeservice', isOpen: true,
    name: 'Hassan Electric Works', address: 'North Nazimabad, Karachi',
    rating: 4.6, reviewCount: 189, color: const Color(0xFF5C6BC0),
    tagline: 'Licensed electrician available 24/7',
    phone: '0333-5678901',
    items: const [
      BusinessItem(id: 'hs1i1', name: 'Wiring Repair', description: 'Fault finding + wiring fix', price: 1000, category: 'Electrician', durationMinutes: 60),
      BusinessItem(id: 'hs1i2', name: 'MCB / Circuit Breaker', description: 'Replacement with new MCB', price: 800, category: 'Electrician', durationMinutes: 30),
      BusinessItem(id: 'hs1i3', name: 'AC Installation', description: 'Split AC install with bracket', price: 2500, category: 'AC Repair', durationMinutes: 120),
      BusinessItem(id: 'hs1i4', name: 'Fan Installation', description: 'Ceiling fan wiring + install', price: 600, category: 'Electrician', durationMinutes: 30),
    ],
  ),
  Business(
    id: 'hs2', businessTypeId: 'homeservice', isOpen: true,
    name: 'Rehman Plumbing & Gas', address: 'Gulberg, Lahore',
    rating: 4.4, reviewCount: 143, color: const Color(0xFF5C6BC0),
    tagline: 'Pipes, leaks & gas experts',
    phone: '0300-8765432',
    items: const [
      BusinessItem(id: 'hs2i1', name: 'Tap / Faucet Repair', description: 'Leaking tap fix or replacement', price: 500, category: 'Plumber', durationMinutes: 30),
      BusinessItem(id: 'hs2i2', name: 'Pipe Leakage Repair', description: 'Underground / wall pipe repair', price: 1500, category: 'Plumber', durationMinutes: 90),
      BusinessItem(id: 'hs2i3', name: 'Geyser Installation', description: 'New geyser with gas fitting', price: 1500, category: 'Plumber', durationMinutes: 60),
      BusinessItem(id: 'hs2i4', name: 'Lock Change', description: 'New lock fitting, any door', price: 800, category: 'Locksmith', durationMinutes: 30),
      BusinessItem(id: 'hs2i5', name: 'Lock Opening (Emergency)', description: 'Locked out of house / car', price: 500, category: 'Locksmith', durationMinutes: 20),
    ],
  ),
  Business(
    id: 'hs3', businessTypeId: 'homeservice', isOpen: false,
    name: 'Quick Fix Home Care', address: 'F-10, Islamabad',
    rating: 4.5, reviewCount: 98, color: const Color(0xFF5C6BC0),
    tagline: 'All home repair solutions',
    phone: '0311-2345670',
    items: const [
      BusinessItem(id: 'hs3i1', name: 'Wall Painting (per room)', description: 'Labour + paint included', price: 8000, category: 'Painter', durationMinutes: 480),
      BusinessItem(id: 'hs3i2', name: 'Carpenter (Door / Window)', description: 'Repair or new fitting', price: 2000, category: 'Carpenter', durationMinutes: 120),
      BusinessItem(id: 'hs3i3', name: 'AC Servicing (Split)', description: 'Full clean + gas check + drain', price: 2000, category: 'AC Repair', durationMinutes: 90),
    ],
  ),

  // ── PET CARE ────────────────────────────────────────────────────────────────
  Business(
    id: 'pet1', businessTypeId: 'petcare', isOpen: true,
    name: 'Paws & Care Vet Clinic', address: 'Defence Phase 6, Karachi',
    rating: 4.8, reviewCount: 204, color: const Color(0xFFFF7043),
    tagline: 'Your pet\'s second home',
    phone: '0321-3456789',
    items: const [
      BusinessItem(id: 'pet1i1', name: 'Vet Consultation', description: 'Full checkup with treatment advice', price: 800, category: 'Vet Consultation', durationMinutes: 30),
      BusinessItem(id: 'pet1i2', name: 'Dog/Cat Grooming', description: 'Bath + haircut + nail clip', price: 1500, category: 'Grooming', durationMinutes: 90),
      BusinessItem(id: 'pet1i3', name: 'Rabies Vaccination', description: 'Annual anti-rabies vaccine', price: 1200, category: 'Vaccination', durationMinutes: 15),
      BusinessItem(id: 'pet1i4', name: 'Pet Boarding (per night)', description: 'Safe & comfortable boarding', price: 1000, category: 'Boarding', unit: 'per night'),
      BusinessItem(id: 'pet1i5', name: 'Emergency Consultation', description: '24/7 emergency vet service', price: 1500, category: 'Emergency', durationMinutes: 30),
    ],
  ),
  Business(
    id: 'pet2', businessTypeId: 'petcare', isOpen: true,
    name: 'Animal Care Hospital', address: 'Gulberg III, Lahore',
    rating: 4.6, reviewCount: 156, color: const Color(0xFFFF7043),
    tagline: 'Advanced pet healthcare',
    phone: '0300-7654321',
    items: const [
      BusinessItem(id: 'pet2i1', name: 'X-Ray (Pet)', description: 'Digital X-ray for dogs/cats', price: 2000, category: 'Vet Consultation', durationMinutes: 20),
      BusinessItem(id: 'pet2i2', name: 'Spay / Neuter', description: 'Surgical procedure with anesthesia', price: 8000, category: 'Emergency', durationMinutes: 120),
      BusinessItem(id: 'pet2i3', name: 'Puppy Vaccination Pack', description: '5-in-1 + deworming package', price: 2500, category: 'Vaccination', durationMinutes: 30),
    ],
  ),
];

// Filter by business type
List<Business> businessesByType(String typeId) =>
    typeId == 'all'
        ? allDummyBusinesses
        : allDummyBusinesses.where((b) => b.businessTypeId == typeId).toList();
