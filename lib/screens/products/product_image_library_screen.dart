import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/common/app_asset_image.dart';

class ProductImageSelection {
  final String? imagePath; // local file path
  final String? suggestedName; // used for label/fallback asset mapping
  final String category;
  final String businessTypeId;

  const ProductImageSelection({
    required this.businessTypeId,
    required this.category,
    this.imagePath,
    this.suggestedName,
  });
}

class ProductImageLibraryScreen extends StatefulWidget {
  final String businessTypeId;
  final Color accent;

  const ProductImageLibraryScreen({
    super.key,
    required this.businessTypeId,
    required this.accent,
  });

  @override
  State<ProductImageLibraryScreen> createState() =>
      _ProductImageLibraryScreenState();
}

class _ProductImageLibraryScreenState extends State<ProductImageLibraryScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final List<String> _cats = _categoriesFor(widget.businessTypeId);
  late final TabController _tabCtrl =
      TabController(length: _cats.length, vsync: this);
  final Map<String, List<String>> _userImages = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _keyFor(String cat) =>
      'image_lib_${widget.businessTypeId}_${cat.toLowerCase()}';

  static List<String> _categoriesFor(String bizId) {
    if (bizId == 'restaurant' || bizId == 'cafe') {
      return const [
        'Biryani',
        'BBQ',
        'Karahi',
        'Burgers',
        'Pizza',
        'Rolls',
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
    if (bizId == 'clinic' || bizId == 'pharmacy') {
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

  static Map<String, List<String>> _suggestedNamesByCat(String bizId) {
    if (bizId == 'restaurant' || bizId == 'cafe') {
      return const {
        'Biryani': ['Chicken Biryani', 'Beef Biryani'],
        'BBQ': ['Chicken Tikka', 'Malai Boti', 'Seekh Kabab'],
        'Karahi': ['Chicken Karahi', 'Mutton Karahi'],
        'Burgers': ['Zinger Burger', 'Beef Burger'],
        'Pizza': ['Fajita Pizza', 'Pepperoni Pizza'],
        'Rolls': ['Chicken Roll', 'Tikka Roll'],
        'Drinks': ['Cola', 'Lassi', 'Fresh Lime'],
        'Desserts': ['Kheer', 'Gulab Jamun'],
      };
    }
    if (bizId == 'grocery' || bizId == 'pharmacy' || bizId == 'others') {
      return const {
        'Oil': ['Cooking Oil', 'Sunflower Oil', 'Canola Oil'],
        'Ghee': ['Desi Ghee', 'Vegetable Ghee'],
        'Rice': ['Basmati Rice', 'Sella Rice'],
        'Daal': ['Masoor Daal', 'Moong Daal', 'Chana Daal'],
        'Flour': ['Aata (Flour)', 'Maida'],
        'Milk': ['Milk', 'Olpers Milk', 'Milk Pack'],
        'Tea': ['Tea', 'Tapal Tea', 'Lipton Tea'],
        'Spices': ['Spices', 'Shan Masala', 'National Masala'],
        'Sugar': ['Sugar'],
      };
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
    if (bizId == 'rentacar') {
      return const {
        'Sedan': ['Sedan'],
        'SUV': ['SUV'],
        'Hatchback': ['Hatchback'],
        'Van': ['Van'],
        'Luxury': ['Luxury Car'],
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
    return const {
      'General': ['Item'],
    };
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final cat in _cats) {
      final raw = prefs.getString(_keyFor(cat));
      if (raw == null || raw.isEmpty) {
        _userImages[cat] = <String>[];
        continue;
      }
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _userImages[cat] = decoded
              .map((e) => e.toString())
              .where((p) => p.isNotEmpty)
              .toList();
        } else {
          _userImages[cat] = <String>[];
        }
      } catch (_) {
        _userImages[cat] = <String>[];
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _persist(String cat) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(cat), jsonEncode(_userImages[cat] ?? const []));
  }

  Future<void> _addFromGallery(String cat) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;
    if (!mounted) return;
    setState(() {
      _userImages.putIfAbsent(cat, () => <String>[]);
      _userImages[cat]!.insert(0, file.path);
    });
    await _persist(cat);
  }

  Future<void> _removeImage(String cat, String path) async {
    setState(() {
      _userImages[cat]?.remove(path);
    });
    await _persist(cat);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.businessTypeId == 'restaurant' ||
            widget.businessTypeId == 'cafe'
        ? 'Restaurant Image Library'
        : widget.businessTypeId == 'rentacar'
            ? 'Rent-a-Car Image Library'
            : widget.businessTypeId == 'salon' || widget.businessTypeId == 'beauty'
                ? 'Salon Image Library'
                : 'Image Library';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: widget.accent,
          labelColor: widget.accent,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _cats.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _cats.map((cat) => _tab(cat)).toList(),
      ),
    );
  }

  Widget _tab(String cat) {
    final suggestedMap = _suggestedNamesByCat(widget.businessTypeId);
    final suggested = suggestedMap[cat] ?? const <String>[];
    final userImgs = _userImages[cat] ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$cat Images',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _addFromGallery(cat),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Suggested (tap to use)',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        if (suggested.isEmpty)
          const Text('No suggestions yet.',
              style: TextStyle(color: AppColors.textHint))
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggested.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _suggestedCard(cat, suggested[i], i),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Your photos (tap to use, long press to delete)',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        if (userImgs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text(
                'No photos yet. Tap Add to upload from gallery.',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: userImgs.length,
            itemBuilder: (_, i) {
              final p = userImgs[i];
              return GestureDetector(
                onTap: () => Navigator.pop(
                  context,
                  ProductImageSelection(
                    businessTypeId: widget.businessTypeId,
                    category: cat,
                    imagePath: p,
                  ),
                ),
                onLongPress: () => _confirmDelete(cat, p),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: Colors.white,
                    child: Image.file(
                      File(p),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _suggestedCard(String cat, String name, int i) {
    return GestureDetector(
      onTap: () => Navigator.pop(
        context,
        ProductImageSelection(
          businessTypeId: widget.businessTypeId,
          category: cat,
          suggestedName: name,
        ),
      ),
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppAssetImage(
              businessTypeId: widget.businessTypeId,
              seed: 'lib_${cat}_$i',
              itemName: name,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String cat, String path) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete photo?'),
        content: const Text('This will remove it from your library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _removeImage(cat, path);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

