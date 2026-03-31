import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/business.dart';
import '../../models/business_type.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../core/utils/async_guard.dart';
import 'book_slot_screen.dart';
import '../../core/media/app_media.dart';
import '../../widgets/common/app_asset_image.dart';

// ── Render mode ───────────────────────────────────────────────────────────────
enum _Mode { food, shop, service, clinic }

_Mode _modeFor(String typeId) {
  switch (typeId) {
    case 'restaurant':
    case 'cafe':
      return _Mode.food;
    case 'grocery':
    case 'pharmacy':
    case 'others':
      return _Mode.shop;
    case 'clinic':
      return _Mode.clinic;
    case 'rentacar':
      return _Mode.service;
    default:
      return _Mode.service; // salon, gym
  }
}

// ── Image helpers ─────────────────────────────────────────────────────────────
/// External stock images (disabled by default).
String _img(String seed, String keyword, {int w = 300, int h = 300}) {
  final lock = seed.hashCode.abs() % 9999;
  return 'https://loremflickr.com/$w/$h/$keyword?lock=$lock';
}

/// Business-type → image keyword
String _bizKw(String bizTypeId) {
  switch (bizTypeId) {
    case 'restaurant':  return 'food,restaurant,meal';
    case 'cafe':        return 'coffee,cafe,pastry';
    case 'grocery':     return 'grocery,supermarket,vegetables';
    case 'pharmacy':    return 'pharmacy,medicine,health';
    case 'salon':       return 'salon,haircut,beauty';
    case 'gym':         return 'gym,fitness,workout';
    case 'clinic':      return 'doctor,clinic,hospital';
    case 'beauty':      return 'makeup,beauty,cosmetics';
    case 'flowers':     return 'flowers,bouquet,floral';
    case 'rentacar':    return 'car,automobile,vehicle';
    case 'mechanic':    return 'car,repair,workshop';
    case 'homeservice': return 'tools,repair,home';
    case 'petcare':     return 'pet,dog,animal';
    default:            return 'store,shop,business';
  }
}

/// Item name + business type → specific image keyword
String _itemKw(String bizTypeId, String itemName) {
  final n = itemName.toLowerCase();
  switch (bizTypeId) {
    case 'restaurant':
    case 'cafe':
      if (n.contains('burger'))                        return 'burger,fast food';
      if (n.contains('pizza'))                         return 'pizza,italian';
      if (n.contains('coffee') || n.contains('cappuccino') || n.contains('latte')) return 'coffee,latte,cafe';
      if (n.contains('cake') || n.contains('dessert') || n.contains('sweet')) return 'cake,dessert,bakery';
      if (n.contains('salad'))                         return 'salad,healthy food';
      if (n.contains('drink') || n.contains('juice') || n.contains('lemon')) return 'juice,drink,refreshing';
      if (n.contains('pasta'))                         return 'pasta,italian';
      if (n.contains('rice') || n.contains('biryani')) return 'biryani,rice,food';
      if (n.contains('sandwich'))                      return 'sandwich,sub';
      if (n.contains('chicken') || n.contains('tikka')) return 'chicken,grilled,food';
      if (n.contains('tea') || n.contains('chai'))     return 'tea,drink,hot';
      if (n.contains('croissant') || n.contains('pastry')) return 'croissant,pastry,bakery';
      return 'food,restaurant,meal';
    case 'grocery':
      if (n.contains('rice') || n.contains('basmati')) return 'rice,grain,food';
      if (n.contains('veg') || n.contains('tomato') || n.contains('onion')) return 'vegetables,fresh,farm';
      if (n.contains('fruit') || n.contains('apple') || n.contains('banana')) return 'fruit,fresh,market';
      if (n.contains('milk') || n.contains('dairy') || n.contains('cheese')) return 'dairy,milk,fresh';
      if (n.contains('oil'))                           return 'cooking oil,kitchen';
      if (n.contains('bread') || n.contains('bak'))   return 'bread,bakery,fresh';
      if (n.contains('biscuit') || n.contains('snack')) return 'snack,biscuit,food';
      return 'grocery,supermarket,food';
    case 'pharmacy':
      return 'medicine,pharmacy,health,capsule';
    case 'salon':
      if (n.contains('hair') || n.contains('cut'))    return 'haircut,salon,barber';
      if (n.contains('color') || n.contains('dye'))   return 'hair color,salon';
      if (n.contains('beard') || n.contains('shave')) return 'beard,barber,shave';
      if (n.contains('spa') || n.contains('massage')) return 'spa,massage,relax';
      if (n.contains('facial') || n.contains('skin')) return 'facial,skincare,beauty';
      return 'salon,beauty,hair';
    case 'gym':
      if (n.contains('yoga'))                         return 'yoga,meditation,wellness';
      if (n.contains('cardio') || n.contains('run'))  return 'running,cardio,fitness';
      if (n.contains('weight') || n.contains('strength')) return 'weightlifting,gym,strength';
      if (n.contains('class') || n.contains('group')) return 'group fitness,aerobics';
      return 'gym,fitness,workout,exercise';
    case 'clinic':
      return 'doctor,clinic,medical,hospital';
    case 'rentacar':
      if (n.contains('suv') || n.contains('jeep'))   return 'suv,4x4,jeep';
      if (n.contains('sedan') || n.contains('luxury')) return 'sedan,luxury car';
      if (n.contains('van') || n.contains('mini'))    return 'van,minivan';
      if (n.contains('bike') || n.contains('moto'))   return 'motorcycle,bike';
      return 'car,automobile,vehicle,driving';
    case 'mechanic':
      return 'car repair,mechanic,workshop,tools';
    case 'homeservice':
      if (n.contains('electric'))  return 'electrician,wiring,electrical';
      if (n.contains('plumb'))     return 'plumbing,pipe,water';
      if (n.contains('paint'))     return 'painting,home,wall';
      if (n.contains('ac') || n.contains('air cond')) return 'air conditioner,cooling';
      if (n.contains('carpenter')) return 'carpenter,wood,furniture';
      return 'home repair,tools,handyman';
    case 'beauty':
      if (n.contains('facial'))    return 'facial,skincare,glow';
      if (n.contains('nail'))      return 'nails,manicure,pedicure';
      if (n.contains('bridal'))    return 'bridal,makeup,wedding';
      if (n.contains('wax'))       return 'waxing,spa,beauty';
      if (n.contains('thread'))    return 'threading,eyebrow,beauty';
      return 'makeup,beauty,cosmetics';
    case 'petcare':
      return 'pet,dog,cat,animal,cute';
    case 'flowers':
      return 'flowers,bouquet,floral,rose';
    default:
      return 'store,business,shop';
  }
}

/// Category name → image keyword (for shop aisle grid)
String _catKw(String cat, String bizTypeId) {
  final c = cat.toLowerCase();
  if (c.contains('fruit'))     return 'fruit,fresh market';
  if (c.contains('veg'))       return 'vegetables,fresh market';
  if (c.contains('dairy') || c.contains('milk')) return 'dairy,milk';
  if (c.contains('meat') || c.contains('chicken')) return 'meat,chicken,butcher';
  if (c.contains('bak'))       return 'bakery,bread,fresh';
  if (c.contains('bever') || c.contains('drink')) return 'drinks,beverages';
  if (c.contains('rice') || c.contains('grain')) return 'rice,grain,food';
  if (c.contains('med') || c.contains('pharma'))  return 'medicine,pharmacy';
  if (c.contains('suppl') || c.contains('vitamin')) return 'vitamins,supplements,health';
  if (c.contains('coffee'))    return 'coffee,cafe';
  if (c.contains('dessert') || c.contains('sweet')) return 'dessert,sweet,cake';
  if (c.contains('combo') || c.contains('meal'))  return 'food,meal,combo';
  return _bizKw(bizTypeId);
}

Widget _netImg(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget fallback,
}) {
  // Default: show placeholders (Pakistan-first + reliable).
  if (!AppMedia.useExternalStockImages) return fallback;

  final showFallbackInsteadOfSizedBox = width == null || height == null;
  final placeholder = showFallbackInsteadOfSizedBox
      ? fallback
      : Container(
          width: width,
          height: height,
          color: Colors.grey[100],
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );

  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => placeholder,
    errorWidget: (_, __, ___) => fallback,
  );
}

// ── Service category icons ────────────────────────────────────────────────────
IconData _serviceIcon(String cat) {
  final c = cat.toLowerCase();
  if (c.contains('hair') || c.contains('cut')) return Icons.content_cut_rounded;
  if (c.contains('makeup') || c.contains('beauty')) return Icons.face_retouching_natural_rounded;
  if (c.contains('nail') || c.contains('manicure') || c.contains('pedicure')) return Icons.back_hand_rounded;
  if (c.contains('massage') || c.contains('spa')) return Icons.spa_rounded;
  if (c.contains('skin') || c.contains('facial')) return Icons.face_rounded;
  if (c.contains('barber') || c.contains('beard') || c.contains('shave')) return Icons.how_to_reg_rounded;
  if (c.contains('yoga') || c.contains('meditation')) return Icons.self_improvement_rounded;
  if (c.contains('cardio') || c.contains('running')) return Icons.directions_run_rounded;
  if (c.contains('strength') || c.contains('weight') || c.contains('muscle')) return Icons.fitness_center_rounded;
  if (c.contains('fitness') || c.contains('gym') || c.contains('class')) return Icons.sports_gymnastics_rounded;
  if (c.contains('dental') || c.contains('teeth')) return Icons.local_hospital_rounded;
  if (c.contains('general') || c.contains('consult')) return Icons.medical_services_rounded;
  if (c.contains('pediatric') || c.contains('child')) return Icons.child_care_rounded;
  if (c.contains('package') || c.contains('bundle')) return Icons.card_giftcard_rounded;
  return Icons.star_rounded;
}

// ── Main screen ───────────────────────────────────────────────────────────────
class BusinessDetailScreen extends StatefulWidget {
  final Business business;
  const BusinessDetailScreen({super.key, required this.business});

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  TabController? _tabCtrl;
  bool _deliverySelected = true;
  static const double _fakeDistanceKm = 2.4; // demo distance
  double get _deliveryDistanceKm => biz.deliveryRadiusKm ?? _fakeDistanceKm;

  // Prescription
  final List<_RxEntry> _rxItems = [];
  final _rxPatientCtrl = TextEditingController();
  final _rxDoctorCtrl  = TextEditingController();
  final _rxNotesCtrl   = TextEditingController();
  final _orderNoteCtrl = TextEditingController();
  XFile? _rxImage;
  bool _rxScanning = false;
  final _imagePicker = ImagePicker();

  Business get biz => widget.business;
  Color get color => biz.color;
  _Mode get mode => _modeFor(biz.businessTypeId);

  List<String> get _categories {
    final cats = biz.items.map((i) => i.category).toSet().toList();
    return ['All', ...cats];
  }

  List<BusinessItem> get _filtered {
    if (_selectedCategory == 'All') return biz.items;
    return biz.items.where((i) => i.category == _selectedCategory).toList();
  }

  List<String> get _rawCategories =>
      biz.items.map((i) => i.category).toSet().toList();

  Map<String, int> get _cart =>
      context.read<CartProvider>().itemsForBusiness(biz.id);

  int get _cartCount => _cart.values.fold(0, (s, q) => s + q);

  double get _cartTotal => _cart.entries.fold(0, (s, e) {
        final item = biz.items.firstWhere((i) => i.id == e.key,
            orElse: () => const BusinessItem(
                id: '', name: '', description: '', price: 0, category: ''));
        return s + item.price * e.value;
      });

  @override
  void initState() {
    super.initState();
    if (mode == _Mode.food) {
      _tabCtrl = TabController(length: _categories.length, vsync: this);
      _tabCtrl!.addListener(() {
        final tc = _tabCtrl;
        if (tc != null && !tc.indexIsChanging) {
          setState(() => _selectedCategory = _categories[tc.index]);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    _rxPatientCtrl.dispose();
    _rxDoctorCtrl.dispose();
    _rxNotesCtrl.dispose();
    _orderNoteCtrl.dispose();
    super.dispose();
  }

  void _add(String id) {
    final cart = context.read<CartProvider>();
    final ok = cart.addItem(businessId: biz.id, itemId: id);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can order from one shop at a time. Clear current cart first.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _remove(String id) {
    context.read<CartProvider>().removeItem(businessId: biz.id, itemId: id);
  }

  BusinessItem? _findIncludedItemByName(String label) {
    final q = label.trim().toLowerCase();
    if (q.isEmpty) return null;
    // Try exact contains match first.
    final hit = biz.items.where((i) => i.name.toLowerCase().contains(q)).toList();
    if (hit.isNotEmpty) return hit.first;

    // Try tokenized match (e.g. "Cold drink" -> "drink").
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.length >= 3).toList();
    for (final t in tokens) {
      final h = biz.items.where((i) => i.name.toLowerCase().contains(t)).toList();
      if (h.isNotEmpty) return h.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: mode == _Mode.food
            ? _foodBody()
            : mode == _Mode.shop
                ? _shopBody()
                : mode == _Mode.clinic
                    ? _clinicBody()
                    : _serviceBody(),
        bottomNavigationBar: _buildCartBar(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1.  FOOD MODE  (Restaurant / Café) — FoodPanda style
  // ══════════════════════════════════════════════════════════════════════════

  Widget _foodBody() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        _heroAppBar(),
        SliverToBoxAdapter(child: _infoStrip()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              indicatorColor: color,
              labelColor: color,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: _categories.map((c) => Tab(text: c)).toList(),
            ),
          ),
        ),
      ],
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _foodCard(_filtered[i]),
      ),
    );
  }

  Widget _foodCard(BusinessItem item) {
    final qty = _cart[item.id] ?? 0;
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: (item.imageUrl.isNotEmpty &&
                          !item.imageUrl.startsWith('http') &&
                          File(item.imageUrl).existsSync())
                      ? Image.file(
                          File(item.imageUrl),
                          width: double.infinity,
                          height: 165,
                          fit: BoxFit.cover,
                        )
                      : _netImg(
                          _img('${biz.id}_${item.id}',
                              _itemKw(biz.businessTypeId, item.name),
                              w: 700,
                              h: 360),
                          width: double.infinity,
                          height: 165,
                          fallback: AppAssetImage(
                            businessTypeId: biz.businessTypeId,
                            seed: '${biz.id}_${item.id}',
                            itemName: item.name,
                            width: double.infinity,
                            height: 165,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE10075),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isBundle
                          ? (biz.businessTypeId == 'restaurant' ||
                                  biz.businessTypeId == 'cafe'
                              ? 'COMBO'
                              : 'PACKAGE')
                          : (item.price >= 500 ? 'Order' : 'Deal'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 36,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '45\nMIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded,
                          size: 15, color: Colors.blueAccent),
                      Text(
                        ' ${biz.rating}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      Text(
                        '  ${biz.reviewCount}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)} • ${item.category} • Restaurant Own delivery',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (item.includes.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.includes
                          .take(4)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Includes ${item.includes.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    item.description,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      qty == 0
                          ? GestureDetector(
                              onTap: () => _add(item.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('+ Add',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            )
                          : _qtyControl(item.id, color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2.  SHOP MODE  (Grocery / Pharmacy / Others) — Imtiaz / Mart style
  // ══════════════════════════════════════════════════════════════════════════

  Widget _shopBody() {
    final allCats = _rawCategories;
    final showingAll = _selectedCategory == 'All';
    final offerItems = biz.items.where((i) => i.hasDiscount).toList();

    return CustomScrollView(
      slivers: [
        _heroAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoStrip(),

              // ── Prescription card (pharmacy only) ────────────────────────
              if (biz.businessTypeId == 'pharmacy')
                _buildPrescriptionCard(),

              // ── Promo banner ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _netImg(
                    _img('${biz.id}_banner', _bizKw(biz.businessTypeId), w: 800, h: 300),
                    width: double.infinity, height: 130,
                    fallback: AppAssetImage(
                      businessTypeId: biz.businessTypeId,
                      seed: '${biz.id}_banner',
                      itemName: null,
                      width: double.infinity,
                      height: 130,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              // ── Offers / Discounted items ────────────────────────────────
              if (offerItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 18, color: Color(0xFFE10075)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Offers for you',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${offerItems.length} deals',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: offerItems.length > 10 ? 10 : offerItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final it = offerItems[i];
                      final qty = _cart[it.id] ?? 0;
                      return GestureDetector(
                        onTap: () => _showItemDetail(it),
                        child: Container(
                          width: 260,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _netImg(
                                  _img('${biz.id}_${it.id}_offer',
                                      _itemKw(biz.businessTypeId, it.name),
                                      w: 240,
                                      h: 240),
                                  width: 76,
                                  height: 76,
                                  fallback: AppAssetImage(
                                    businessTypeId: biz.businessTypeId,
                                    seed: '${biz.id}_${it.id}_offer',
                                    itemName: it.name,
                                    width: 76,
                                    height: 76,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      it.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE10075),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${it.discountPercent.toStringAsFixed(0)}% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (it.originalPrice != null)
                                          Text(
                                            'Rs. ${it.originalPrice!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs. ${it.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              qty == 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        '+ Add',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : _qtyControl(it.id, color),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // ── Category heading ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shop by Category',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppColors.textPrimary)),
                    if (!showingAll)
                      GestureDetector(
                        onTap: () => setState(() => _selectedCategory = 'All'),
                        child: Text('View All',
                            style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),

              // ── Category grid or Product list ────────────────────────────
              showingAll
                  ? _aisleGrid(allCats)
                  : _productSection(_selectedCategory),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aisleGrid(List<String> cats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cats.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final count = biz.items.where((item) => item.category == cat).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Column(
              children: [
                // ── Category image tile ──────────────────────────────────
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _netImg(
                      _img('${cat}_cat', _catKw(cat, biz.businessTypeId), w: 200, h: 200),
                      width: double.infinity,
                      fallback: AppAssetImage(
                        businessTypeId: biz.businessTypeId,
                        seed: '${cat}_cat',
                        itemName: cat,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(cat,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
                Text('$count items',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _productSection(String cat) {
    final items = biz.items.where((i) => i.category == cat).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(cat,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, color: color)),
              const Spacer(),
              Text('${items.length} items',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _shopProductCard(item)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _shopProductCard(BusinessItem item) {
    final qty = _cart[item.id] ?? 0;
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _netImg(
                    _img('${biz.id}_${item.id}',
                        _itemKw(biz.businessTypeId, item.name),
                        w: 700,
                        h: 360),
                    width: double.infinity,
                    height: 145,
                    fallback: AppAssetImage(
                      businessTypeId: biz.businessTypeId,
                      seed: '${biz.id}_${item.id}',
                      itemName: item.name,
                      width: double.infinity,
                      height: 145,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (item.hasDiscount)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE10075),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(
                    item.unit != null
                        ? '${item.category} • ${item.unit}'
                        : item.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (item.includes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.includes
                          .take(4)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(item.description,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.hasDiscount && item.originalPrice != null)
                            Text(
                              'Rs. ${item.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            'Rs. ${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      qty == 0
                          ? GestureDetector(
                              onTap: () => _add(item.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('+ Add',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                            )
                          : _qtyControl(item.id, color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3.  CLINIC MODE  (OPD / Hospital)
  // ══════════════════════════════════════════════════════════════════════════

  IconData _clinicCatIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('consult')) return Icons.medical_services_rounded;
    if (c.contains('lab') || c.contains('test')) return Icons.biotech_rounded;
    if (c.contains('dental')) return Icons.sentiment_satisfied_rounded;
    if (c.contains('vacc')) return Icons.vaccines_rounded;
    if (c.contains('xray') || c.contains('x-ray') || c.contains('scan')) return Icons.image_search_rounded;
    if (c.contains('child') || c.contains('pediatr')) return Icons.child_care_rounded;
    if (c.contains('emergency')) return Icons.emergency_rounded;
    return Icons.add_box_rounded;
  }

  Widget _clinicBody() {
    final cats = _rawCategories;
    final filtered = _selectedCategory == 'All'
        ? biz.items
        : biz.items.where((i) => i.category == _selectedCategory).toList();

    return CustomScrollView(
      slivers: [
        _heroAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoStrip(),
              // ── OPD Banner ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPD Appointments',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: color)),
                        const SizedBox(height: 2),
                        Text('Book a slot — skip the waiting line',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: biz.isOpen
                          ? const Color(0xFF43A047).withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(
                          color: biz.isOpen
                              ? const Color(0xFF43A047)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(biz.isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: biz.isOpen
                                  ? const Color(0xFF43A047)
                                  : Colors.grey)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              // ── Department filter ────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Departments',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 78,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _deptChip('All', Icons.apps_rounded, _selectedCategory == 'All'),
                    ...cats.map((c) => _deptChip(c, _clinicCatIcon(c), _selectedCategory == c)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              // ── Appointment cards ────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Text('Available Services',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ...filtered.map((item) => _opdCard(item)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deptChip(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: selected ? Colors.white : color, size: 18),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _opdCard(BusinessItem item) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _netImg(
                    _img('${biz.id}_${item.id}',
                        _itemKw(biz.businessTypeId, item.name),
                        w: 700,
                        h: 360),
                    width: double.infinity,
                    height: 150,
                    fallback: Container(
                      width: double.infinity,
                      height: 150,
                      color: color.withValues(alpha: 0.1),
                      child: Icon(_clinicCatIcon(item.category),
                          color: color, size: 42),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.durationMinutes != null
                          ? '${item.durationMinutes} min'
                          : 'Slot',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 5),
                  Text(item.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  if (item.includes.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.includes
                          .take(4)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Text('Rs. ${item.price.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color)),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: biz.isOpen
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookSlotScreen(business: biz, item: item),
                                  ),
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: const Text('Book Now',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4.  SERVICE MODE  (Salon / Gym)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _serviceBody() {
    final cats = _rawCategories;
    final filtered = _selectedCategory == 'All'
        ? biz.items
        : biz.items.where((i) => i.category == _selectedCategory).toList();
    final offerItems = biz.items.where((i) => i.hasDiscount).toList();

    return CustomScrollView(
      slivers: [
        _heroAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoStrip(),
              const SizedBox(height: 20),

              // ── Offers / Discounted services ───────────────────────────
              if (offerItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_rounded,
                          size: 18, color: Color(0xFFE10075)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Deals & Discounts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${offerItems.length} offers',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: offerItems.length > 10 ? 10 : offerItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final it = offerItems[i];
                      return GestureDetector(
                        onTap: () => _showItemDetail(it),
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _netImg(
                                  _img('${biz.id}_${it.id}_offer',
                                      _itemKw(biz.businessTypeId, it.name),
                                      w: 240,
                                      h: 240),
                                  width: 76,
                                  height: 76,
                                  fallback: Container(
                                    width: 76,
                                    height: 76,
                                    color: color.withValues(alpha: 0.1),
                                    child: Icon(_serviceIcon(it.category),
                                        color: color, size: 34),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      it.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE10075),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            '${it.discountPercent.toStringAsFixed(0)}% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (it.originalPrice != null)
                                          Text(
                                            'Rs. ${it.originalPrice!.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rs. ${it.price.toStringAsFixed(0)}'
                                      '${it.unit != null ? ' / ${it.unit}' : ''}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── "Discover Services" heading ───────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Discover Services',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 10),

              // ── Compact horizontal category chips ─────────────────────
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return _serviceCatTile(
                        'All',
                        Icons.apps_rounded,
                        _selectedCategory == 'All',
                      );
                    }
                    final cat = cats[i - 1];
                    return _serviceCatTile(
                      cat,
                      _serviceIcon(cat),
                      _selectedCategory == cat,
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ── Services list ────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...filtered.map((item) => _serviceCard(item)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serviceCatTile(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(BusinessItem item) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _netImg(
                    _img('${biz.id}_${item.id}',
                        _itemKw(biz.businessTypeId, item.name),
                        w: 700,
                        h: 360),
                    width: double.infinity,
                    height: 150,
                    fallback: Container(
                      width: double.infinity,
                      height: 150,
                      color: color.withValues(alpha: 0.1),
                      child: Icon(_serviceIcon(item.category),
                          color: color, size: 40),
                    ),
                  ),
                ),
                if (item.hasDiscount)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE10075),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (item.includes.isNotEmpty)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${(biz.businessTypeId == 'restaurant' || biz.businessTypeId == 'cafe') ? 'COMBO' : 'PACKAGE'} • ${item.includes.length} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(item.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (item.includes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Includes: ${item.includes.take(3).join(', ')}'
                      '${item.includes.length > 3 ? '…' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (item.includes.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.includes
                          .take(4)
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: color.withValues(alpha: 0.18)),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      if (item.durationMinutes != null) ...[
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text('${item.durationMinutes} min',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.hasDiscount && item.originalPrice != null)
                            Text(
                              'Rs. ${item.originalPrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            'Rs. ${item.price.toStringAsFixed(0)}'
                            '${item.unit != null ? ' / ${item.unit}' : ''}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16, color: color),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: biz.isOpen
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookSlotScreen(
                                      business: biz,
                                      item: item,
                                    ),
                                  ),
                                )
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        child: Text(biz.actionLabel,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetail(BusinessItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final qty = _cart[item.id] ?? 0;
          final isBookable = mode == _Mode.service || mode == _Mode.clinic;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _netImg(
                      _img('${biz.id}_${item.id}',
                          _itemKw(biz.businessTypeId, item.name),
                          w: 700,
                          h: 420),
                      width: double.infinity,
                      height: 180,
                      fallback: AppAssetImage(
                        businessTypeId: biz.businessTypeId,
                        seed: '${biz.id}_${item.id}',
                        itemName: item.name,
                        width: double.infinity,
                        height: 180,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.durationMinutes != null)
                        const Text(
                          'Duration available',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.description.isEmpty
                        ? 'No additional description'
                        : item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.includes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Includes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...item.includes.map((t) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (item.includes.isNotEmpty && !isBookable) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 18),
                            Text(
                              'Add items separately (optional)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: item.includes.map((label) {
                                final match = _findIncludedItemByName(label);
                                final canAdd = match != null;
                                return OutlinedButton.icon(
                                  onPressed: canAdd
                                      ? () {
                                          final ok = context
                                              .read<CartProvider>()
                                              .addItem(
                                                businessId: biz.id,
                                                itemId: match.id,
                                              );
                                          if (!ok) return;
                                          setSheet(() {});
                                          setState(() {});
                                        }
                                      : null,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: Text(
                                    canAdd ? label : '$label (not found)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: canAdd ? color : AppColors.border,
                                    ),
                                    foregroundColor:
                                        canAdd ? color : AppColors.textHint,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Rs. ${item.price.toStringAsFixed(0)}'
                        '${item.unit != null ? ' / ${item.unit}' : ''}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const Spacer(),
                      if (!isBookable)
                        qty == 0
                            ? ElevatedButton(
                                onPressed: () {
                                  _add(item.id);
                                  setSheet(() {});
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('+ Add to Cart'),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _remove(item.id);
                                        setSheet(() {});
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.remove_rounded),
                                    ),
                                    Text('$qty',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      onPressed: () {
                                        _add(item.id);
                                        setSheet(() {});
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                    ),
                                  ],
                                ),
                              )
                      else
                        ElevatedButton(
                          onPressed: biz.isOpen
                              ? () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookSlotScreen(
                                        business: biz,
                                        item: item,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(biz.actionLabel),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Shared: Hero App Bar ──────────────────────────────────────────────────

  SliverAppBar _heroAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: color,
      actions: [
        if (mode != _Mode.service)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'View cart',
                  onPressed: _cartCount == 0 ? null : _showCartSummary,
                  icon: const Icon(Icons.shopping_cart_rounded),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover photo
            _netImg(
              _img('${biz.id}_hero', _bizKw(biz.businessTypeId), w: 800, h: 400),
              width: double.infinity, height: double.infinity,
              fallback: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Dark gradient overlay at bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Business info at bottom
            Positioned(
              bottom: 16, left: 16, right: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(biz.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black45)
                          ])),
                  if (biz.tagline != null)
                    Text(biz.tagline!,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                ],
              ),
            ),
            // Open badge
            Positioned(
              bottom: 16, right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: biz.isOpen
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  biz.isOpen ? 'Open' : 'Closed',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info strip ────────────────────────────────────────────────────────────

  Widget _infoStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(biz.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip(Icons.star_rounded,
                  '${biz.rating}  (${biz.reviewCount})', Colors.amber),
              const SizedBox(width: 10),
              _chip(Icons.inventory_2_outlined,
                  '${biz.items.length} items', color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: c, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── Qty +/- control ───────────────────────────────────────────────────────

  Widget _qtyControl(String id, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _remove(id),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  border: Border.all(color: c), shape: BoxShape.circle),
              child: Icon(Icons.remove, color: c, size: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${_cart[id]}',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: c)),
          ),
          GestureDetector(
            onTap: () => _add(id),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      );

  // ── Prescription card & sheet (pharmacy) ─────────────────────────────────

  Widget _buildPrescriptionCard() {
    return GestureDetector(
      onTap: _showPrescriptionSheet,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order by Prescription',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  _rxItems.isEmpty
                      ? 'Tap to enter medicines clearly — doctor ki writing ki zaroorat nahi'
                      : '${_rxItems.length} medicine${_rxItems.length > 1 ? 's' : ''} added — tap to edit',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _rxItems.isEmpty ? 'Add' : 'Edit',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _pickAndScan(
      ImageSource source, StateSetter setSheet) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file == null) return;

      // Show scanning state
      setSheet(() {
        _rxImage = file;
        _rxScanning = true;
      });
      if (mounted) {
        setState(() {
          _rxImage = file;
          _rxScanning = true;
        });
      }

      // Simulate OCR processing delay
      await AsyncGuard.withTimeout(
        Future.delayed(const Duration(milliseconds: 2200)),
        timeout: const Duration(seconds: 10),
      );

      // Auto-fill medicines from "scan"
      _rxItems.clear();
      for (final m in _ocrMedicines) {
        _rxItems.add(_RxEntry()
          ..name = m.name
          ..dosage = m.dosage
          ..qty = m.qty
          ..days = m.days
          ..price = m.price);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AsyncGuard.friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setSheet(() => _rxScanning = false);
      if (mounted) setState(() => _rxScanning = false);
    }
  }

  void _showPrescriptionSheet() {
    // Ensure at least one empty entry
    if (_rxItems.isEmpty && _rxImage == null) _rxItems.add(_RxEntry());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void addEntry() {
            setSheet(() => _rxItems.add(_RxEntry()));
          }

          void removeEntry(int i) {
            if (_rxItems.length > 1) setSheet(() => _rxItems.removeAt(i));
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(children: [
                    Icon(Icons.medication_rounded, color: color, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Prescription Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.textPrimary)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Prescription scan karo ya khud medicines likhein',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // ── Scan prescription section ────────────────────────────
                  if (_rxScanning) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(children: [
                        SizedBox(
                          width: 36, height: 36,
                          child: CircularProgressIndicator(
                              color: color, strokeWidth: 3),
                        ),
                        const SizedBox(height: 12),
                        Text('Prescription scan ho rahi hai...',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Medicines detect ki ja rahi hain',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ] else if (_rxImage != null) ...[
                    // Image preview + re-scan option
                    Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_rxImage!.path),
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: GestureDetector(
                          onTap: () => _pickAndScan(
                              ImageSource.camera, setSheet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text('Re-scan',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                '${_rxItems.where((e) => e.name.isNotEmpty).length} medicines detected',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                  ] else ...[
                    // Scan buttons
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickAndScan(
                              ImageSource.camera, setSheet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 26),
                                SizedBox(height: 6),
                                Text('Camera sy\nScan Karo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickAndScan(
                              ImageSource.gallery, setSheet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_rounded,
                                    color: color, size: 26),
                                const SizedBox(height: 6),
                                Text('Gallery sy\nUpload Karo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('ya khud likhein',
                            style: TextStyle(
                                fontSize: 11,
                                color: color.withValues(alpha: 0.7))),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 10),
                  ],

                  // Patient & Doctor
                  _rxField('Patient Name', _rxPatientCtrl,
                      Icons.person_outline, 'Mara naam...', setSheet),
                  const SizedBox(height: 10),
                  _rxField('Doctor Name (optional)', _rxDoctorCtrl,
                      Icons.local_hospital_outlined, 'Dr. ...', setSheet),
                  const SizedBox(height: 18),

                  // Medicines header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Medicines',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      GestureDetector(
                        onTap: addEntry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: color.withValues(alpha: 0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, color: color, size: 16),
                            const SizedBox(width: 4),
                            Text('Add Medicine',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Medicine rows
                  ..._rxItems.asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: entry.name,
                              onChanged: (v) => entry.name = v,
                              decoration: InputDecoration(
                                hintText: 'Medicine name (e.g. Panadol)',
                                hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          if (_rxItems.length > 1)
                            GestureDetector(
                              onTap: () => removeEntry(i),
                              child: Icon(Icons.close_rounded,
                                  color: AppColors.textHint, size: 18),
                            ),
                        ]),
                        const Divider(height: 14),
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: entry.dosage,
                              onChanged: (v) => entry.dosage = v,
                              decoration: const InputDecoration(
                                hintText: 'Dosage (e.g. 1 tab 2x daily)',
                                hintStyle: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                prefixIcon: Icon(Icons.schedule_rounded,
                                    size: 14, color: AppColors.textHint),
                              ),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1, height: 28,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 56,
                            child: TextFormField(
                              initialValue: entry.qty,
                              onChanged: (v) => entry.qty = v,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: 'Qty',
                                hintStyle: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const Text('pcs',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ]),
                        const Divider(height: 14),
                        // Days + Price row
                        Row(children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          const Text('Din:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 40,
                            child: TextFormField(
                              initialValue: entry.days,
                              onChanged: (v) {
                                entry.days = v;
                                setSheet(() {});
                              },
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          const Text('din',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const Spacer(),
                          Container(
                              width: 1, height: 20, color: AppColors.border),
                          const SizedBox(width: 10),
                          const Text('Rs.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 64,
                            child: TextFormField(
                              initialValue: entry.price,
                              onChanged: (v) {
                                entry.price = v;
                                setSheet(() {});
                              },
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: color),
                            ),
                          ),
                        ]),
                      ]),
                    );
                  }),

                  // Bill summary
                  Builder(builder: (_) {
                    final total = _rxItems.fold<double>(0, (sum, e) {
                      final p = double.tryParse(e.price) ?? 0;
                      final q = double.tryParse(e.qty) ?? 1;
                      return sum + p * q;
                    });
                    if (total <= 0) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Column(children: [
                        ..._rxItems.where((e) => e.name.isNotEmpty && (double.tryParse(e.price) ?? 0) > 0).map((e) {
                          final p = double.tryParse(e.price) ?? 0;
                          final q = double.tryParse(e.qty) ?? 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              Expanded(
                                child: Text(e.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('${q.toInt()} × Rs.${p.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(width: 8),
                              Text('Rs.${(p * q).toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            ]),
                          );
                        }),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                            Text('Rs. ${total.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: color)),
                          ],
                        ),
                      ]),
                    );
                  }),

                  // Notes
                  const SizedBox(height: 4),
                  TextField(
                    controller: _rxNotesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Extra note pharmacist k liye (optional)...',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final valid = _rxItems.any((e) => e.name.isNotEmpty);
                        if (!valid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Kam az kam ek medicine ka naam zaroor likhein'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        setState(() {}); // refresh card badge
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                'Prescription bhej di gayi — ${_rxItems.where((e) => e.name.isNotEmpty).length} medicine(s)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ]),
                            backgroundColor: color,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Prescription Submit Karo',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rxField(String label, TextEditingController ctrl,
      IconData icon, String hint, StateSetter setSheet) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => setSheet(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 12, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 18, color: color),
        filled: true,
        fillColor: AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ── Cart bottom bar ───────────────────────────────────────────────────────

  Widget? _buildCartBar() {
    if (mode == _Mode.service) return null;
    if (_cartCount == 0) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_cartCount item${_cartCount > 1 ? 's' : ''}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rs. ${_grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (biz.hasDelivery && _deliverySelected)
                  Text(
                    'incl. Rs.${_deliveryFee.toStringAsFixed(0)} delivery',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showCartSummary,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Cart',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _deliveryFee =>
      _deliverySelected ? biz.deliveryFeeFor(_deliveryDistanceKm) : 0;

  double get _grandTotal => _cartTotal + _deliveryFee;

  Future<void> _confirmAndPlaceOrder({bool? isDelivery}) async {
    final deliverySelected = isDelivery ?? _deliverySelected;
    final authProv = context.read<AuthProvider>();
    final orderProv = context.read<OrderProvider>();
    final cartProv = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final shouldPlace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          deliverySelected
              ? 'Place delivery order for Rs. ${_grandTotal.toStringAsFixed(0)}?'
              : 'Confirm pickup order for Rs. ${_grandTotal.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Place Order'),
          ),
        ],
      ),
    );
    if (shouldPlace != true) return;

    final bizTypeName = BusinessType.all
        .firstWhere((t) => t.id == biz.businessTypeId,
            orElse: () => BusinessType(
                  id: biz.businessTypeId,
                  title: biz.businessTypeId,
                  icon: Icons.store,
                  imageUrl: '',
                  categories: [],
                  color: color,
                ))
        .title;

    final phone = authProv.userEmail ?? '0300-0000000';
    final optionalNote = _orderNoteCtrl.text.trim();
    final baseNote = deliverySelected
        ? 'Delivery • ${_deliveryDistanceKm.toStringAsFixed(1)} km'
        : 'Pickup';
    final newOrder = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      customerId: phone,
      customerName: 'Customer',
      customerPhone: phone,
      businessTypeId: biz.businessTypeId,
      businessTypeName: bizTypeName,
      isDelivery: deliverySelected,
      deliveryCharge: deliverySelected ? _deliveryFee : 0,
      notes: optionalNote.isEmpty
          ? baseNote
          : '$baseNote\nNote: $optionalNote',
      items: _cart.entries.map((e) {
        final item = biz.items.firstWhere((i) => i.id == e.key);
        return OrderItem(
          productId: item.id,
          productName: item.name,
          quantity: e.value,
          unitPrice: item.price,
        );
      }).toList(),
      status: OrderStatus.pending,
    );
    orderProv.addOrder(newOrder);

    if (mounted) {
      navigator.pop();
      cartProv.clearBusinessCart(biz.id);
      _orderNoteCtrl.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              deliverySelected
                  ? 'Order placed! Delivery on the way.'
                  : 'Order confirmed! Ready for pickup.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ]),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showCartSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final canDelivery = biz.hasDelivery;
          // If delivery isn't supported by this business, default to pickup
          // so user isn't stuck on "delivery" silently.
          if (!canDelivery && _deliverySelected) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _deliverySelected = false);
            });
          }

          final cartItems = _cart.entries.map((e) {
            final item = biz.items.firstWhere((i) => i.id == e.key);
            return MapEntry(item, e.value);
          }).toList();
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Handle ──────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(biz.typeIcon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(biz.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                ),
              ]),
              const SizedBox(height: 14),

              // ── Delivery / Pickup toggle (only if business delivers) ─
              // Pickup: always available for food businesses.
              // Delivery: only available when `biz.hasDelivery == true`.
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: canDelivery
                          ? () {
                              // Only rebuild the bottom-sheet UI here.
                              // We still update the outer state field so order uses it.
                              setSheet(() => _deliverySelected = true);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: (_deliverySelected && canDelivery)
                              ? color
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining_rounded,
                                color: (_deliverySelected && canDelivery)
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Delivery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: (_deliverySelected && canDelivery)
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setSheet(() => _deliverySelected = false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_deliverySelected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_rounded,
                                color: !_deliverySelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Pickup',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_deliverySelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Cart items ───────────────────────────────────────────
              const Divider(),
              ...cartItems.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _netImg(
                        _img('${biz.id}_${e.key.id}', _itemKw(biz.businessTypeId, e.key.name), w: 100, h: 100),
                        width: 40, height: 40,
                        fallback: AppAssetImage(
                          businessTypeId: biz.businessTypeId,
                          seed: '${biz.id}_${e.key.id}',
                          itemName: e.key.name,
                          width: 40,
                          height: 40,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.key.name,
                        style: const TextStyle(fontSize: 14))),
                    Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              context.read<CartProvider>().removeItem(
                                    businessId: biz.id,
                                    itemId: e.key.id,
                                  );
                              setSheet(() {});
                              setState(() {});
                              if (_cartCount == 0 && context.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Text(
                            '${e.value}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            iconSize: 18,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              context.read<CartProvider>().addItem(
                                    businessId: biz.id,
                                    itemId: e.key.id,
                                  );
                              setSheet(() {});
                              setState(() {});
                            },
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Rs. ${(e.key.price * e.value).toStringAsFixed(0)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: color)),
                    IconButton(
                      tooltip: 'Delete item',
                      onPressed: () {
                        context.read<CartProvider>().removeItem(
                              businessId: biz.id,
                              itemId: e.key.id,
                              quantity: e.value,
                            );
                        setSheet(() {});
                        setState(() {});
                        if (_cartCount == 0 && context.mounted) {
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Bill breakdown ───────────────────────────────────────
              const Divider(),
              _billRow('Subtotal', _cartTotal, color),
              if (canDelivery && _deliverySelected) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.delivery_dining_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Delivery (${_deliveryDistanceKm.toStringAsFixed(1)} km'
                      ' · Rs.${_deliveryFee.toStringAsFixed(0)})',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  Text('Rs. ${_deliveryFee.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                ]),
              ],
              if (!canDelivery || !_deliverySelected) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.storefront_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text('Pickup — no delivery charge',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ),
                  const Text('Free',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF43A047))),
                ]),
              ],
              const SizedBox(height: 10),
              const Divider(thickness: 1.5),
              _billRow('Total', _grandTotal, color, large: true),
              const SizedBox(height: 16),
              TextField(
                controller: _orderNoteCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Optional note (e.g. gate pe call karna)',
                  hintStyle: const TextStyle(
                      color: AppColors.textHint, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: color.withValues(alpha: 0.7)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Confirm button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                      onPressed: () => _confirmAndPlaceOrder(isDelivery: _deliverySelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _deliverySelected ? 'Confirm Order • Rs. ${_grandTotal.toStringAsFixed(0)}' : 'Confirm Pickup • Rs. ${_grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _billRow(String label, double amount, Color c, {bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: large ? FontWeight.bold : FontWeight.w500,
                fontSize: large ? 16 : 14,
                color: large ? AppColors.textPrimary : AppColors.textSecondary)),
        Text('Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: large ? 18 : 14,
                color: large ? c : AppColors.textPrimary)),
      ],
    );
  }
}

// ── Sliver Tab Bar delegate ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppColors.surface, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_) => false;
}

// ── Prescription entry model ──────────────────────────────────────────────────

class _RxEntry {
  String name;
  String dosage;
  String qty;
  String days;
  String price;
  _RxEntry()
      : name = '',
        dosage = '',
        qty = '1',
        days = '7',
        price = '';
}

class _RxOcr {
  final String name, dosage, qty, days, price;
  const _RxOcr(this.name, this.dosage, this.qty, this.days, this.price);
}

const _ocrMedicines = [
  _RxOcr('Augmentin 625mg',  '1 tab 2x daily',        '14', '7',  '480'),
  _RxOcr('Panadol 500mg',    '1-2 tabs 3x daily',      '20', '7',  '90'),
  _RxOcr('Omeprazole 20mg',  '1 cap before breakfast', '7',  '7',  '210'),
];
