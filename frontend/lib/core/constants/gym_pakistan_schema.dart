import 'dart:convert';

/// Pakistan-market gym system — catalog + JSON export for AI / backend.
/// No session reschedule: admission → ticket → pay at gym → owner accepts → membership active.
abstract final class GymPakistanSchema {
  GymPakistanSchema._();

  static const String version = '1.0';

  /// Membership & entry models offered in PK gyms.
  static const List<Map<String, dynamic>> membershipModels = [
    {
      'id': 'monthly',
      'label': 'Monthly Membership',
      'labelUr': 'ماہانہ ممبرشپ',
      'commonInPk': true,
      'typicalDurationDays': 30,
    },
    {
      'id': 'quarterly',
      'label': 'Quarterly Membership (3 months)',
      'labelUr': 'سہ ماہی پیکج',
      'commonInPk': true,
      'typicalDurationDays': 90,
    },
    {
      'id': 'yearly',
      'label': 'Yearly Membership',
      'labelUr': 'سالانہ ممبرشپ',
      'commonInPk': true,
      'typicalDurationDays': 365,
    },
    {
      'id': 'weekly',
      'label': 'Weekly Membership',
      'labelUr': 'ہفتہ وار',
      'commonInPk': false,
      'typicalDurationDays': 7,
    },
    {
      'id': 'per_session',
      'label': 'Per Session Entry',
      'labelUr': 'فی سیشن',
      'commonInPk': false,
      'typicalDurationDays': 0,
    },
    {
      'id': 'per_day',
      'label': 'Per Day Entry',
      'labelUr': 'فی دن داخلہ',
      'commonInPk': false,
      'typicalDurationDays': 1,
    },
    {
      'id': 'personal_training',
      'label': 'Personal Training Package',
      'labelUr': 'ذاتی ٹریننگ',
      'commonInPk': true,
      'separateCharges': true,
    },
  ];

  static const List<Map<String, dynamic>> gymServices = [
    {'id': 'general_access', 'label': 'General Gym Access'},
    {'id': 'personal_training', 'label': 'Personal Training'},
    {'id': 'cardio', 'label': 'Cardio Section'},
    {'id': 'weights', 'label': 'Weight Training Section'},
    {'id': 'group_classes', 'label': 'Group Classes'},
  ];

  static const List<Map<String, dynamic>> paymentMethods = [
    {'id': 'cash', 'label': 'Cash at gym', 'labelUr': 'نقد ادائیگی جم میں'},
    {'id': 'pending_until_cash', 'label': 'Pending until paid at gym'},
  ];

  /// Default sellable packages (demo fees in PKR).
  static const List<Map<String, dynamic>> defaultPackages = [
    {
      'id': 'pkg_monthly_std',
      'modelId': 'monthly',
      'name': 'Monthly Standard',
      'feePkr': 4500,
      'durationDays': 30,
      'includes': ['general_access', 'cardio', 'weights'],
      'trainerOptional': true,
    },
    {
      'id': 'pkg_quarterly',
      'modelId': 'quarterly',
      'name': '3 Months Save Deal',
      'feePkr': 12000,
      'durationDays': 90,
      'includes': ['general_access', 'cardio', 'weights', 'group_classes'],
      'trainerOptional': true,
    },
    {
      'id': 'pkg_yearly',
      'modelId': 'yearly',
      'name': 'Yearly Gold',
      'feePkr': 42000,
      'durationDays': 365,
      'includes': ['general_access', 'cardio', 'weights', 'group_classes'],
      'trainerOptional': true,
    },
    {
      'id': 'pkg_weekly',
      'modelId': 'weekly',
      'name': 'Weekly Trial',
      'feePkr': 1500,
      'durationDays': 7,
      'includes': ['general_access', 'cardio', 'weights'],
      'trainerOptional': false,
    },
    {
      'id': 'pkg_day_pass',
      'modelId': 'per_day',
      'name': 'Single Day Pass',
      'feePkr': 500,
      'durationDays': 1,
      'includes': ['general_access', 'cardio', 'weights'],
      'trainerOptional': false,
    },
    {
      'id': 'pkg_session_8',
      'modelId': 'per_session',
      'name': '8 Sessions Pack',
      'feePkr': 6400,
      'sessionCount': 8,
      'durationDays': 0,
      'includes': ['general_access', 'cardio', 'weights'],
      'trainerOptional': false,
    },
    {
      'id': 'pkg_pt_12',
      'modelId': 'personal_training',
      'name': 'PT — 12 Sessions',
      'feePkr': 18000,
      'sessionCount': 12,
      'durationDays': 90,
      'includes': ['personal_training', 'general_access', 'weights'],
      'trainerOptional': false,
    },
  ];

  /// In-gym supplement shop (داخل gym shop).
  static const List<Map<String, dynamic>> supplementCategories = [
    {
      'id': 'protein',
      'label': 'Protein Supplements',
      'items': ['Whey Protein', 'Mass Gainer', 'Isolate Protein'],
    },
    {
      'id': 'pre_post',
      'label': 'Pre / Post Workout',
      'items': ['Pre-workout', 'BCAA', 'Creatine'],
    },
    {
      'id': 'health',
      'label': 'Health Supplements',
      'items': ['Multivitamins', 'Fish Oil', 'Fat Burners'],
    },
    {
      'id': 'accessories',
      'label': 'Accessories',
      'items': ['Shaker Bottles', 'Gym Gloves', 'Lifting Belts'],
    },
  ];

  /// Demo stock (name, brand, price PKR, qty).
  static const List<Map<String, dynamic>> defaultSupplementProducts = [
    {'categoryId': 'protein', 'name': 'Gold Standard Whey', 'brand': 'Optimum Nutrition', 'pricePkr': 18500, 'stock': 12},
    {'categoryId': 'protein', 'name': 'Serious Mass', 'brand': 'Optimum Nutrition', 'pricePkr': 14200, 'stock': 8},
    {'categoryId': 'protein', 'name': 'ISO HD', 'brand': 'BPI Sports', 'pricePkr': 16500, 'stock': 6},
    {'categoryId': 'pre_post', 'name': 'C4 Original', 'brand': 'Cellucor', 'pricePkr': 8500, 'stock': 15},
    {'categoryId': 'pre_post', 'name': 'BCAA Energy', 'brand': 'EVL', 'pricePkr': 6200, 'stock': 20},
    {'categoryId': 'pre_post', 'name': 'Micronized Creatine', 'brand': 'Optimum Nutrition', 'pricePkr': 4500, 'stock': 25},
    {'categoryId': 'health', 'name': 'Men Multivitamin', 'brand': 'GNC', 'pricePkr': 5200, 'stock': 18},
    {'categoryId': 'health', 'name': 'Omega-3 Fish Oil', 'brand': 'NOW', 'pricePkr': 4800, 'stock': 14},
    {'categoryId': 'health', 'name': 'Fat Burner', 'brand': 'MuscleTech', 'pricePkr': 9200, 'stock': 5},
    {'categoryId': 'accessories', 'name': 'Shaker 700ml', 'brand': 'Generic', 'pricePkr': 800, 'stock': 40},
    {'categoryId': 'accessories', 'name': 'Gym Gloves', 'brand': 'Harbinger', 'pricePkr': 2200, 'stock': 22},
    {'categoryId': 'accessories', 'name': 'Leather Lifting Belt', 'brand': 'RDX', 'pricePkr': 4500, 'stock': 10},
  ];

  /// Full schema as JSON string (for export / AI).
  static String toJsonString() {
    final map = {
      'version': version,
      'membershipModels': membershipModels,
      'gymServices': gymServices,
      'paymentMethods': paymentMethods,
      'defaultPackages': defaultPackages,
      'supplementCategories': supplementCategories,
      'defaultSupplementProducts': defaultSupplementProducts,
      'optionalFeatures': {
        'discountPackages': true,
        'trainerCommission': true,
        'productSalesTracking': true,
        'attendanceTracking': true,
      },
    };
    return JsonEncoder.withIndent('  ').convert(map);
  }
}
