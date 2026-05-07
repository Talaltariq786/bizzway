import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/constants/grocery_categories.dart';
import '../../core/constants/stock_photo_catalog.dart';
import '../../models/product.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_paths.dart';
import '../../core/config/offline_mode.dart';
import '../../core/utils/dev_log.dart';
import '../../providers/api_catalog_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_asset_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'product_image_library_screen.dart';

/// Investor / screen-recording scenarios for [AddProductScreen].
enum InvestorDemoAddProductScenario {
  /// Grocery bundle + Ramadan-style flags (current default demo).
  groceryBundle,
  /// Restaurant combo meal with multiple lines.
  restaurantCombo,
  /// Rent-a-car fleet line (daily self-drive).
  rentacarVehicle,
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    this.investorDemoPrefill = false,
    this.investorDemoScenario,
  });

  /// Guided tour: auto-fill Ramadan bundle + discount + price for recording.
  final bool investorDemoPrefill;

  /// When set, fills fields for that vertical (overrides [investorDemoPrefill]).
  final InvestorDemoAddProductScenario? investorDemoScenario;

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
  /// Curated HTTPS image when user picks from library / suggested chips (not a local file).
  String? _stockImageUrl;
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
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _pickedImagePath = file.path;
        _stockImageUrl = null;
        _suggestedImageName = null;
      });
    } catch (e, st) {
      devLog('pickPhotoFromGallery', e, st);
      if (mounted) {
        showAppToast(context, 'Gallery open nahi ho saki. Dobara try karein.',
            error: true);
      }
    }
  }

  String? _stockUrlForSuggestedName(String bizId, String name) {
    if (_isFoodBiz(bizId)) {
      return StockPhotoCatalog.restaurantUrlForLabel(name);
    }
    if (bizId == 'grocery' || bizId == 'pharmacy' || bizId == 'others') {
      return StockPhotoCatalog.groceryUrlForLabel(name);
    }
    return null;
  }

  void _selectSuggestedImage(String name, String bizId) {
    setState(() {
      _suggestedImageName = name;
      _pickedImagePath = null;
      _stockImageUrl = _stockUrlForSuggestedName(bizId, name);
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
      _stockImageUrl =
          sel.imagePath != null ? null : sel.stockImageUrl;
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
  void initState() {
    super.initState();
    if (widget.investorDemoScenario != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _investorDemoPrefillScenario(widget.investorDemoScenario!),
      );
    } else if (widget.investorDemoPrefill) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _investorDemoPrefill());
    }
  }

  Future<void> _investorDemoPrefillScenario(
    InvestorDemoAddProductScenario scenario,
  ) async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    final biz = context.read<BusinessProvider>();
    final raw = biz.selectedBusiness?.id ?? '';
    final bizId = raw.isEmpty ? 'grocery' : raw;

    switch (scenario) {
      case InvestorDemoAddProductScenario.groceryBundle:
        _applyInvestorDemoGroceryBundle(bizId);
        break;
      case InvestorDemoAddProductScenario.restaurantCombo:
        setState(() {
          _nameCtrl.text = 'Family Burger Combo';
          _descCtrl.text =
              'Two signature burgers + jumbo fries + 1.5 L drink — share meal.';
          _priceCtrl.text = '1899';
          _selectedCategory = 'Combos';
          _hasDiscount = true;
          _discountCtrl.text = '10';
          _isRamzanSpecial = false;
          _isValentinesSpecial = false;
          _isBundle = true;
          _bundleItems
            ..clear()
            ..addAll([
              'Classic beef burger',
              'Classic beef burger',
              'Jumbo fries',
              'Soft drink 1.5 L',
            ]);
          _selectedUnit = 'per combo';
        });
        break;
      case InvestorDemoAddProductScenario.rentacarVehicle:
        setState(() {
          _nameCtrl.text = 'Toyota Fortuner — self-drive';
          _descCtrl.text =
              '2023 • AC • Bluetooth • security deposit at pickup.';
          _priceCtrl.text = '13500';
          _selectedCategory = 'SUV';
          _hasDiscount = false;
          _discountCtrl.clear();
          _isBundle = false;
          _bundleItems.clear();
          _isRamzanSpecial = false;
          _isValentinesSpecial = false;
          _selectedUnit = 'per day';
        });
        break;
    }
  }

  void _applyInvestorDemoGroceryBundle(String bizId) {
    setState(() {
      _nameCtrl.text = 'Ramadan Family Pack';
      _descCtrl.text =
          'Limited bundle: dates, juice & staples — Ramadan special.';
      _priceCtrl.text = '3499';
      _selectedCategory = GroceryCategories.aisleNames[3];
      _hasDiscount = true;
      _discountCtrl.text = '15';
      _isRamzanSpecial = _showRamzanToggle(bizId);
      _isBundle = true;
      _bundleItems
        ..clear()
        ..addAll([
          'Premium dates 500g',
          'Rooh Afza 750ml',
          'Chana daal 1kg',
        ]);
      _selectedUnit = 'per pack';
    });
  }

  Future<void> _investorDemoPrefill() async {
    if (!mounted || !widget.investorDemoPrefill) return;
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    final biz = context.read<BusinessProvider>();
    final raw = biz.selectedBusiness?.id ?? '';
    final bizId = raw.isEmpty ? 'grocery' : raw;
    _applyInvestorDemoGroceryBundle(bizId);
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

  Future<void> _save(String bizId, List<String> categories) async {
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
      imageUrl: _pickedImagePath ?? _stockImageUrl ?? '',
      bundleItems:
          (_isBundle && allowBundle) ? List.unmodifiable(_bundleItems) : const [],
    );

    final msg = isGymMembership
        ? 'Package add ho gaya'
        : isService
            ? 'Service add ho gaya'
            : isFood
                ? 'Item add ho gaya${_hasDiscount ? ' (deal ke sath)' : ''}'
                : 'Product add ho gaya';
    try {
      final bizProv = context.read<BusinessProvider>();
      final catalogProv = context.read<ApiCatalogProvider>();
      final remoteId = bizProv.remoteBusinessMongoId;
      if (!OfflineMode.enabled && remoteId != null && remoteId.isNotEmpty) {
        await ApiClient().postJson(
          ApiPaths.businessProducts(remoteId),
          body: {
            'name': product.name,
            'price': product.price,
            'category': product.category,
            'images': product.imageUrl.trim().startsWith('http')
                ? [product.imageUrl.trim()]
                : <String>[],
            'stock': 0,
            'isActive': true,
          },
        );
        await catalogProv.loadProductsForBusinessType(
          bizId,
          remoteBusinessMongoId: bizProv.remoteBusinessMongoId,
        );
        if (!mounted) return;
        showAppToast(context, msg, success: true);
        Navigator.pop(context);
        return;
      }
      context.read<ProductProvider>().addProduct(product);
      if (!mounted) return;
      showAppToast(context, msg, success: true);
      Navigator.pop(context);
    } catch (e, st) {
      devLog('_save product', e, st);
      if (mounted) {
        showAppToast(
          context,
          'Server pe save nahi ho saka (login + business owner check). Local save try karein.',
          error: true,
        );
      }
    }
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

  /// Stock URLs use `w=800`; bump for sharper full-width preview on retina.
  String _sharperCatalogImageUrl(String url) {
    if (!url.contains('images.unsplash.com')) return url;
    return url.replaceFirst(RegExp(r'w=\d+'), 'w=1400');
  }

  Widget _emptyPhotoPlaceholder({
    required Color bizColor,
  }) {
    return ColoredBox(
      color: const Color(0xFFECEFF3),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 52,
              color: bizColor.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 10),
            Text(
              'Library se photo choose karein',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              if (!context.mounted) return;
              setState(() {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) _selectedCategory = name;
              });
              if (!ctx.mounted) return;
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photo: hero on top (square cover), controls below — clean ─
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Material(
                      color: const Color(0xFFECEFF3),
                      child: InkWell(
                        onTap: () => _openImageLibrary(
                          businessTypeId: bizId.isEmpty
                              ? (biz.selectedBusiness?.id ?? 'others')
                              : bizId,
                          accent: bizColor,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_pickedImagePath != null)
                                Image.file(
                                  File(_pickedImagePath!),
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                )
                              else if (_stockImageUrl != null &&
                                  _stockImageUrl!.startsWith('http'))
                                CachedNetworkImage(
                                  imageUrl: _sharperCatalogImageUrl(
                                      _stockImageUrl!),
                                  fit: BoxFit.cover,
                                  fadeInDuration:
                                      const Duration(milliseconds: 120),
                                  placeholder: (context, url) => ColoredBox(
                                    color: const Color(0xFFECEFF3),
                                    child: Center(
                                      child: SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: bizColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, err) =>
                                      _emptyPhotoPlaceholder(
                                    bizColor: bizColor,
                                  ),
                                )
                              else
                                _emptyPhotoPlaceholder(
                                  bizColor: bizColor,
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 3,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.18),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _pickPhotoFromGallery,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.photo_camera_outlined,
                                        size: 22,
                                        color: bizColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isService ? 'Service photo' : 'Item photo',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Photo par tap: library. Camera: phone gallery.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.2,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _openImageLibrary(
                                    businessTypeId: bizId.isEmpty
                                        ? (biz.selectedBusiness?.id ??
                                            'others')
                                        : bizId,
                                    accent: bizColor,
                                  ),
                                  icon: const Icon(
                                    Icons.collections_bookmark_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('Library'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickPhotoFromGallery,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('Gallery'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.textPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: bizColor.withValues(alpha: 0.4),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isShop) ...[
                const SizedBox(height: 8),
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
                const SizedBox(height: 6),
                SizedBox(
                  height: 86,
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
                      final thumbUrl = _isFlowerShop(bizId)
                          ? null
                          : _stockUrlForSuggestedName(bizId, name);
                      return GestureDetector(
                        onTap: () =>
                            _selectSuggestedImage(name, bizId),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: thumbUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: thumbUrl,
                                        width: 34,
                                        height: 34,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 34,
                                          height: 34,
                                          color: bizColor.withValues(alpha: 0.08),
                                          alignment: Alignment.center,
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: bizColor,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            AppAssetImage(
                                          businessTypeId: bizId.isEmpty
                                              ? (biz.selectedBusiness?.id ??
                                                  'others')
                                              : bizId,
                                          seed: 'shop_sugg_$i',
                                          itemName: name,
                                          width: 34,
                                          height: 34,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : AppAssetImage(
                                        businessTypeId: bizId.isEmpty
                                            ? (biz.selectedBusiness?.id ??
                                                'others')
                                            : bizId,
                                        seed: 'shop_sugg_$i',
                                        itemName: name,
                                        width: 34,
                                        height: 34,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                              const SizedBox(height: 4),
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
                                      : AppColors.textPrimary,
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
              const SizedBox(height: 16),

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

              // ── Category (quick) ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category_outlined, color: bizColor, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addCategoryDialog(context),
                          icon: Icon(Icons.add_rounded, size: 20, color: bizColor),
                          label: Text(
                            'New',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: bizColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in categories) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedCategory == cat
                                        ? bizColor
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                selected: _selectedCategory == cat,
                                onSelected: (ok) {
                                  if (!ok) return;
                                  setState(() => _selectedCategory = cat);
                                },
                                selectedColor: bizColor.withValues(alpha: 0.14),
                                backgroundColor: AppColors.backgroundLight,
                                side: BorderSide(
                                  color: _selectedCategory == cat
                                      ? bizColor
                                      : AppColors.border,
                                  width: _selectedCategory == cat ? 2 : 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── More options (collapsed) ──────────────────────────────
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  collapsedBackgroundColor: Colors.white,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.border),
                  ),
                  leading: Icon(Icons.tune_rounded, color: bizColor),
                  title: const Text(
                    'More options',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: const Text(
                    'Description, discount, unit, bundle, specials…',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Description (optional)',
                      hint: isService
                          ? 'What does this service include?'
                          : isFood
                              ? 'Ingredients / short description...'
                              : 'Brief product description...',
                      controller: _descCtrl,
                      maxLines: 3,
                      prefixIcon: Icons.description_outlined,
                      validator: null,
                    ),
                    const SizedBox(height: 16),

                    // Keep existing advanced sections below (bundle/discount/unit/etc.)
                    if (showBundle) ...[
                      // ── Package / Combo builder ───────────────────────────────
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
                                  activeThumbColor: bizColor,
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

                    // ── Ramzan / Valentines toggles, Gym options, Unit, Pharmacy slabs, Discount ──
                    // (existing code below remains, just moved into this ExpansionTile)
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
                              activeThumbColor: bizColor,
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
                              activeThumbColor: Colors.red,
                              onChanged: (v) =>
                                  setState(() => _isValentinesSpecial = v),
                            ),
                          ],
                        ),
                      ),
                    if (_showRamzanToggle(bizId) || _isFlowerShop(bizId))
                      const SizedBox(height: 16),

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
                              onTap: () => setState(() => _gymPackageDuration = d),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? bizColor : bizColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    color: sel ? Colors.white : bizColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                                color: _gymWithTrainer ? bizColor : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.sports_gymnastics_rounded,
                                color: _gymWithTrainer ? Colors.white : Colors.grey,
                                size: 20,
                              ),
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
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _gymWithTrainer,
                              onChanged: (v) => setState(() => _gymWithTrainer = v),
                              activeThumbColor: bizColor,
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

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
                                  color: selected ? bizColor : bizColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  u,
                                  style: TextStyle(
                                    color: selected ? Colors.white : bizColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
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

                    if (isPharmacy) ...[
                      // Pharmacy slab block (existing behavior)
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
                                Icon(Icons.savings_outlined, color: bizColor, size: 20),
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
                              'Example: bill ≥ Rs. 5,000 → 5% off.',
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

                    if (showStandardDiscount) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
                  ],
                ),
              ),

              // ── Package / Combo builder ───────────────────────────────
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
                onPressed: () async {
                  await _save(bizId, categories);
                },
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
