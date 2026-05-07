/// Grocery / general store "quick setup" catalog for Pakistan shops.
///
/// Use this to bulk-add common categories + items so small shop owners can
/// start listing fast on mobile (no laptop).
library;

abstract final class GroceryQuickSetupCatalog {
  GroceryQuickSetupCatalog._();

  /// Category → item names.
  static const Map<String, List<String>> categories = {
    'Basic Rashan (Staples)': [
      'Atta',
      'Maida',
      'Besan',
      'Chawal (Basmati)',
      'Chawal (Sella)',
      'Chawal (Toota)',
      'Cheeni',
      'Namak',
      'Daal (Masoor)',
      'Daal (Moong)',
      'Daal (Mash)',
      'Daal (Chana)',
      'Safaid chana',
      'Kala chana',
      'Sewaiyan',
    ],
    'Masalay (Spices)': [
      'Lal mirch powder',
      'Haldi powder',
      'Dhaniya powder',
      'Zeera',
      'Kali mirch',
      'Garam masala',
      'Chaat masala',
      'Biryani masala',
      'Qorma masala',
      'Nihari masala',
      'Achar masala',
    ],
    'Oil & Ghee': [
      'Cooking oil (soybean)',
      'Cooking oil (canola)',
      'Banaspati ghee',
      'Olive oil',
    ],
    'Instant & Fast Food': [
      'Noodles',
      'Pasta / spaghetti',
      'Instant soup',
      'Oats',
    ],
    'Canned & Packed Food': [
      'Tomato paste',
      'Canned beans',
      'Canned matar',
      'Canned fruit',
      'Packed food items',
    ],
    'Sweet Items & Spreads': [
      'Shehad (honey)',
      'Jam',
      'Jelly',
      'Peanut butter',
      'Chocolate spread',
    ],
    'Biscuits & Snacks': [
      'Biscuits (Marie)',
      'Biscuits (cream)',
      'Wafers',
      'Chips',
      'Nimko / namkeen',
      'Popcorn',
      'Chocolates',
      'Toffees',
    ],
    'Drinks (Beverages)': [
      'Chai',
      'Coffee',
      'Doodh (milk packs)',
      'Juice',
      'Soft drinks',
      'Mineral water',
      'Sharbat',
    ],
    'Dairy Items': [
      'Dahi',
      'Makhan (butter)',
      'Cream',
      'Paneer',
    ],
    'Bakery Items': [
      'Bread',
      'Bun',
      'Rusk',
      'Cake',
      'Bakery biscuits',
    ],
    'Dry Fruits & Nuts': [
      'Badam',
      'Kaju',
      'Kishmish',
      'Pista',
      'Akhrot',
      'Moong phali',
    ],
    'Cleaning Items': [
      'Washing powder',
      'Kapray dhonay ka sabun',
      'Dish wash liquid',
      'Dish wash bar',
      'Phenyl',
      'Bleach',
      'Glass cleaner',
      'Jhaaru',
      'Pocha',
    ],
    'Personal Care': [
      'Nahane ka sabun',
      'Shampoo',
      'Hair oil',
      'Toothpaste',
      'Toothbrush',
      'Face wash',
      'Shaving cream / razor',
      'Dettol / sanitizer',
    ],
    'Paper & Plastic': [
      'Tissue paper',
      'Toilet paper',
      'Kitchen roll',
      'Aluminium foil',
      'Cling wrap',
      'Plastic bags',
    ],
    'General Items (Misc)': [
      'Match box',
      'Lighter',
      'Battery',
      'Mobile load / easy load',
      'Chewing gum',
    ],
    'Fresh Items (Optional)': [
      'Anday',
      'Sabzi',
      'Phal',
      'Fresh doodh',
    ],
  };
}

