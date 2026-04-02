/// Structured grocery aisles for owner + customer flows & AI-friendly hints.
abstract final class GroceryCategories {
  GroceryCategories._();

  /// Main aisle names — use as [Product.category] / [BusinessItem.category].
  static const List<String> aisleNames = [
    'Oil & Ghee',
    'Staples (Basic Food)',
    'Spices & Sauces',
    'Packaged & Ready Food',
    'Snacks & Bakery',
    'Dairy & Drinks',
    'Fresh Items',
    'Frozen Food',
    'Cleaning Products',
    'Personal Care',
    'Baby Products',
    'Miscellaneous',
  ];

  static final Set<String> aisleNamesSet = aisleNames.toSet();

  /// Typical SKUs per aisle (suggestions for add-product & image library).
  static const Map<String, List<String>> suggestedItemsByAisle = {
    'Oil & Ghee': [
      'Cooking Oil',
      'Banaspati Ghee',
      'Desi Ghee',
      'Olive Oil',
      'Canola Oil',
      'Sunflower Oil',
      'Corn Oil',
    ],
    'Staples (Basic Food)': [
      'Atta (Wheat Flour)',
      'Rice (Basmati, Sella)',
      'Masoor Daal',
      'Moong Daal',
      'Chana Daal',
      'Mash Daal',
      'Gram (Chana)',
      'Besan',
    ],
    'Spices & Sauces': [
      'Spices (Haldi, Mirch, Dhaniya)',
      'Garam Masala',
      'Salt',
      'Sugar',
      'Ketchup',
      'Chili Sauce',
      'Soy Sauce',
      'Pickles (Achaar)',
      'Vinegar',
    ],
    'Packaged & Ready Food': [
      'Instant Noodles',
      'Canned Food',
      'Ready-to-Eat Meals',
      'Jams & Spreads',
    ],
    'Snacks & Bakery': [
      'Biscuits',
      'Chips',
      'Nimko',
      'Bread',
      'Rusk',
      'Cakes',
    ],
    'Dairy & Drinks': [
      'Milk',
      'Yogurt (Dahi)',
      'Butter',
      'Cheese',
      'Cream',
      'Tea',
      'Coffee',
      'Juices',
      'Soft Drinks',
      'Mineral Water',
    ],
    'Fresh Items': [
      'Vegetables',
      'Fruits',
      'Chicken',
      'Meat',
    ],
    'Frozen Food': [
      'Frozen Paratha',
      'Nuggets',
      'Frozen Vegetables',
      'Ice Cream',
    ],
    'Cleaning Products': [
      'Laundry Detergent',
      'Dishwashing Liquid',
      'Floor Cleaner (Phenyl)',
      'Toilet Cleaner',
      'Tissue / Paper',
    ],
    'Personal Care': [
      'Soap',
      'Shampoo',
      'Toothpaste',
      'Hair Oil',
      'Lotion',
    ],
    'Baby Products': [
      'Diapers',
      'Baby Food',
      'Baby Wipes',
    ],
    'Miscellaneous': [
      'Matches',
      'Batteries',
      'Plastic Bags',
      'Stationery',
    ],
  };

  /// Flat list for quick-pick chips (add product, etc.).
  static List<String> get allSuggestedProductNames {
    final out = <String>[];
    for (final list in suggestedItemsByAisle.values) {
      out.addAll(list);
    }
    return out;
  }
}
