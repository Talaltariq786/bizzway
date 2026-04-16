/// Suggested names for [ProductImageLibraryScreen]: top tabs + optional **sub-tabs**
/// (e.g. Burgers → Chicken / Beef / Fish) with Pakistan-style wording.
library product_image_library_catalog;

abstract final class ProductImageLibraryCatalog {
  ProductImageLibraryCatalog._();

  static List<String> categoriesFor(String bizId) {
    if (bizId == 'restaurant' || bizId == 'cafe') {
      return const [
        'Biryani & Rice',
        'Nihari & Haleem',
        'Karahi & Korma',
        'BBQ & Tikka',
        'Burgers & Broast',
        'Pizza',
        'Rolls & Paratha',
        'Snacks & Sides',
        'Drinks',
        'Desserts',
      ];
    }
    if (bizId == 'grocery' || bizId == 'pharmacy' || bizId == 'others') {
      return const [
        'Oil',
        'Ghee',
        'Rice',
        'Daal',
        'Flour',
        'Milk',
        'Cold drinks & Juice',
        'Tea',
        'Spices',
        'Sugar',
      ];
    }
    if (bizId == 'salon' || bizId == 'beauty') {
      return const [
        'Haircut',
        'Beard',
        'Facial',
        'Wax',
        'Mani/Pedi',
        'Makeup',
      ];
    }
    if (bizId == 'rentacar') {
      return const [
        'Sedan',
        'SUV',
        'Hatchback',
        'Van',
        'Luxury',
      ];
    }
    if (bizId == 'clinic') {
      return const [
        'Consultation',
        'Lab',
        'Medicines',
      ];
    }
    if (bizId == 'gym') {
      return const [
        'Membership',
        'Personal Training',
        'Class',
        'Diet Plan',
      ];
    }
    if (bizId == 'mechanic') {
      return const [
        'Puncture',
        'Battery',
        'Oil Change',
        'Towing',
      ];
    }
    if (bizId == 'homeservice') {
      return const [
        'Electrician',
        'Plumber',
        'Carpenter',
        'Painter',
        'AC',
      ];
    }
    return const ['General'];
  }

  /// Category → sub-tab → product names. If a category is missing here,
  /// [flatSuggestions] is used instead.
  static Map<String, Map<String, List<String>>> nestedFor(String bizId) {
    if (bizId == 'restaurant' || bizId == 'cafe') {
      return _restaurantNested;
    }
    if (bizId == 'grocery' || bizId == 'pharmacy' || bizId == 'others') {
      return _groceryNested;
    }
    if (bizId == 'rentacar') {
      return _rentacarNested;
    }
    return const {};
  }

  /// Flat list when a category has no nested map or for simple UIs.
  static Map<String, List<String>> flatFor(String bizId) {
    if (bizId == 'restaurant' || bizId == 'cafe') {
      return const {};
    }
    if (bizId == 'grocery' || bizId == 'pharmacy' || bizId == 'others') {
      return const {};
    }
    if (bizId == 'salon' || bizId == 'beauty') {
      return const {
        'Haircut': ['Haircut', 'Hair Styling'],
        'Beard': ['Beard Trim', 'Shave'],
        'Facial': ['Facial', 'Cleanup'],
        'Wax': ['Wax', 'Threading'],
        'Mani/Pedi': ['Manicure', 'Pedicure'],
        'Makeup': ['Party Makeup', 'Bridal Makeup'],
      };
    }
    if (bizId == 'clinic') {
      return const {
        'Consultation': ['OPD Consult', 'Video Consult'],
        'Lab': ['Blood Test', 'X-Ray'],
        'Medicines': ['Prescription Medicines'],
      };
    }
    if (bizId == 'gym') {
      return const {
        'Membership': ['Monthly Membership', 'Yearly Membership'],
        'Personal Training': ['PT Session'],
        'Class': ['Group Class'],
        'Diet Plan': ['Diet Plan'],
      };
    }
    if (bizId == 'mechanic') {
      return const {
        'Puncture': ['Tire Repair', 'Puncture Fix'],
        'Battery': ['Battery Change', 'Jump Start'],
        'Oil Change': ['Oil Change', 'Filter Change'],
        'Towing': ['Towing', 'Roadside Help'],
      };
    }
    if (bizId == 'homeservice') {
      return const {
        'Electrician': ['Wiring', 'Fan Install'],
        'Plumber': ['Leak Fix', 'Motor Install'],
        'Carpenter': ['Furniture Repair'],
        'Painter': ['Room Paint'],
        'AC': ['AC Service', 'Gas Refill'],
      };
    }
    return const {
      'General': ['Item'],
    };
  }

  /// Restaurant: PK menu — nested by protein / style.
  static const Map<String, Map<String, List<String>>> _restaurantNested = {
    'Biryani & Rice': {
      'Chicken': [
        'Chicken Biryani',
        'Boneless Chicken Biryani',
        'Chicken Tikka Biryani',
      ],
      'Beef': [
        'Beef Biryani',
        'Beef Pulao',
      ],
      'Mutton': [
        'Mutton Biryani',
        'Sindhi Biryani',
      ],
      'Rice': [
        'Plain Rice',
        'Zeera Rice',
        'Sada Chawal',
      ],
    },
    'Nihari & Haleem': {
      'Beef': [
        'Beef Nihari',
        'Nihari Special',
        'Nalli Nihari',
      ],
      'Chicken': [
        'Chicken Nihari',
        'Chicken Haleem',
        'Haleem Plate',
      ],
    },
    'Karahi & Korma': {
      'Chicken': [
        'Chicken Karahi',
        'Chicken Korma',
        'Chicken Achari',
        'White Chicken Karahi',
      ],
      'Mutton': [
        'Mutton Karahi',
        'Mutton Korma',
      ],
      'Beef': [
        'Beef Karahi',
      ],
    },
    'BBQ & Tikka': {
      'Chicken': [
        'Chicken Tikka (Chest)',
        'Chicken Tikka (Leg)',
        'Chicken Malai Tikka',
        'Chicken Boti',
      ],
      'Beef': [
        'Beef Chapli Kabab',
        'Beef Seekh Kabab',
      ],
      'Mixed': [
        'Malai Boti',
        'Seekh Kabab',
        'Gola Kabab',
        'Reshmi Kabab',
      ],
    },
    'Burgers & Broast': {
      'Chicken': [
        'Zinger Burger',
        'Zinger with Cheese',
        'Zinger Double Patty',
        'Chicken Burger Single Patty',
        'Chicken Burger Double Patty',
        'Chicken Burger with Cheese',
        'Crispy Chicken Burger',
        'Mayo Chicken Burger',
      ],
      'Beef': [
        'Beef Burger Single Patty',
        'Beef Burger Double Patty',
        'Beef Cheese Burger',
        'Chapli Burger',
      ],
      'Fish': [
        'Fish Burger',
        'Fish Zinger',
      ],
      'Broast & Wings': [
        'Chicken Broast (Half)',
        'Chicken Broast (Full)',
        'Spicy Fried Chicken (8 pcs)',
        'Hot Wings (6 pcs)',
        'Chicken Nuggets (9 pcs)',
      ],
    },
    'Pizza': {
      'Chicken': [
        'Chicken Tikka Pizza',
        'Chicken Fajita Pizza',
        'BBQ Chicken Pizza',
      ],
      'Beef': [
        'Beef Pepperoni Pizza',
        'Seekh Pizza',
      ],
      'Veg': [
        'Fajita Pizza',
        'Cheese Lovers Pizza',
        'Veggie Pizza',
      ],
    },
    'Rolls & Paratha': {
      'Chicken': [
        'Chicken Mayo Roll',
        'Chicken Tikka Roll',
        'Chicken Malai Boti Roll',
        'Chicken Reshmi Roll',
      ],
      'Beef': [
        'Beef Roll',
        'Beef Seekh Roll',
      ],
      'Chatni & Mayo': [
        'Chatni Roll',
        'Mayo Roll',
        'Green Chutney Roll',
      ],
      'Paratha': [
        'Paratha Roll',
        'Anda Paratha Roll',
        'Cheeni Paratha Roll',
      ],
    },
    'Snacks & Sides': {
      'All': [
        'French Fries (Regular)',
        'Masala Fries',
        'Loaded Fries',
        'Potato Chips',
        'Chicken Popcorn',
      ],
    },
    'Drinks': {
      'Soft drinks': [
        'Cola (500ml)',
        'Cola (1.5L)',
        'Sprite (500ml)',
      ],
      'Juice & Lassi': [
        'Fresh Lime',
        'Mint Margarita',
        'Sweet Lassi',
        'Salty Lassi',
      ],
      'Tea & Doodh': [
        'Doodh Patti',
        'Karak Chai',
        'Elachi Chai',
      ],
    },
    'Desserts': {
      'All': [
        'Kheer',
        'Gulab Jamun',
        'Ice Cream Cup',
      ],
    },
  };

  /// Grocery: PK general store — brands as **text labels** (no logo images).
  static const Map<String, Map<String, List<String>>> _groceryNested = {
    'Oil': {
      'Sunflower / Canola': [
        'Sunflower Oil 1L',
        'Canola Oil 1L',
        'Dalda Cooking Oil (style)',
      ],
      'Olive / Others': [
        'Olive Oil',
        'Corn Oil',
        'Soya Cooking Oil',
      ],
    },
    'Ghee': {
      'All': [
        'Desi Ghee',
        'Banaspati Ghee 1kg',
        'Vegetable Ghee',
      ],
    },
    'Rice': {
      'Basmati': [
        'Basmati Rice 5kg',
        'Sella Rice 5kg',
        'Kernel Basmati (style)',
      ],
      'Steamed / Sella': [
        'Double Bag Rice',
        'Steam Rice 1kg',
      ],
    },
    'Daal': {
      'Masoor / Moong': [
        'Masoor Daal',
        'Moong Daal',
        'Mash Daal',
      ],
      'Chana / Gram': [
        'Chana Daal',
        'Gram (Chana)',
        'Besan',
      ],
    },
    'Flour': {
      'All': [
        'Atta (Wheat Flour) 10kg',
        'Maida',
        'Chakki Aatta',
      ],
    },
    'Milk': {
      'UHT small packs': [
        'UHT milk 250ml',
        'UHT milk 200ml',
        'Flavoured Milk (style)',
      ],
      '1L / Full cream': [
        'Milk 1L (full cream)',
        'Full cream milk 1L (popular brand style)',
        'Milk pack 500ml',
      ],
      'Powder / Whitener': [
        'Milk powder (style)',
        'Tea whitener (liquid)',
      ],
    },
    'Cold drinks & Juice': {
      'Soft drinks': [
        'Cola 500ml',
        'Sprite 500ml',
        'Cola 1.5L',
        'Orange soft drink (style)',
      ],
      'Juice & squash': [
        'Mango juice (style)',
        'Apple juice (style)',
        'Syrup (rose / style)',
        'Shezan juice (style)',
      ],
      'Water': [
        'Mineral water 500ml',
        'Water 1.5L bottle',
      ],
    },
    'Tea': {
      'Black / Dust': [
        'Tea (family pack)',
        'Tapal Tea (style)',
        'Lipton Tea (style)',
      ],
      'Green / Elachi': [
        'Green Tea',
        'Elachi Chai mix',
      ],
    },
    'Spices': {
      'Masalay': [
        'Shan Masala (style)',
        'National Masala (style)',
        'Garam Masala',
      ],
      'Basic': [
        'Spices (Haldi, Mirch, Dhaniya)',
        'Salt',
        'Ketchup',
      ],
    },
    'Sugar': {
      'All': [
        'Sugar 2kg',
        'Brown Sugar',
        'Gurr (Jaggery)',
      ],
    },
  };

  /// Rent-a-car: brand-style tabs + **new / popular models** (text only).
  static const Map<String, Map<String, List<String>>> _rentacarNested = {
    'Sedan': {
      'Toyota': [
        'Corolla (new model)',
        'Yaris',
        'Camry',
      ],
      'Honda': [
        'Civic (new)',
        'City',
        'Accord',
      ],
      'Suzuki': [
        'Ciaz',
        'Swift',
      ],
      'Hyundai / Changan': [
        'Elantra',
        'Sonata',
        'Alsvin',
        'Oshan X7 (style)',
      ],
    },
    'SUV': {
      'Toyota': [
        'Fortuner',
        'Corolla Cross',
      ],
      'Honda': [
        'BR-V',
        'HR-V',
      ],
      'Haval / Kia': [
        'Haval H6',
        'Sportage',
        'Sorento',
      ],
      'Suzuki': [
        'Vitara',
        'XL7',
      ],
    },
    'Hatchback': {
      'Suzuki': [
        'Swift',
        'Cultus',
        'Wagon R',
      ],
      'Toyota': [
        'Yaris Hatchback',
      ],
      'Kia / Hyundai': [
        'Picanto',
        'i10',
      ],
    },
    'Van': {
      'All': [
        'Hiace (style)',
        'Commercial Van',
        'Family Van 7-seat',
      ],
    },
    'Luxury': {
      'All': [
        'Mercedes (style)',
        'BMW (style)',
        'Audi (style)',
        'Land Cruiser (style)',
      ],
    },
  };
}
