class Product {
  final String id;
  final String businessTypeId;
  String name;
  String description;
  double price;
  String category;
  String imageUrl;
  bool isAvailable;
  final DateTime createdAt;

  // Type-specific fields
  double discountPercent; // restaurant/cafe deals (0 = no discount)
  int? durationMinutes;   // salon/clinic sessions (minutes) | gym classes
  String? unit;           // grocery/pharmacy unit | gym: package duration ('1 Month','3 Months',etc.)
  bool? withTrainer;      // gym memberships only
  /// Pharmacy: cart must reach this amount (Rs.) for [discountPercent] to apply.
  double? minOrderForDiscount;
  bool isRamzanSpecial;   // Ramzan-specific package/offer
  bool isValentinesSpecial;   // Valentine's Day special offer
  final List<String> bundleItems; // combo/package contents (names)

  Product({
    required this.id,
    required this.businessTypeId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.isAvailable = true,
    this.discountPercent = 0,
    this.durationMinutes,
    this.unit,
    this.withTrainer,
    this.minOrderForDiscount,
    this.isRamzanSpecial = false,
    this.isValentinesSpecial = false,
    this.bundleItems = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get discountedPrice =>
      discountPercent > 0 ? price * (1 - discountPercent / 100) : price;

  bool get hasDiscount => discountPercent > 0;

  bool get isBundle => bundleItems.isNotEmpty;

  Product copyWith({
    String? businessTypeId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    double? discountPercent,
    int? durationMinutes,
    String? unit,
    bool? withTrainer,
    double? minOrderForDiscount,
    bool? isRamzanSpecial,
    bool? isValentinesSpecial,
    List<String>? bundleItems,
  }) {
    return Product(
      id: id,
      businessTypeId: businessTypeId ?? this.businessTypeId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      discountPercent: discountPercent ?? this.discountPercent,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      unit: unit ?? this.unit,
      withTrainer: withTrainer ?? this.withTrainer,
      minOrderForDiscount: minOrderForDiscount ?? this.minOrderForDiscount,
      isRamzanSpecial: isRamzanSpecial ?? this.isRamzanSpecial,
      isValentinesSpecial: isValentinesSpecial ?? this.isValentinesSpecial,
      bundleItems: bundleItems ?? this.bundleItems,
      createdAt: createdAt,
    );
  }
}
