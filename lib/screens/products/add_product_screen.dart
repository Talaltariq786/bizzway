import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/grocery_categories.dart';
import '../../models/product.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_asset_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'product_image_library_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  /// Pharmacy: minimum cart total (Rs.) for slab discount.
  final _minOrderCtrl = TextEditingController();
  String? _selectedCategory;
  String _selectedUnit = 'per piece';
  bool _hasDiscount = false;
  bool _isBundle = false;
  bool _isRamzanSpecial = false;
  bool _isValentinesSpecial = false;
  final List<String> _bundleItems = [];
  final ImagePicker _imagePicker = ImagePicker();
  String? _pickedImagePath;
  String? _suggestedImageName;

  // Gym-specific
  String _gymPackageDuration = '1 Month';
  bool _gymWithTrainer = false;

  static const _units = [
    'per piece', 'per kg', 'per 500g', 'per pack',
    'per bottle', 'per dozen', 'per litre', 'per box',
  ];

  static const _flowerUnits = [
    'per bouquet', 'per arrangement', 'per dozen',
    'per bunch', 'per set', 'per package',
  ];

  static const _flowerSuggestedNames = [
    'Red Rose Bouquet',
    'Mehndi Flowers Package',
    'Shadi Decoration Package',
    'Bridal Bouquet',
    'Henna Ceremony Flowers',
    'Wedding Centerpiece',
    'Table Arrangement',
    'Gift Basket',
    'Birthday Flowers',
  ];

  Future<void> _pickPhotoFromGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;
    if (!mounted) return;
    setState(() {
      _pickedImagePath = file.path;
      _suggestedImageName = null;
    });
  }

  void _selectSuggestedImage(String name) {
    setState(() {
      _suggestedImageName = name;
      _pickedImagePath = null;
      // Optional helper: if name is empty, prefill to match selected suggestion.
      if (_nameCtrl.text.trim().isEmpty) _nameCtrl.text = name;
    });
  }

  Future<void> _openImageLibrary({
    required String businessTypeId,
    required Color accent,
  }) async {
    final sel = await Navigator.of(context).push<ProductImageSelection>(
      MaterialPageRoute(
        builder: (_) => ProductImageLibraryScreen(
          businessTypeId: businessTypeId,
          accent: accent,
        ),
      ),
    );
    if (sel == null) return;
    if (!mounted) return;
    setState(() {
      _suggestedImageName = sel.suggestedName;
      _pickedImagePath = sel.imagePath;
      if (_nameCtrl.text.trim().isEmpty && (sel.suggestedName ?? '').isNotEmpty) {
        _nameCtrl.text = sel.suggestedName!;
      }
    });
  }

  static const _gymDurations = [
    '1 Month', '3 Months', '6 Months', '12 Months',
  ];

  Future<void> _setCustomUnit(BuildContext context, Color accent) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _CustomUnitDialog(
        initialValue: _selectedUnit,
        accent: accent,
      ),
    );
    if (!mounted) return;
    if (result == null) return;
    final v = result.trim();
    if (v.isEmpty) return;
    setState(() => _selectedUnit = v);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _minOrderCtrl.dispose();
    super.dispose();
  }

  void _save(String bizId, List<String> categories) {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final isPharmacyCheck = bizId == 'pharmacy';
    if (_isBundle && _bundleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 included item for the package'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (isPharmacyCheck && _hasDiscount) {
      final minO = double.tryParse(_minOrderCtrl.text);
      final d = double.tryParse(_discountCtrl.text);
      if (minO == null || minO <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter minimum bill amount (Rs.) for this discount slab'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      if (d == null || d <= 0 || d >= 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter discount between 1 and 99%'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    final isService = _isServiceBiz(bizId);
    final isFood = _isFoodBiz(bizId);
    final isShop = _isShopBiz(bizId);
    final isGym = _isGymBiz(bizId);
    final isGymMembership = _isGymMembership(bizId);
    final isRentacar = _isRentacarBiz(bizId);
    final isPharmacy = bizId == 'pharmacy';
    final isClinic = bizId == 'clinic';
    final allowBundle = !isClinic &&
        !isPharmacy &&
        (isFood || isGym || (isShop && !isPharmacy));

    double discount = 0;
    double? minOrderDisc;
    if (isPharmacy && _hasDiscount) {
      discount = double.tryParse(_discountCtrl.text) ?? 0;
      minOrderDisc = double.tryParse(_minOrderCtrl.text);
    } else if (!isClinic && _hasDiscount) {
      if (isGym ||
          isFood ||
          isRentacar ||
          (isShop && !isPharmacy) ||
          (isService && !isGym)) {
        discount = double.tryParse(_discountCtrl.text) ?? 0;
      }
    }

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      businessTypeId: bizId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      category: _selectedCategory!,
      discountPercent: discount,
      durationMinutes: null,
      unit: isGymMembership
          ? _gymPackageDuration
          : (isGym && _selectedCategory != 'Assessment')
              ? _gymPackageDuration
              : isShop
                  ? _selectedUnit
                  : isRentacar
                      ? (_selectedCategory == 'With Driver'
                          ? 'per hour'
                          : 'per day')
                      : null,
      withTrainer: isGymMembership ? _gymWithTrainer : null,
      minOrderForDiscount: isPharmacy ? minOrderDisc : null,
      isRamzanSpecial: _showRamzanToggle(bizId) && _isRamzanSpecial,
      isValentinesSpecial: _isValentinesSpecial,
      imageUrl: _pickedImagePath ?? '',
      bundleItems:
          (_isBundle && allowBundle) ? List.unmodifiable(_bundleItems) : const [],
    );

    context.read<ProductProvider>().addProduct(product);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(isGymMembership
                ? 'Package added!'
                : isService
                    ? 'Service added!'
                    : isFood
                        ? 'Item added${_hasDiscount ? ' with deal!' : '!'}'
                        : 'Product added!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _fallbackCategoryForDelete(String bizId, String deleting, List<String> categories) {
    final trimmed = deleting.trim();
    final list = categories.where((c) => c.trim().isNotEmpty && c != trimmed).toList();
    if (list.contains('General')) return 'General';
    if (list.isNotEmpty) return list.first;
    // last resort
    return 'General';
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context, {
    required String bizId,
    required String category,
    required List<String> categories,
  }) async {
    final biz = context.read<BusinessProvider>();
    final productProv = context.read<ProductProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "$category"? Products in this category will be moved to a safe category.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final fallback = _fallbackCategoryForDelete(bizId, category, categories);
    productProv.migrateCategoryForBusiness(
      bizId,
      fromCategory: category,
      toCategory: fallback,
    );
    await biz.removeCustomCategory(category);

    if (!mounted) return;
    if (_selectedCategory == category) {
      setState(() => _selectedCategory = fallback);
    } else {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category deleted. Moved items to "$fallback".'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  bool _isServiceBiz(String id) =>
      ['salon', 'gym', 'clinic', 'beauty', 'mechanic', 'petcare']
          .contains(id);
  bool _isFoodBiz(String id) =>
      ['restaurant', 'cafe'].contains(id);
  bool _isShopBiz(String id) =>
      ['grocery', 'pharmacy', 'others', 'flowers'].contains(id);
  bool _isFlowerShop(String id) => id == 'flowers';
  bool _isRentacarBiz(String id) => id == 'rentacar';
  bool _isGymBiz(String id) => id == 'gym';
  bool _isGymMembership(String bizId) =>
      _isGymBiz(bizId) && _selectedCategory == 'Memberships';

  /// Ramzan toggle only for food/grocery-style shops (not pharmacy, gym, clinic, salon, etc.).
  bool _showRamzanToggle(String id) =>
      ['restaurant', 'cafe', 'grocery', 'others'].contains(id);

  Future<void> _pickBundleItems(
    BuildContext context, {
    required List<Product> existing,
  }) async {
    // Exclude bundles to avoid nesting complexity for now.
    final candidates = existing.where((p) => !p.isBundle).toList();
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BundleItemsSheet(
        candidates: candidates,
        initialSelected: _bundleItems,
        isFood: _isFoodBiz(context.read<BusinessProvider>().selectedBusiness?.id ?? ''),
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      _bundleItems
        ..clear()
        ..addAll(result..sort());
    });
  }

  Future<void> _addCategoryDialog(BuildContext context) async {
    final biz = context.read<BusinessProvider>();
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Category'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'e.g. Deals, Packages, BBQ, Drinks',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await biz.addCustomCategory(ctrl.text);
              if (!mounted) return;
              setState(() {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) _selectedCategory = name;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biz = context.watch<BusinessProvider>();
    final productProv = context.watch<ProductProvider>();
    final bizId = biz.selectedBusiness?.id ?? '';
    final categories = biz.categories;
    final customCategories = biz.customCategories.toSet();
    final isService = _isServiceBiz(bizId);
    final isFood = _isFoodBiz(bizId);
    final isShop = _isShopBiz(bizId);
    final isGym = _isGymBiz(bizId);
    final isGymMembership = _isGymMembership(bizId);
    final isRentacar = _isRentacarBiz(bizId);
    final isPharmacy = bizId == 'pharmacy';
    final isClinic = bizId == 'clinic';
    final showBundle = !isClinic &&
        !isPharmacy &&
        (isFood || isGym || (isShop && !isPharmacy));
    final showStandardDiscount = !isPharmacy &&
        !isGym &&
        !isClinic &&
        (isFood ||
            isRentacar ||
            (isShop && !isPharmacy) ||
            (isService && !isGym && !isClinic));
    final bizColor = biz.themeColor;
    final existing = bizId.isEmpty
        ? productProv.products
        : productProv.productsForBusiness(bizId);

    String appBarTitle = isGym
        ? 'Add Gym Package / Service'
        : isService
            ? 'Add Service'
            : isFood
                ? 'Add Menu Item'
                : 'Add Product';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image picker placeholder ──────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickPhotoFromGallery,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: bizColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: bizColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _pickedImagePath != null
                              ? Image.file(
                                  File(_pickedImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: AppAssetImage(
                                    businessTypeId: bizId.isEmpty
                                        ? (biz.selectedBusiness?.id ?? 'others')
                                        : bizId,
                                    seed: 'owner_preview',
                                    itemName: _suggestedImageName ??
                                        _nameCtrl.text.trim(),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: bizColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Tap to add photo',
                    style: TextStyle(
                        fontSize: 12, color: bizColor)),
              ),
              // Image library buttons (recommended for all; especially shop/food/services)
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => _openImageLibrary(
                          businessTypeId: bizId.isEmpty
                              ? (biz.selectedBusiness?.id ?? 'others')
                              : bizId,
                          accent: bizColor,
                        ),
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text('Library'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: _pickPhotoFromGallery,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                        label: const Text('Upload'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isShop) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isFlowerShop(bizId) ? 'Wedding & Event Packages' : 'Suggested items (tap to select)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _isFlowerShop(bizId)
                        ? _flowerSuggestedNames.length
                        : GroceryCategories.allSuggestedProductNames.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final names = _isFlowerShop(bizId)
                          ? _flowerSuggestedNames
                          : GroceryCategories.allSuggestedProductNames;
                      final name = names[i];
                      final selected = _suggestedImageName == name;
                      return GestureDetector(
                        onTap: () => _selectSuggestedImage(name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 92,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selected
                                ? bizColor.withValues(alpha: 0.14)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? bizColor.withValues(alpha: 0.6)
                                  : AppColors.border,
                            ),
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
                                businessTypeId: bizId.isEmpty
                                    ? (biz.selectedBusiness?.id ?? 'others')
                                    : bizId,
                                seed: 'shop_sugg_$i',
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
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? bizColor
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Name ─────────────────────────────────────────────────
              CustomTextField(
                label: isService
                    ? 'Service Name'
                    : isFood
                        ? 'Item Name'
                        : 'Product Name',
                hint: isService
                    ? 'e.g. Haircut & Style'
                    : isFood
                        ? 'e.g. Classic Burger'
                        : 'e.g. Basmati Rice',
                controller: _nameCtrl,
                prefixIcon: Icons.label_outline,
                validator: (v) => v!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),

              // ── Description ──────────────────────────────────────────
              CustomTextField(
                label: 'Description',
                hint: isService
                    ? 'What does this service include?'
                    : isFood
                        ? 'Ingredients or short description...'
                        : 'Brief product description...',
                controller: _descCtrl,
                maxLines: 3,
                prefixIcon: Icons.description_outlined,
                validator: (v) =>
                    v!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              // ── Price ─────────────────────────────────────────────────
              CustomTextField(
                label: 'Price (Rs.)',
                hint: '0',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                validator: (v) {
                  if (v!.isEmpty) return 'Please enter price';
                  if (double.tryParse(v) == null) return 'Enter valid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Package / Combo builder ───────────────────────────────
              if (showBundle) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.all_inclusive_rounded,
                              color: bizColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isFood ? 'Combo' : 'Package',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isBundle,
                            activeColor: bizColor,
                            onChanged: (v) => setState(() {
                              _isBundle = v;
                              if (!v) _bundleItems.clear();
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isFood
                            ? 'Enable to create a combo that includes multiple items.'
                            : 'Enable to bundle multiple items in one package.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (_isBundle) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._bundleItems.map((t) => Chip(
                                  label: Text(t),
                                  onDeleted: () =>
                                      setState(() => _bundleItems.remove(t)),
                                )),
                            ActionChip(
                              label: Text(isFood
                                  ? '+ Add combo items'
                                  : '+ Add package items'),
                              avatar: const Icon(Icons.add_rounded, size: 18),
                              onPressed: () => _pickBundleItems(
                                context,
                                existing: existing,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Included items: ${_bundleItems.length}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Ramzan Special / Valentine's Special Toggle ────────────────────────
              if (_showRamzanToggle(bizId) && !_isFlowerShop(bizId))
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration_rounded, color: bizColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ramzan Special',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Mark this as Ramzan offer',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isRamzanSpecial,
                        activeColor: bizColor,
                        onChanged: (v) => setState(() => _isRamzanSpecial = v),
                      ),
                    ],
                  ),
                ),
              if (_isFlowerShop(bizId))
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Valentine's Special",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Mark this as Valentine's Day offer",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isValentinesSpecial,
                        activeColor: Colors.red,
                        onChanged: (v) => setState(() => _isValentinesSpecial = v),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ── Gym: Package duration + Trainer toggle ────────────────
              if (isGym) ...[
                if (isGymMembership ||
                    _selectedCategory == 'Group Classes' ||
                    _selectedCategory == 'Diet Plans') ...[
                  const Text('Package Duration',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _gymDurations.map((d) {
                      final sel = _gymPackageDuration == d;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _gymPackageDuration = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? bizColor
                                : bizColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(d,
                              style: TextStyle(
                                  color: sel ? Colors.white : bizColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Trainer toggle — only for Memberships
                if (isGymMembership) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bizColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: bizColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _gymWithTrainer
                              ? bizColor
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sports_gymnastics_rounded,
                            color: _gymWithTrainer
                                ? Colors.white
                                : Colors.grey,
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Includes Personal Trainer',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            Text(
                                _gymWithTrainer
                                    ? 'Dedicated trainer assigned'
                                    : 'Self-workout only',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _gymWithTrainer,
                        onChanged: (v) =>
                            setState(() => _gymWithTrainer = v),
                        activeThumbColor: bizColor,
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                // Discount for all gym types
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.local_offer_rounded,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Add Discount',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary)),
                        ),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (v) =>
                              setState(() => _hasDiscount = v),
                          activeThumbColor: Colors.orange,
                        ),
                      ]),
                      if (_hasDiscount) ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Discount %',
                          hint: 'e.g. 15',
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.percent_rounded,
                        ),
                        const SizedBox(height: 8),
                        if (_priceCtrl.text.isNotEmpty &&
                            _discountCtrl.text.isNotEmpty) ...[
                          Builder(builder: (_) {
                            final p =
                                double.tryParse(_priceCtrl.text) ?? 0;
                            final d =
                                double.tryParse(_discountCtrl.text) ?? 0;
                            final discounted = p * (1 - d / 100);
                            return Text(
                              'Customer pays: Rs. ${discounted.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            );
                          }),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Shop: Unit ───────────────────────────────────────────
              if (isShop) ...[
                const Text('Unit / Pricing',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...(_isFlowerShop(bizId) ? _flowerUnits : _units).map((u) {
                      final selected = _selectedUnit == u;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedUnit = u),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                selected ? bizColor : bizColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(u,
                              style: TextStyle(
                                  color: selected ? Colors.white : bizColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                      );
                    }),
                    ActionChip(
                      label: const Text('Custom unit'),
                      avatar: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => _setCustomUnit(context, bizColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $_selectedUnit',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 16),
              ],

              // ── Pharmacy: discount slabs (min bill → %) ──────────────
              if (isPharmacy) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.savings_outlined,
                              color: bizColor, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Discount slab',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          Switch(
                            value: _hasDiscount,
                            onChanged: (v) => setState(() => _hasDiscount = v),
                            activeThumbColor: bizColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Example: bill ≥ Rs. 5,000 → 5% off. Add one row per slab.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (_hasDiscount) ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Minimum bill (Rs.)',
                          hint: 'e.g. 5000',
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.shopping_cart_outlined,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Discount %',
                          hint: 'e.g. 5',
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.percent_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Discount / Deal (non-gym, non-clinic, non-pharmacy) ─
              if (showStandardDiscount) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Add Discount / Deal',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                          ),
                          Switch(
                            value: _hasDiscount,
                            onChanged: (v) => setState(() => _hasDiscount = v),
                            activeThumbColor: Colors.orange,
                          ),
                        ],
                      ),
                      if (_hasDiscount) ...[
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Discount %',
                          hint: 'e.g. 20',
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.percent_rounded,
                          validator: _hasDiscount
                              ? (v) {
                                  if (v!.isEmpty) return 'Enter discount %';
                                  final d = double.tryParse(v);
                                  if (d == null || d <= 0 || d >= 100) {
                                    return 'Enter 1–99';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 8),
                        if (_priceCtrl.text.isNotEmpty &&
                            _discountCtrl.text.isNotEmpty) ...[
                          Builder(builder: (_) {
                            final p = double.tryParse(_priceCtrl.text) ?? 0;
                            final d = double.tryParse(_discountCtrl.text) ?? 0;
                            final discounted = p * (1 - d / 100);
                            return Text(
                              'Customer pays: Rs. ${discounted.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            );
                          }),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Category ─────────────────────────────────────────────
              const Text('Category',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final selected = _selectedCategory == cat;
                  final isCustom = customCategories.contains(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    onLongPress: isCustom
                        ? () => _confirmDeleteCategory(
                              context,
                              bizId: bizId,
                              category: cat,
                              categories: categories,
                            )
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? bizColor : bizColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat,
                              style: TextStyle(
                                  color: selected ? Colors.white : bizColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          if (isCustom) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: selected ? Colors.white : bizColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _addCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add new category'),
                ),
              ),
              if (bizId == 'rentacar') ...[
                const SizedBox(height: 10),
                Text(
                  'Rent-a-Car: "With Driver" price is per hour, "Self Drive" price is per day.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // ── Save button ───────────────────────────────────────────
              CustomButton(
                label: isService
                    ? 'Save Service'
                    : isFood
                        ? 'Add to Menu'
                        : 'Save Product',
                onPressed: () => _save(bizId, categories),
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleItemsSheet extends StatefulWidget {
  final List<Product> candidates;
  final List<String> initialSelected;
  final bool isFood;
  const _BundleItemsSheet({
    required this.candidates,
    required this.initialSelected,
    required this.isFood,
  });

  @override
  State<_BundleItemsSheet> createState() => _BundleItemsSheetState();
}

class _BundleItemsSheetState extends State<_BundleItemsSheet> {
  final TextEditingController _manualCtrl = TextEditingController();
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected.toSet();
  }

  @override
  void dispose() {
    _manualCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelWord = widget.isFood ? 'combo' : 'package';
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Select included items',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These will appear inside your $labelWord on customer side.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Add included item manually',
                                hintText:
                                    'e.g. Haircut, Beard, Facial, Mani/Pedi',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final t = _manualCtrl.text.trim();
                              if (t.isEmpty) return;
                              setState(() => _selected.add(t));
                              _manualCtrl.clear();
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: widget.candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = widget.candidates[i];
                  final checked = _selected.contains(p.name);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CheckboxListTile(
                      value: checked,
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(p.name);
                        } else {
                          _selected.remove(p.name);
                        }
                      }),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Rs. ${p.price.toStringAsFixed(0)} • ${p.category}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(ctx).padding.bottom + 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            FocusScope.of(ctx).unfocus();
                            Navigator.pop<List<String>>(ctx, null);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            FocusScope.of(ctx).unfocus();
                            Navigator.pop<List<String>>(
                              ctx,
                              _selected.toList(),
                            );
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomUnitDialog extends StatefulWidget {
  final String initialValue;
  final Color accent;
  const _CustomUnitDialog({
    required this.initialValue,
    required this.accent,
  });

  @override
  State<_CustomUnitDialog> createState() => _CustomUnitDialogState();
}

class _CustomUnitDialogState extends State<_CustomUnitDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Custom unit'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(
          labelText: 'Unit',
          hintText: 'e.g. per 250g, per 5kg bag, per tray, per carton',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: widget.accent),
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
