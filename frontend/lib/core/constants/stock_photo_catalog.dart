/// Curated food & grocery thumbnails via **Unsplash** CDN
/// (see https://unsplash.com/license — free to use in apps; not scraped from Google Images).
///
/// Labels are Pakistan-style menu / general-store wording. Brand names are descriptive
/// (“popular brand style”) without using trademark logos as images.
library;

abstract final class StockPhotoCatalog {
  StockPhotoCatalog._();

  /// Unsplash photo IDs → stable crop URLs (food / grocery stock).
  /// Picked for **South Asian / home-kitchen** feel (thali, daal–chawal, tandoor,
  /// tawa, masala, bazaar produce) — not generic Western stock-only vibes.
  static const _u = <String, String>{
    // Biryani / rice (desi handi & plates)
    'biryani1':
        'https://images.unsplash.com/photo-1589302168068-964664d93dd0?auto=format&fit=crop&w=800&q=82',
    'biryani2':
        'https://images.unsplash.com/photo-1719239885399-f87d992e0f18?auto=format&fit=crop&w=800&q=82',
    'rice1':
        'https://images.unsplash.com/photo-1610514000782-b205b70fbe71?auto=format&fit=crop&w=800&q=82',
    /// Ghar wala **daal + chawal** (rice, lentils, raita-style sides).
    'daalrice':
        'https://images.unsplash.com/photo-1756821753095-64134f5c0c5c?auto=format&fit=crop&w=800&q=82',
    /// Full **thali** — multiple bowls, feels like dhaba / home feast.
    'thali1':
        'https://images.unsplash.com/photo-1742281257707-0c7f7e5ca9c6?auto=format&fit=crop&w=800&q=82',
    // Karahi / korma / salan (rich meat & chili)
    'curry1':
        'https://images.unsplash.com/photo-1764314108477-f026172e32a9?auto=format&fit=crop&w=800&q=82',
    'curry2':
        'https://images.unsplash.com/photo-1710091691771-96b2e6d17dac?auto=format&fit=crop&w=800&q=82',
    // Nihari-style dark stew / haleem bowl
    'stew1':
        'https://images.unsplash.com/photo-1652545297020-f5e8ad779eb4?auto=format&fit=crop&w=800&q=82',
    // BBQ / grilled — **tandoori + seekh / grill** (desi BBQ)
    'bbq1':
        'https://images.unsplash.com/photo-1775211578178-61f06027adf3?auto=format&fit=crop&w=800&q=82',
    'bbq2':
        'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=800&q=82',
    'wings1':
        'https://images.unsplash.com/photo-1736952332338-44dc07283462?auto=format&fit=crop&w=800&q=82',
    // Burgers / fried — still “fast food” but crisp & appetizing
    'burger1':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=82',
    'burger2':
        'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=82',
    'fried1':
        'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&w=800&q=82',
    'fried2':
        'https://images.unsplash.com/photo-1617692855027-33b14f061079?auto=format&fit=crop&w=800&q=82',
    // Pizza (Western item — keep classic slice)
    'pizza1':
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=82',
    'pizza2':
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?auto=format&fit=crop&w=800&q=82',
    // Rolls / paratha — **tawa & street tray**
    'wrap1':
        'https://images.unsplash.com/photo-1763951719000-661d3d50d763?auto=format&fit=crop&w=800&q=82',
    'wrap2':
        'https://images.unsplash.com/photo-1680456693148-dde2351c4434?auto=format&fit=crop&w=800&q=82',
    // Snacks / fries / chips
    'fries1':
        'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=800&q=82',
    'chips1':
        'https://images.unsplash.com/photo-1566478989037-eec170784df0?auto=format&fit=crop&w=800&q=82',
    'snack1':
        'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&w=800&q=82',
    // Drinks — **soft drink bottles** (also used for restaurant cola picks)
    'drink1':
        'https://images.unsplash.com/photo-1742567365295-727724acf5ef?auto=format&fit=crop&w=800&q=82',
    'drink2':
        'https://images.unsplash.com/photo-1437418747212-8d9707af4928?auto=format&fit=crop&w=800&q=82',
    'lassi1':
        'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=800&q=82',
    // Mithai — **halwai / jalebi** energy
    'sweet1':
        'https://images.unsplash.com/photo-1758910536889-43ce7b3199fd?auto=format&fit=crop&w=800&q=82',
    'sweet2':
        'https://images.unsplash.com/photo-1760263217152-009971f0bccc?auto=format&fit=crop&w=800&q=82',
    // Grocery: milk / dairy
    'milk1':
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=800&q=82',
    'milk2':
        'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=82',
    'dairy1':
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=800&q=82',
    // **Chai** — kulhad / pour (not generic coffee)
    'tea1':
        'https://images.unsplash.com/photo-1761483281417-778013dc0177?auto=format&fit=crop&w=800&q=82',
    'oil1':
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=800&q=82',
    // Chawal / basmati pile (dry)
    'ricebag1':
        'https://images.unsplash.com/photo-1723475158229-894679ca024e?auto=format&fit=crop&w=800&q=82',
    // Masala / haldi-mirch — **bowls & bazaar** (PK general store vibe)
    'spice1':
        'https://images.unsplash.com/photo-1682749398549-952020d7b9ac?auto=format&fit=crop&w=800&q=82',
    /// Spice **bags** on stall — feels like masalay aisle / mix packets.
    'pk_masala_bags':
        'https://images.unsplash.com/photo-1692481641786-89fbd5594146?auto=format&fit=crop&w=800&q=82',
    /// **Masala market** stall — colourful sacks / spice shop.
    'pk_spice_market':
        'https://images.unsplash.com/photo-1750387354022-484120f3dcd0?auto=format&fit=crop&w=800&q=82',
    /// **Soft drinks** — plastic bottles (cold drink cooler vibe).
    'pk_softdrinks':
        'https://images.unsplash.com/photo-1742567365295-727724acf5ef?auto=format&fit=crop&w=800&q=82',
    /// **Store beverage** shelves — juice, bottles, cartons.
    'pk_drinks_shelf':
        'https://images.unsplash.com/photo-1760776140488-32fcfab4066a?auto=format&fit=crop&w=800&q=82',
    /// **Fridge aisle** — chilled drinks display.
    'pk_fridge_drinks':
        'https://images.unsplash.com/photo-1767978076849-d86161daa670?auto=format&fit=crop&w=800&q=82',
    /// **Juice** bottles row — tetra / fruit juice feel.
    'pk_juice':
        'https://images.unsplash.com/photo-1734773557735-8fc50f94b473?auto=format&fit=crop&w=800&q=82',
    /// **Orange / mixed juice** pour — fresh juice look.
    'pk_juice2':
        'https://images.unsplash.com/photo-1694886712783-5eefee63cedc?auto=format&fit=crop&w=800&q=82',
    /// Dairy + drinks **supermarket shelf** (milk cartons nearby).
    'pk_milk_shelf':
        'https://images.unsplash.com/photo-1760273464017-4bb7dfa42d91?auto=format&fit=crop&w=800&q=82',
    'sugar1':
        'https://images.unsplash.com/photo-1581927692308-004b221aee60?auto=format&fit=crop&w=800&q=82',
    'bread1':
        'https://images.unsplash.com/photo-1613292443284-8d10ef9383fe?auto=format&fit=crop&w=800&q=82',
    // Dry **daal** (masoor etc.)
    'lentils1':
        'https://images.unsplash.com/photo-1764573464925-da17a9f796d4?auto=format&fit=crop&w=800&q=82',
    'atta1':
        'https://images.unsplash.com/photo-1760445528974-e6dedad99336?auto=format&fit=crop&w=800&q=82',
    'clean1':
        'https://images.unsplash.com/photo-1583947215259-4e0376d5f8f4?auto=format&fit=crop&w=800&q=82',
    'baby1':
        'https://images.unsplash.com/photo-1515488042361-ee00e0ddd4e4?auto=format&fit=crop&w=800&q=82',
    // Sabzi **bazaar**
    'veg1':
        'https://images.unsplash.com/photo-1768734837464-c5045c6a98c4?auto=format&fit=crop&w=800&q=82',
    'frozen1':
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=82',
    // Rent-a-car (generic licensed stock — not brand logos)
    'car_sedan':
        'https://images.unsplash.com/photo-1583121274602-3e2820c69888?auto=format&fit=crop&w=800&q=82',
    'car_suv':
        'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=800&q=82',
    'car_hatch':
        'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=800&q=82',
    'car_van':
        'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?auto=format&fit=crop&w=800&q=82',
    'car_luxury':
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&q=82',
    // Salon & beauty
    'salon1':
        'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=800&q=82',
    'salon2':
        'https://images.unsplash.com/photo-1503951914875-452162b0e3a1?auto=format&fit=crop&w=800&q=82',
    'facial1':
        'https://images.unsplash.com/photo-1512290923902-8a9b81a236a8?auto=format&fit=crop&w=800&q=82',
    'nail1':
        'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&w=800&q=82',
    'makeup1':
        'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=800&q=82',
    'wax1':
        'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&w=800&q=82',
    // Gym & fitness
    'gym1':
        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=800&q=82',
    'gym2':
        'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=800&q=82',
    'gym3':
        'https://images.unsplash.com/photo-1599058945522-23772669bccc?auto=format&fit=crop&w=800&q=82',
    // Clinic / health (generic, no brand logos)
    'doc1':
        'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=800&q=82',
    'lab1':
        'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=800&q=82',
    'pills1':
        'https://images.unsplash.com/photo-1584308666744-24d5c474e2ff?auto=format&fit=crop&w=800&q=82',
    // Mechanic
    'tire1':
        'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?auto=format&fit=crop&w=800&q=82',
    'battery1':
        'https://images.unsplash.com/photo-1621905251918-48416bd8575a?auto=format&fit=crop&w=800&q=82',
    'wrench1':
        'https://images.unsplash.com/photo-1504222490343-c4fcc94dba60?auto=format&fit=crop&w=800&q=82',
    'tow1':
        'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=800&q=82',
    // Home services
    'home_electric':
        'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=800&q=82',
    'home_plumber':
        'https://images.unsplash.com/photo-1581244277943-cbf7bbaaf9ac?auto=format&fit=crop&w=800&q=82',
    'home_wood':
        'https://images.unsplash.com/photo-1504148455328-c376907d481c?auto=format&fit=crop&w=800&q=82',
    'home_paint':
        'https://images.unsplash.com/photo-1561214115f19b0fa6a90a202584c6a?auto=format&fit=crop&w=800&q=82',
    'home_ac':
        'https://images.unsplash.com/photo-1631545285857-e0f50d49f255?auto=format&fit=crop&w=800&q=82',
  };

  /// Business cover photo suggestions (HD) for Pakistani-style food/grocery.
  ///
  /// Returns **HTTPS URLs** sized for header/cover usage (w=1600).
  static List<String> coverSuggestionsForBusiness(String businessTypeId) {
    final b = businessTypeId.toLowerCase().trim();
    final keys = <String>[
      if (b == 'restaurant' || b == 'cafe') ...[
        'biryani1',
        'thali1',
        'curry1',
        'bbq1',
        'wrap1',
        'lassi1',
      ] else if (b == 'grocery' || b == 'pharmacy' || b == 'others') ...[
        'pk_spice_market',
        'veg1',
        'pk_drinks_shelf',
        'pk_milk_shelf',
        'pk_masala_bags',
      ] else if (b == 'rentacar') ...[
        'car_sedan',
        'car_suv',
        'car_hatch',
      ] else if (b == 'salon' || b == 'beauty') ...[
        'salon1',
        'facial1',
        'nail1',
        'makeup1',
      ] else if (b == 'gym') ...[
        'gym1',
        'gym2',
        'gym3',
      ] else if (b == 'clinic') ...[
        'doc1',
        'lab1',
        'pills1',
      ] else if (b == 'mechanic') ...[
        'tire1',
        'battery1',
        'wrench1',
      ] else if (b == 'homeservice') ...[
        'home_electric',
        'home_plumber',
        'home_paint',
        'home_ac',
      ] else ...[
        // Fallback: still pleasant, non-offensive, general covers.
        'thali1',
        'pk_spice_market',
        'car_sedan',
      ],
    ];

    return keys
        .map((k) => _u[k])
        .whereType<String>()
        .map(_toCoverHd)
        .toSet()
        .toList();
  }

  static String _toCoverHd(String url) {
    // Unsplash URLs in this catalog already include `w=800`. For cover headers,
    // we bump width to 1600 for a sharper look.
    return url.replaceAll(RegExp(r'([?&])w=\d+'), r'$1w=1600');
  }

  /// Normalized label → Unsplash-backed URL for **restaurant / cafe** library items.
  static final Map<String, String> _restaurant = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }

    // Biryani & rice
    a('Chicken Biryani', 'biryani1');
    a('Beef Biryani', 'biryani2');
    a('Mutton Biryani', 'biryani1');
    a('Sindhi Biryani', 'biryani2');
    a('Boneless Biryani', 'biryani1');
    a('Plain Rice', 'rice1');
    a('Zeera Rice', 'rice1');

    // Nihari / haleem
    a('Beef Nihari', 'stew1');
    a('Nihari Special', 'stew1');
    a('Haleem', 'curry2');
    a('Chicken Haleem', 'curry2');

    // Karahi / korma
    a('Chicken Karahi', 'curry1');
    a('Mutton Karahi', 'curry1');
    a('White Karahi', 'curry2');
    a('Chicken Korma', 'curry1');
    a('Mutton Korma', 'curry2');
    a('Chicken Achari', 'curry1');

    // BBQ
    a('Chicken Tikka (Chest)', 'bbq1');
    a('Chicken Tikka (Leg)', 'bbq1');
    a('Malai Boti', 'bbq2');
    a('Seekh Kabab', 'bbq1');
    a('Beef Chapli Kabab', 'bbq2');
    a('Gola Kabab', 'bbq1');
    a('Chicken Malai Tikka', 'bbq2');

    // Burgers / broast / fast
    a('Zinger Burger', 'burger1');
    a('Chicken Burger (Single Patty)', 'burger1');
    a('Chicken Burger (Double Patty)', 'burger2');
    a('Beef Burger', 'burger1');
    a('Anda Shami Burger', 'burger2');
    a('Crispy Chicken Burger', 'burger1');
    a('Chicken Broast (Half)', 'fried1');
    a('Chicken Broast (Full)', 'fried2');
    a('Spicy Fried Chicken (8 pcs)', 'fried1');
    a('Hot Wings (6 pcs)', 'wings1');
    a('Chicken Nuggets (9 pcs)', 'fried2');

    // Pizza
    a('Chicken Tikka Pizza', 'pizza1');
    a('Fajita Pizza', 'pizza2');
    a('Pepperoni Pizza', 'pizza1');
    a('Cheese Lovers Pizza', 'pizza2');

    // Rolls / paratha
    a('Chicken Mayo Roll', 'wrap1');
    a('Tikka Roll', 'wrap2');
    a('Seekh Roll', 'wrap1');
    a('Paratha Roll', 'wrap2');

    // Snacks & sides
    a('French Fries (Regular)', 'fries1');
    a('Masala Fries', 'fries1');
    a('Loaded Fries', 'fries1');
    a('Potato Chips', 'chips1');
    a('Chicken Popcorn', 'snack1');

    // Drinks
    a('Cola (500ml)', 'drink1');
    a('Fresh Lime', 'drink2');
    a('Mint Margarita', 'drink1');
    a('Sweet Lassi', 'lassi1');
    a('Salty Lassi', 'lassi1');

    // Desserts
    a('Kheer', 'sweet1');
    a('Gulab Jamun', 'sweet2');
    a('Ice Cream Cup', 'sweet2');

    // Extra rolls / burgers / pizza (nested library labels)
    a('Fish Burger', 'burger1');
    a('Fish Zinger', 'burger1');
    a('Zinger with Cheese', 'burger2');
    a('Zinger Double Patty', 'burger2');
    a('Chicken Burger with Cheese', 'burger2');
    a('Beef Burger Single Patty', 'burger1');
    a('Beef Burger Double Patty', 'burger2');
    a('Beef Cheese Burger', 'burger2');
    a('Mayo Chicken Burger', 'burger1');
    a('Chicken Malai Boti Roll', 'wrap1');
    a('Chicken Reshmi Roll', 'wrap1');
    a('Beef Roll', 'wrap2');
    a('Chatni Roll', 'wrap1');
    a('Green Chutney Roll', 'wrap1');
    a('Chicken Fajita Pizza', 'pizza2');
    a('BBQ Chicken Pizza', 'pizza1');
    a('Beef Pepperoni Pizza', 'pizza1');
    a('Veggie Pizza', 'pizza2');
    a('Doodh Patti', 'lassi1');
    a('Karak Chai', 'tea1');
    a('Elachi Chai', 'tea1');
    a('Beef Pulao', 'biryani2');
    a('Chicken Tikka Biryani', 'biryani1');
    a('Boneless Chicken Biryani', 'biryani1');
    a('Nalli Nihari', 'stew1');
    a('Haleem Plate', 'curry2');
    a('Beef Karahi', 'curry1');
    a('Reshmi Kabab', 'bbq2');
    a('Sada Chawal', 'rice1');
    a('White Chicken Karahi', 'curry2');
    a('Seekh Pizza', 'pizza1');
    a('Anda Paratha Roll', 'wrap2');
    a('Cheeni Paratha Roll', 'wrap2');
    a('Mayo Roll', 'wrap1');
    a('Cola (1.5L)', 'drink1');
    a('Sprite (500ml)', 'drink1');
    a('Chicken Boti', 'bbq1');
    a('Beef Seekh Kabab', 'bbq1');
    a('Beef Korma', 'curry2');
    a('Achari Roll', 'wrap1');

    return m;
  }();

  /// Normalized label → URL for **grocery** (aisle suggestions + Milk pack style text).
  static final Map<String, String> _grocery = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }

    a('Cooking Oil', 'oil1');
    a('Banaspati Ghee', 'oil1');
    a('Desi Ghee', 'dairy1');
    a('Olive Oil', 'oil1');
    a('Canola Oil', 'oil1');
    a('Sunflower Oil', 'oil1');
    a('Corn Oil', 'oil1');

    a('Atta (Wheat Flour)', 'atta1');
    a('Rice (Basmati, Sella)', 'ricebag1');
    a('Masoor Daal', 'lentils1');
    a('Moong Daal', 'lentils1');
    a('Chana Daal', 'lentils1');
    a('Mash Daal', 'lentils1');
    a('Gram (Chana)', 'lentils1');
    a('Besan', 'atta1');

    a('Spices (Haldi, Mirch, Dhaniya)', 'spice1');
    a('Garam Masala', 'pk_masala_bags');
    a('Salt', 'spice1');
    a('Sugar', 'sugar1');
    a('Ketchup', 'spice1');
    a('Chili Sauce', 'spice1');
    a('Soy Sauce', 'spice1');
    a('Pickles (Achaar)', 'spice1');
    a('Vinegar', 'spice1');

    a('Instant Noodles', 'snack1');
    a('Canned Food', 'snack1');
    a('Ready-to-Eat Meals', 'frozen1');
    a('Jams & Spreads', 'sweet2');

    a('Biscuits', 'snack1');
    a('Chips', 'chips1');
    a('Nimko', 'chips1');
    a('Bread', 'bread1');
    a('Rusk', 'bread1');
    a('Cakes', 'sweet2');

    a('Milk', 'milk1');
    a('Milk 1L (full cream)', 'milk2');
    a('UHT milk 250ml', 'milk1');
    a('UHT milk 1L', 'milk2');
    a('Full cream milk 1L (popular brand style)', 'milk2');
    a('Milk pack 500ml', 'milk1');
    a('Tea whitener (liquid)', 'milk2');
    a('Yogurt (Dahi)', 'dairy1');
    a('Butter', 'dairy1');
    a('Cheese', 'dairy1');
    a('Cream', 'dairy1');
    a('Tea', 'tea1');
    a('Coffee', 'tea1');
    a('Juices', 'pk_juice');
    a('Soft Drinks', 'pk_softdrinks');
    a('Mineral Water', 'pk_drinks_shelf');

    a('Vegetables', 'veg1');
    a('Fruits', 'veg1');
    a('Chicken', 'bbq1');
    a('Meat', 'bbq2');

    a('Frozen Paratha', 'frozen1');
    a('Nuggets', 'fried2');
    a('Frozen Vegetables', 'veg1');
    a('Ice Cream', 'sweet2');

    a('Laundry Detergent', 'clean1');
    a('Dishwashing Liquid', 'clean1');
    a('Floor Cleaner (Phenyl)', 'clean1');
    a('Toilet Cleaner', 'clean1');
    a('Tissue / Paper', 'clean1');

    a('Soap', 'clean1');
    a('Shampoo', 'clean1');
    a('Toothpaste', 'clean1');
    a('Hair Oil', 'oil1');
    a('Lotion', 'clean1');

    a('Diapers', 'baby1');
    a('Baby Food', 'baby1');
    a('Baby Wipes', 'baby1');

    a('Matches', 'snack1');
    a('Batteries', 'snack1');
    a('Plastic Bags', 'clean1');
    a('Stationery', 'snack1');

    // PK grocery library — explicit labels (nested catalog + “style” wording, no logos)
    a('Sunflower Oil 1L', 'oil1');
    a('Canola Oil 1L', 'oil1');
    a('Dalda Cooking Oil (style)', 'oil1');
    a('Olive Oil', 'oil1');
    a('Corn Oil', 'oil1');
    a('Soya Cooking Oil', 'oil1');
    a('Banaspati Ghee 1kg', 'oil1');
    a('Vegetable Ghee', 'oil1');
    a('Basmati Rice 5kg', 'ricebag1');
    a('Sella Rice 5kg', 'ricebag1');
    a('Kernel Basmati (style)', 'ricebag1');
    a('Double Bag Rice', 'ricebag1');
    a('Steam Rice 1kg', 'ricebag1');
    a('Atta (Wheat Flour) 10kg', 'atta1');
    a('Chakki Aatta', 'atta1');
    a('UHT milk 200ml', 'milk1');
    a('Flavoured Milk (style)', 'pk_milk_shelf');
    a('Milk powder (style)', 'pk_milk_shelf');
    a('Tea (family pack)', 'tea1');
    a('Tapal Tea (style)', 'tea1');
    a('Lipton Tea (style)', 'tea1');
    a('Green Tea', 'tea1');
    a('Elachi Chai mix', 'spice1');
    a('Shan Masala (style)', 'pk_masala_bags');
    a('National Masala (style)', 'pk_masala_bags');
    a('Sugar 2kg', 'sugar1');
    a('Brown Sugar', 'sugar1');
    a('Gurr (Jaggery)', 'sugar1');
    a('Cola 500ml', 'pk_softdrinks');
    a('Sprite 500ml', 'pk_softdrinks');
    a('Cola 1.5L', 'pk_softdrinks');
    a('Orange soft drink (style)', 'pk_softdrinks');
    a('Mango juice (style)', 'pk_juice');
    a('Apple juice (style)', 'pk_juice2');
    a('Syrup (rose / style)', 'pk_juice');
    a('Shezan juice (style)', 'pk_juice');
    a('Mineral water 500ml', 'pk_drinks_shelf');
    a('Water 1.5L bottle', 'pk_drinks_shelf');

    return m;
  }();

  static final Map<String, String> _salon = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }
    a('Haircut', 'salon1');
    a('Hair Styling', 'salon1');
    a('Beard Trim', 'salon2');
    a('Shave', 'salon2');
    a('Facial', 'facial1');
    a('Cleanup', 'facial1');
    a('Wax', 'wax1');
    a('Threading', 'facial1');
    a('Mani/Pedi', 'nail1');
    a('Manicure', 'nail1');
    a('Pedicure', 'nail1');
    a('Party Makeup', 'makeup1');
    a('Bridal Makeup', 'makeup1');
    a('Makeup', 'makeup1');
    return m;
  }();

  static final Map<String, String> _gym = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }
    a('Membership', 'gym1');
    a('Monthly Membership', 'gym1');
    a('Yearly Membership', 'gym1');
    a('Personal Training', 'gym2');
    a('PT Session', 'gym2');
    a('Class', 'gym3');
    a('Group Class', 'gym3');
    a('Diet Plan', 'gym2');
    return m;
  }();

  static final Map<String, String> _clinic = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }
    a('Consultation', 'doc1');
    a('OPD Consult', 'doc1');
    a('Video Consult', 'doc1');
    a('Lab', 'lab1');
    a('Blood Test', 'lab1');
    a('X-Ray', 'lab1');
    a('Medicines', 'pills1');
    a('Prescription Medicines', 'pills1');
    return m;
  }();

  static final Map<String, String> _mechanic = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }
    a('Puncture', 'tire1');
    a('Tire Repair', 'tire1');
    a('Puncture Fix', 'tire1');
    a('Battery', 'battery1');
    a('Battery Change', 'battery1');
    a('Jump Start', 'battery1');
    a('Oil Change', 'wrench1');
    a('Filter Change', 'wrench1');
    a('Towing', 'tow1');
    a('Roadside Help', 'tow1');
    return m;
  }();

  static final Map<String, String> _homeService = () {
    final m = <String, String>{};
    void a(String label, String key) {
      m[_norm(label)] = _u[key]!;
    }
    a('Electrician', 'home_electric');
    a('Wiring', 'home_electric');
    a('Fan Install', 'home_electric');
    a('Plumber', 'home_plumber');
    a('Leak Fix', 'home_plumber');
    a('Motor Install', 'home_plumber');
    a('Carpenter', 'home_wood');
    a('Furniture Repair', 'home_wood');
    a('Painter', 'home_paint');
    a('Room Paint', 'home_paint');
    a('AC', 'home_ac');
    a('AC Service', 'home_ac');
    a('Gas Refill', 'home_ac');
    return m;
  }();

  static String _norm(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

  /// HTTPS URL for this restaurant menu label, or null → fallback to SVG in UI.
  static String? restaurantUrlForLabel(String label) {
    final k = _norm(label);
    return _restaurant[k] ?? _restaurantPartial(k);
  }

  /// HTTPS URL for grocery SKU label.
  static String? groceryUrlForLabel(String label) {
    final k = _norm(label);
    return _grocery[k] ?? _groceryPartial(k);
  }

  /// Thumbnail URL for the product image library (restaurant / cafe / grocery-style shops).
  static String? stockUrlForBusiness(String businessTypeId, String label) {
    final b = businessTypeId.toLowerCase();
    if (b == 'restaurant' || b == 'cafe') {
      return restaurantUrlForLabel(label);
    }
    if (b == 'grocery' || b == 'pharmacy' || b == 'others') {
      return groceryUrlForLabel(label);
    }
    if (b == 'rentacar') {
      return rentacarUrlForLabel(label);
    }
    if (b == 'salon' || b == 'beauty') {
      return salonUrlForLabel(label);
    }
    if (b == 'gym') {
      return gymUrlForLabel(label);
    }
    if (b == 'clinic') {
      return clinicUrlForLabel(label);
    }
    if (b == 'mechanic') {
      return mechanicUrlForLabel(label);
    }
    if (b == 'homeservice') {
      return homeServiceUrlForLabel(label);
    }
    return null;
  }

  static String? salonUrlForLabel(String label) {
    final k = _norm(label);
    return _salon[k] ?? _salonPartial(k);
  }

  static String? gymUrlForLabel(String label) {
    final k = _norm(label);
    return _gym[k] ?? _gymPartial(k);
  }

  static String? clinicUrlForLabel(String label) {
    final k = _norm(label);
    return _clinic[k] ?? _clinicPartial(k);
  }

  static String? mechanicUrlForLabel(String label) {
    final k = _norm(label);
    return _mechanic[k] ?? _mechanicPartial(k);
  }

  static String? homeServiceUrlForLabel(String label) {
    final k = _norm(label);
    return _homeService[k] ?? _homeServicePartial(k);
  }

  static String? _salonPartial(String k) {
    if (k.contains('hair') || k.contains('style')) return _u['salon1'];
    if (k.contains('beard') || k.contains('shave')) return _u['salon2'];
    if (k.contains('facial') || k.contains('clean')) return _u['facial1'];
    if (k.contains('wax') || k.contains('thread')) return _u['wax1'];
    if (k.contains('mani') || k.contains('pedi') || k.contains('nail')) {
      return _u['nail1'];
    }
    if (k.contains('makeup') || k.contains('bridal') || k.contains('party')) {
      return _u['makeup1'];
    }
    return _u['salon1'];
  }

  static String? _gymPartial(String k) {
    if (k.contains('diet') || k.contains('nutrition')) return _u['gym2'];
    if (k.contains('yoga') || k.contains('class') || k.contains('group')) {
      return _u['gym3'];
    }
    if (k.contains('pt') || k.contains('personal')) return _u['gym2'];
    if (k.contains('member')) return _u['gym1'];
    return _u['gym1'];
  }

  static String? _clinicPartial(String k) {
    if (k.contains('blood') || k.contains('x-ray') || k.contains('lab')) {
      return _u['lab1'];
    }
    if (k.contains('medicine') || k.contains('pharma') || k.contains('drug')) {
      return _u['pills1'];
    }
    if (k.contains('consult') || k.contains('opd') || k.contains('doctor')) {
      return _u['doc1'];
    }
    return _u['doc1'];
  }

  static String? _mechanicPartial(String k) {
    if (k.contains('tire') || k.contains('punctur') || k.contains('wheel')) {
      return _u['tire1'];
    }
    if (k.contains('battery') || k.contains('jump')) return _u['battery1'];
    if (k.contains('oil') || k.contains('filter') || k.contains('wrench')) {
      return _u['wrench1'];
    }
    if (k.contains('tow') || k.contains('road')) return _u['tow1'];
    return _u['wrench1'];
  }

  static String? _homeServicePartial(String k) {
    if (k.contains('electric') || k.contains('wire') || k.contains('fan')) {
      return _u['home_electric'];
    }
    if (k.contains('plumb') || k.contains('leak') || k.contains('motor')) {
      return _u['home_plumber'];
    }
    if (k.contains('carpent') || k.contains('wood') || k.contains('furniture')) {
      return _u['home_wood'];
    }
    if (k.contains('paint')) return _u['home_paint'];
    if (k.contains('gas refill') || k.contains('ac service') || k == 'ac') {
      return _u['home_ac'];
    }
    return _u['home_electric'];
  }

  /// Generic car imagery for rent-a-car library (no manufacturer logos).
  static String? rentacarUrlForLabel(String label) {
    final k = _norm(label);
    if (k.contains('luxury') ||
        k.contains('mercedes') ||
        k.contains('bmw') ||
        k.contains('audi') ||
        k.contains('cruiser')) {
      return _u['car_luxury'];
    }
    if (k.contains('van') || k.contains('hiace') || k.contains('7-seat')) {
      return _u['car_van'];
    }
    if (k.contains('suv') ||
        k.contains('fortuner') ||
        k.contains('sportage') ||
        k.contains('sorento') ||
        k.contains('h6') ||
        k.contains('br-v') ||
        k.contains('hr-v') ||
        k.contains('cross')) {
      return _u['car_suv'];
    }
    if (k.contains('hatch') ||
        k.contains('cultus') ||
        k.contains('wagon r') ||
        k.contains('picanto') ||
        k.contains('swift')) {
      return _u['car_hatch'];
    }
    return _u['car_sedan'];
  }

  static String? _restaurantPartial(String k) {
    // Cooked **daal / chawal** plate (avoid matching random "dal" inside other words).
    if (k.contains('chawal') ||
        k.contains('daal') ||
        RegExp(r'\bdal\b').hasMatch(k)) {
      return _u['daalrice'];
    }
    if (k.contains('biryani')) return _u['biryani1'];
    if (k.contains('nihari')) return _u['stew1'];
    if (k.contains('haleem')) return _u['curry2'];
    if (k.contains('karahi') || k.contains('korma')) return _u['curry1'];
    if (k.contains('burger')) return _u['burger1'];
    if (k.contains('broast') || k.contains('fried')) return _u['fried1'];
    if (k.contains('wing')) return _u['wings1'];
    if (k.contains('pizza')) return _u['pizza1'];
    if (k.contains('roll') || k.contains('paratha')) return _u['wrap1'];
    if (k.contains('fries') || k.contains('chips')) return _u['fries1'];
    if (k.contains('lassi') || k.contains('drink') || k.contains('cola')) {
      return _u['drink1'];
    }
    if (k.contains('tikka') || k.contains('bbq') || k.contains('kabab')) {
      return _u['bbq1'];
    }
    return null;
  }

  static String? _groceryPartial(String k) {
    // Recipe mixes / masalay — **packet aisle** (Shan / National / garam style wording).
    if (k.contains('shan') ||
        k.contains('national') ||
        k.contains('recipe mix') ||
        k.contains('garam masala')) {
      return _u['pk_masala_bags'];
    }
    // **Cold drinks** — cola / sprite range
    if (k.contains('cola') ||
        k.contains('sprite') ||
        k.contains('pepsi') ||
        k.contains('fanta') ||
        k.contains('7up') ||
        k.contains('soft drink')) {
      return _u['pk_softdrinks'];
    }
    // **Juice / squash / sherbet** (PK juice wall)
    if (k.contains('juice') ||
        k.contains('squash') ||
        k.contains('shezan') ||
        k.contains('rooh') ||
        k.contains('syrup')) {
      return _u['pk_juice'];
    }
    // **Bottled water**
    if (k.contains('mineral water') ||
        (k.contains('water') && k.contains('bottle'))) {
      return _u['pk_drinks_shelf'];
    }
    if (k.contains('flavour') && k.contains('milk')) {
      return _u['pk_milk_shelf'];
    }
    if (k.contains('milk') || k.contains('dairy') || k.contains('whitener')) {
      return _u['milk1'];
    }
    if (k.contains('oil') || k.contains('ghee')) return _u['oil1'];
    if (k.contains('daal') ||
        k.contains('lentil') ||
        RegExp(r'\bdal\b').hasMatch(k)) {
      return _u['lentils1'];
    }
    if (k.contains('atta') || k.contains('besan') || k.contains('flour')) {
      return _u['atta1'];
    }
    if (k.contains('rice')) {
      return _u['ricebag1'];
    }
    if (k.contains('tea') || k.contains('coffee')) return _u['tea1'];
    if (k.contains('haldi') ||
        k.contains('mirch') ||
        k.contains('dhaniya') ||
        k.contains('ketchup') ||
        k.contains('pickle') ||
        k.contains('achaar')) {
      return _u['spice1'];
    }
    if (k.contains('spice') || k.contains('masala') || k.contains('salt')) {
      return _u['spice1'];
    }
    if (k.contains('chip') || k.contains('nimko') || k.contains('biscuit')) {
      return _u['chips1'];
    }
    if (k.contains('bread') || k.contains('rusk')) return _u['bread1'];
    if (k.contains('clean') || k.contains('detergent') || k.contains('soap')) {
      return _u['clean1'];
    }
    if (k.contains('baby') || k.contains('diaper')) return _u['baby1'];
    if (k.contains('veg') || k.contains('fruit')) return _u['veg1'];
    if (k.contains('frozen') || k.contains('nugget') || k.contains('ice cream')) {
      return _u['frozen1'];
    }
    return null;
  }
}
