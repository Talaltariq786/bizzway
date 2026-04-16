import 'package:flutter/material.dart';
import '../models/business_type.dart';
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
  final String? imageUrl;
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
    this.imageUrl,
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

  /// From `GET /api/businesses` row (menu items loaded separately).
  factory Business.fromPublicApi(
    Map<String, dynamic> m, {
    List<BusinessItem> items = const [],
  }) {
    final typeId = (m['type'] ?? '').toString().trim();
    BusinessType? match;
    for (final t in BusinessType.all) {
      if (t.id == typeId) {
        match = t;
        break;
      }
    }
    final safeType = typeId.isEmpty ? 'others' : typeId;
    return Business(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Shop').toString(),
      address: (m['address'] ?? '').toString(),
      rating: 0,
      reviewCount: 0,
      businessTypeId: safeType,
      isOpen: true,
      items: items,
      color: match?.color ?? const Color(0xFF6C63FF),
      tagline: null,
      phone: null,
      imageUrl: null,
      deliveryBaseCharge: null,
      deliveryPerKmCharge: null,
      deliveryRadiusKm: null,
    );
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

  /// Rent-a-car / owner sync (optional for other business types).
  final String? customerFullName;
  final String? customerNic;
  final String? customerLicenseNo;
  final String? bookingCode;
  final String? vehicleHandoverMode;
  final String? rentacarTripType;
  final String? pickupAddress;
  final String? dropoffAddress;

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
    this.customerFullName,
    this.customerNic,
    this.customerLicenseNo,
    this.bookingCode,
    this.vehicleHandoverMode,
    this.rentacarTripType,
    this.pickupAddress,
    this.dropoffAddress,
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
      customerFullName: json['customerFullName']?.toString(),
      customerNic: json['customerNic']?.toString(),
      customerLicenseNo: json['customerLicenseNo']?.toString(),
      bookingCode: json['bookingCode']?.toString(),
      vehicleHandoverMode: json['vehicleHandoverMode']?.toString(),
      rentacarTripType: json['rentacarTripType']?.toString(),
      pickupAddress: json['pickupAddress']?.toString(),
      dropoffAddress: json['dropoffAddress']?.toString(),
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
      'customerFullName': customerFullName,
      'customerNic': customerNic,
      'customerLicenseNo': customerLicenseNo,
      'bookingCode': bookingCode,
      'vehicleHandoverMode': vehicleHandoverMode,
      'rentacarTripType': rentacarTripType,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
    };
  }

  CustomerBooking copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? businessTypeId,
    String? itemId,
    String? itemName,
    double? price,
    int? durationMinutes,
    DateTime? dateTime,
    String? status,
    String? notes,
    String? customerFullName,
    String? customerNic,
    String? customerLicenseNo,
    String? bookingCode,
    String? vehicleHandoverMode,
    String? rentacarTripType,
    String? pickupAddress,
    String? dropoffAddress,
  }) {
    return CustomerBooking(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      customerFullName: customerFullName ?? this.customerFullName,
      customerNic: customerNic ?? this.customerNic,
      customerLicenseNo: customerLicenseNo ?? this.customerLicenseNo,
      bookingCode: bookingCode ?? this.bookingCode,
      vehicleHandoverMode: vehicleHandoverMode ?? this.vehicleHandoverMode,
      rentacarTripType: rentacarTripType ?? this.rentacarTripType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
    );
  }

  String get actionLabel {
    switch (businessTypeId) {
      case 'restaurant':
      case 'cafe':    return 'Reservation';
      case 'gym':     return 'Session';
      case 'grocery':
      case 'pharmacy':return 'Order';
      case 'rentacar':
        return 'Booking';
      default:        return 'Appointment';
    }
  }
}


/// Deprecated: browse via API (`CustomerMarketplaceProvider`).
final List<Business> allDummyBusinesses = [
  // Restaurant
  const Business(
    id: 'demo_rest_1',
    name: 'Karachi Kitchen',
    address: 'Clifton, Karachi',
    rating: 4.6,
    reviewCount: 128,
    businessTypeId: 'restaurant',
    isOpen: true,
    color: Color(0xFFE91E63),
    tagline: 'Fresh food • Fast delivery',
    deliveryRadiusKm: 5,
    items: [
      BusinessItem(
        id: 'demo_food_1',
        name: 'Chicken Biryani',
        description: 'Spicy, aromatic, single plate',
        price: 450,
        category: 'Food',
      ),
      BusinessItem(
        id: 'demo_food_2',
        name: 'Mint Margarita',
        description: 'Chilled drink',
        price: 180,
        category: 'Drinks',
      ),
    ],
  ),

  // Grocery
  const Business(
    id: 'demo_groc_1',
    name: 'Fresh Mart',
    address: 'DHA Phase 5, Karachi',
    rating: 4.4,
    reviewCount: 92,
    businessTypeId: 'grocery',
    isOpen: true,
    color: Color(0xFF43A047),
    deliveryRadiusKm: 5,
    items: [
      BusinessItem(
        id: 'demo_g_1',
        name: 'Milk 1L',
        description: 'Dairy milk',
        price: 260,
        category: 'Dairy',
        unit: 'per pack',
      ),
      BusinessItem(
        id: 'demo_g_2',
        name: 'Eggs (Dozen)',
        description: 'Farm eggs',
        price: 420,
        category: 'Dairy',
        unit: 'per dozen',
      ),
    ],
  ),

  // Rent a car
  const Business(
    id: 'demo_rent_1',
    name: 'City Rent A Car',
    address: 'PECHS, Karachi',
    rating: 4.7,
    reviewCount: 56,
    businessTypeId: 'rentacar',
    isOpen: true,
    color: Color(0xFF3F51B5),
    items: [
      BusinessItem(
        id: 'demo_car_1',
        name: 'Toyota Corolla',
        description: 'AC • Clean • Driver optional',
        price: 6500,
        category: 'Cars',
        unit: 'per day',
      ),
    ],
  ),
];

// Filter by business type
List<Business> businessesByType(String typeId) =>
    typeId == 'all'
        ? allDummyBusinesses
        : allDummyBusinesses.where((b) => b.businessTypeId == typeId).toList();
