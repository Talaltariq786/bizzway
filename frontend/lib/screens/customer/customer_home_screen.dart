import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/maps/map_location_picker_screen.dart';
import '../../core/maps/map_location_result.dart';
import '../../models/business.dart';
import '../../models/business_type.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_marketplace_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/api_catalog_provider.dart';
import 'business_detail_screen.dart';
import 'customer_orders_screen.dart';
import 'my_bookings_screen.dart';
import 'near_me_screen.dart';
import '../../widgets/common/sliding_drawer_shell.dart';
import '../../widgets/common/customer_side_drawer.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedNav = 0;
  int _selectedTopMiniCard = 0;
  String _selectedBizType = 'all'; // 'all' | any BusinessType.id
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<SlidingDrawerShellState> _drawerKey =
      GlobalKey<SlidingDrawerShellState>();

  Future<void> _refreshMarketplaceForLocation() async {
    if (!mounted) return;
    final a = context.read<LocationProvider>().selectedAddress;
    await context.read<CustomerMarketplaceProvider>().refresh(
          nearLat: a.lat,
          nearLng: a.lng,
          radiusKm: 40,
        );
  }

  Future<String?> _askNewAddressLabel() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Naya address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('Home'),
              onTap: () => Navigator.pop(ctx, 'Home'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.business_rounded, color: AppColors.primary),
              title: const Text('Office'),
              onTap: () => Navigator.pop(ctx, 'Office'),
            ),
            ListTile(
              leading: const Icon(Icons.place_rounded, color: AppColors.primary),
              title: const Text('Other'),
              onTap: () => Navigator.pop(ctx, 'Other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  IconData _iconForLabel(String label) {
    switch (label) {
      case 'Office':
        return Icons.business_rounded;
      case 'Home':
        return Icons.home_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (BusinessType.excludedFromCustomerBrowse.contains(_selectedBizType)) {
        setState(() => _selectedBizType = 'all');
      }
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        await context.read<OrderProvider>().refreshFromApi();
      }
      if (!mounted) return;
      final loc = context.read<LocationProvider>();
      final a = loc.selectedAddress;
      await context.read<CustomerMarketplaceProvider>().refresh(
            nearLat: a.lat,
            nearLng: a.lng,
            radiusKm: 40,
          );
    });
  }

  /// Respects browse chips: Café / Others / Near Me types map to "all".
  String get _effectiveBrowseTypeId {
    if (_selectedBizType == 'all') return 'all';
    if (BusinessType.excludedFromCustomerBrowse.contains(_selectedBizType)) {
      return 'all';
    }
    return _selectedBizType;
  }

  final List<Map<String, dynamic>> _offers = [
    {
      'title': '20% OFF First Booking',
      'subtitle': 'Use code: FIRST20',
      'colors': [const Color(0xFF6C63FF), const Color(0xFF9B59B6)],
      'icon': Icons.local_offer_rounded,
    },
    {
      'title': 'Free Delivery Today',
      'subtitle': 'On grocery & pharmacy orders',
      'colors': [const Color(0xFF43A047), const Color(0xFF00BCD4)],
      'icon': Icons.delivery_dining_rounded,
    },
    {
      'title': 'Weekend Special',
      'subtitle': 'Spa + Facial @ Rs. 2499',
      'colors': [const Color(0xFFE91E8C), const Color(0xFFFF6584)],
      'icon': Icons.star_rounded,
    },
  ];

  List<Business> _visibleBusinesses(CustomerMarketplaceProvider mp) {
    return mp.filtered(
      effectiveBrowseTypeId: _effectiveBrowseTypeId,
      searchQuery: _searchQuery,
    );
  }

  List<Business> _topRated(CustomerMarketplaceProvider mp) {
    final list = [..._visibleBusinesses(mp)]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(6).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlidingDrawerShell(
      key: _drawerKey,
      drawer: CustomerSideDrawer(
        selectedIndex: _selectedNav,
        onSelectTab: (i) => setState(() => _selectedNav = i),
        onClose: () => _drawerKey.currentState?.closeDrawer(),
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Stack(
          children: [
            _selectedNav == 0
                ? _buildHome()
                : _selectedNav == 1
                    ? const NearMeScreen()
                    : _selectedNav == 2
                        ? _buildCartTab()
                        : _selectedNav == 3
                            ? const MyBookingsScreen()
                            : const CustomerOrdersScreen(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              child: Material(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _drawerKey.currentState?.toggleDrawer(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.menu_rounded, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final cartCount = context.watch<CartProvider>().hasItems 
        ? context.watch<CartProvider>().itemCountForBusiness(
            context.watch<CartProvider>().businessId!) 
        : 0;
    final orderCount = context.watch<OrderProvider>().orders.length;

    final labels = ['Home', 'Near Me', 'Cart', 'Bookings', 'Orders'];

    return CurvedNavigationBar(
      index: _selectedNav,
      height: 75,
      items: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 24, color: Colors.white),
            if (_selectedNav != 0) ...[
              const SizedBox(height: 2),
              Text(labels[0], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.near_me_outlined, size: 24, color: Colors.white),
            if (_selectedNav != 1) ...[
              const SizedBox(height: 2),
              Text(labels[1], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: cartCount > 0 ? Text('$cartCount', style: const TextStyle(fontSize: 8)) : null,
              backgroundColor: const Color(0xFFE91E3F),
              child: Icon(Icons.shopping_cart_outlined, size: 24, color: Colors.white),
            ),
            if (_selectedNav != 2) ...[
              const SizedBox(height: 2),
              Text(labels[2], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 24, color: Colors.white),
            if (_selectedNav != 3) ...[
              const SizedBox(height: 2),
              Text(labels[3], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: orderCount > 0 ? Text('$orderCount', style: const TextStyle(fontSize: 8)) : null,
              backgroundColor: const Color(0xFFE91E3F),
              child: Icon(Icons.receipt_long_outlined, size: 24, color: Colors.white),
            ),
            if (_selectedNav != 4) ...[
              const SizedBox(height: 2),
              Text(labels[4], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ],
      onTap: (index) {
        setState(() => _selectedNav = index);
      },
      backgroundColor: Colors.transparent,
      color: AppColors.primary,
      animationDuration: const Duration(milliseconds: 400),
      animationCurve: Curves.easeInOut,
    );
  }

  // ── Home ─────────────────────────────────────────────────────────────────

  Widget _buildHome() {
    final mp = context.watch<CustomerMarketplaceProvider>();
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mp.isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                  ),
                ),
              if (mp.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Shops: ${mp.error}',
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              _buildTopMiniCards(),
              _buildExpandedTopCard(),
              _buildLiveBusiness(), // ← live owner bridge
              _buildOffersCarousel(),
              _buildCategoryGrid(),
              _buildTopRated(),
              _buildAllBusinesses(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedTopCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(_selectedTopMiniCard),
        child: () {
          if (_selectedTopMiniCard == 0) return _buildAddressBar();
          if (_selectedTopMiniCard == 1) return _buildSearchBar();
          if (_selectedTopMiniCard == 2) return _buildAzanCard();
          return _buildUpcomingBooking();
        }(),
      ),
    );
  }

  Widget _buildTopMiniCards() {
    final loc = context.watch<LocationProvider>();
    final upcoming = context.watch<AppointmentProvider>().upcoming;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _topMiniCard(
              idx: 0,
              icon: Icons.home_rounded,
              title: 'Address',
              subtitle: loc.selectedAddress.label,
              onTap: () => _showAddressSheet(loc),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _topMiniCard(
              idx: 1,
              icon: Icons.search_rounded,
              title: 'Search',
              subtitle: 'Find',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _topMiniCard(
              idx: 2,
              icon: Icons.mosque_rounded,
              title: 'Prayer',
              subtitle: loc.nextPrayer.name,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _topMiniCard(
              idx: 3,
              icon: Icons.calendar_month_rounded,
              title: 'Upcoming',
              subtitle: upcoming.isEmpty ? 'None' : '1',
              onTap: () => setState(() => _selectedNav = 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topMiniCard({
    required int idx,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final selected = _selectedTopMiniCard == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTopMiniCard = idx);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.primary),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: selected
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartTab() {
    final mp = context.watch<CustomerMarketplaceProvider>();
    final cart = context.watch<CartProvider>();
    final cartBiz = _resolveCartBusiness();
    final bizId = cart.businessId;
    final cartItems = bizId == null ? const <MapEntry<String, int>>[] : cart.itemsForBusiness(bizId).entries.toList();
    final headerTitle = cartBiz?.name ?? 'No active cart';

    if (bizId == null || cartItems.isEmpty || cartBiz == null) {
      return SafeArea(
        child: Column(
          children: [
            _buildCartHeader(headerTitle, () {
              if (bizId != null) {
                cart.clearBusinessCart(bizId);
              }
            }),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                  const SizedBox(height: 48),
                  const Icon(Icons.shopping_cart_checkout_rounded,
                      size: 56, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Add items from a shop to start checkout',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedNav = 0),
                          icon: const Icon(Icons.storefront_rounded),
                          label: const Text('Browse Shops'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _selectedNav = 1),
                          icon: const Icon(Icons.near_me_rounded),
                          label: const Text('Near Me'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Suggested for you', 'Top picks'),
                  const SizedBox(height: 10),
                  ..._topRated(mp).take(3).map((b) => _cartSuggestCard(b)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final subtotal = cartItems.fold<double>(0, (sum, e) {
      final item = cartBiz.items.firstWhere(
        (x) => x.id == e.key,
        orElse: () => const BusinessItem(
          id: '',
          name: 'Item',
          description: '',
          price: 0,
          category: '',
        ),
      );
      return sum + (item.price * e.value);
    });

    return SafeArea(
      child: Column(
        children: [
          _buildCartHeader(cartBiz.name, () => cart.clearBusinessCart(bizId)),
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final entry = cartItems[index];
                final item = cartBiz.items.firstWhere(
                  (x) => x.id == entry.key,
                  orElse: () => const BusinessItem(
                    id: '',
                    name: 'Item',
                    description: '',
                    price: 0,
                    category: '',
                  ),
                );
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${item.price.toStringAsFixed(0)} each',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => cart.removeItem(
                          businessId: bizId,
                          itemId: entry.key,
                        ),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text(
                        '${entry.value}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        onPressed: () => cart.addItem(
                          businessId: bizId,
                          itemId: entry.key,
                        ),
                        icon: const Icon(Icons.add_circle_rounded,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rs. ${(item.price * entry.value).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Subtotal',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        'Rs. ${subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _open(cartBiz),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Open Shop Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartHeader(String businessName, VoidCallback onClear) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientPrimary,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_rounded,
                color: Colors.white, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartSuggestCard(Business biz) {
    return GestureDetector(
      onTap: () => _open(biz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: biz.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(biz.typeIcon, color: biz.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    biz.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'From Rs. ${_minPrice(biz)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  // ── Live owner business (Provider bridge) ─────────────────────────────────

  Widget _buildLiveBusiness() {
    final bizProv = context.watch<BusinessProvider>();
    final prodProv = context.watch<ProductProvider>();
    final apiCat = context.watch<ApiCatalogProvider>();

    // Only show if owner has set up a business
    if (bizProv.selectedBusiness == null) return const SizedBox.shrink();

    // Filter by selected category if any
    if (_selectedBizType != 'all' &&
        _selectedBizType != bizProv.selectedBusiness!.id) {
      return const SizedBox.shrink();
    }

    final allowedCategories = bizProv.categories.toSet();
    final bizId = bizProv.selectedBusiness!.id;
    final scopedProducts = apiCat.products.isNotEmpty
        ? apiCat.products
            .where((p) => allowedCategories.contains(p.category))
            .toList()
        : prodProv.productsForBusiness(bizId).where((p) => allowedCategories.contains(p.category)).toList();
    final scopedDeals = prodProv.activeDealsForBusiness(bizId);
    final filteredProducts = scopedProducts;

    final wantsDelivery = bizProv.hasDelivery;
    final liveBiz = Business.fromOwner(
      businessName: bizProv.businessName,
      businessTypeId: bizProv.selectedBusiness!.id,
      color: bizProv.selectedBusiness!.color,
      products: filteredProducts,
      deliveryBaseCharge: wantsDelivery ? bizProv.deliveryBaseCharge : null,
      deliveryPerKmCharge: wantsDelivery ? bizProv.deliveryPerKmCharge : null,
      deliveryRadiusKm: wantsDelivery ? bizProv.deliveryRadiusKm : null,
    );

    // Search filter
    if (_searchQuery.isNotEmpty &&
        !liveBiz.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
        !liveBiz.businessTypeId.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 5),
                  const Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('Registered on BizzWay',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _open(liveBiz),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: liveBiz.color.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: liveBiz.color.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [liveBiz.color, liveBiz.color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(liveBiz.typeIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(liveBiz.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Open',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      Text(liveBiz.tagline ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,
                              fontStyle: FontStyle.italic)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 13, color: liveBiz.color),
                        const SizedBox(width: 4),
                        Text(
                          '${scopedProducts.where((p) => p.isAvailable).length} items live',
                          style: TextStyle(
                              fontSize: 12,
                              color: liveBiz.color,
                              fontWeight: FontWeight.w600),
                        ),
                        if (scopedDeals.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.local_offer_rounded,
                              size: 13, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            '${scopedDeals.length} deals',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient header ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    final auth = context.read<AuthProvider>();
    final name = auth.userEmail?.split('@').first ?? 'Guest';
    final h = DateTime.now().hour;
    final greeting = h < 12
        ? 'Good Morning ☀️'
        : h < 17
            ? 'Good Afternoon 🌤️'
            : 'Good Evening 🌙';

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientPrimary,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20, right: 20, bottom: 24,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Karachi, Pakistan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headerBtn(Icons.notifications_outlined, () {}),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Address bar ───────────────────────────────────────────────────────────

  Widget _buildAddressBar() {
    final loc = context.watch<LocationProvider>();
    final addr = loc.selectedAddress;
    return GestureDetector(
      onTap: () => _showAddressSheet(loc),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(addr.icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivering to',
                    style: TextStyle(
                        fontSize: 8.5,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500)),
                Text(addr.address,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(addr.label,
                style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more_rounded,
              size: 16, color: AppColors.textHint),
        ]),
      ),
    );
  }

  void _showAddressSheet(LocationProvider loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Choose Delivery Address',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 14),
              ...loc.addresses.map((a) {
                final isSelected = loc.selectedAddress.id == a.id;
                return GestureDetector(
                  onTap: () {
                    loc.selectAddress(a.id);
                    Navigator.pop(context);
                    unawaited(_refreshMarketplaceForLocation());
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(children: [
                      Icon(a.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary)),
                            Text(a.address,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await Future<void>.delayed(Duration.zero);
                  if (!mounted) return;
                  final label = await _askNewAddressLabel();
                  if (label == null || !mounted) return;
                  final locProv = context.read<LocationProvider>();
                  final seed = locProv.selectedAddress;
                  final r = await Navigator.of(context).push<MapLocationResult>(
                    MaterialPageRoute<MapLocationResult>(
                      fullscreenDialog: true,
                      builder: (_) => MapLocationPickerScreen(
                        initialLat: seed.lat ?? 24.8607,
                        initialLng: seed.lng ?? 67.0011,
                        title: 'Naya pin',
                      ),
                    ),
                  );
                  if (r == null || !mounted) return;
                  locProv.addAddress(
                    label,
                    r.addressLine,
                    _iconForLabel(label),
                    lat: r.lat,
                    lng: r.lng,
                  );
                  await _refreshMarketplaceForLocation();
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_location_alt_rounded,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Add New Address (map)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 14)),
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

  // ── Azan / prayer times card ──────────────────────────────────────────────

  Widget _buildAzanCard() {
    final loc = context.watch<LocationProvider>();
    final next = loc.nextPrayer;
    final countdown = loc.nextPrayerCountdown;
    final screenW = MediaQuery.of(context).size.width;
    // Show 4 boxes per row within horizontal list (account for horizontal padding 16*2 and 3 gaps of 5px)
    final double prayerBoxWidth = ((screenW - 32) - (3 * 5)) / 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A5C), Color(0xFF0D7377)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.mosque_rounded, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              const Text('Prayer Times · Karachi',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(next.icon, color: Colors.amber, size: 11),
                  const SizedBox(width: 2.5),
                  Text('${next.name} in $countdown',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.2,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: loc.prayerTimes.length,
                itemBuilder: (_, i) {
                  final p = loc.prayerTimes[i];
                  final isNext = p.name == next.name;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: prayerBoxWidth,
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 3.5),
                    decoration: BoxDecoration(
                      color: isNext
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: isNext
                          ? Border.all(
                              color: Colors.amber.withValues(alpha: 0.7),
                              width: 1.5)
                          : null,
                      boxShadow: isNext
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.nameUrdu,
                            style: TextStyle(
                                fontSize: 10,
                                color: isNext
                                    ? Colors.amber
                                    : Colors.white70,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 1),
                        Text(loc.formatPrayerTime(p.time),
                            style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white60)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search restaurant, salon, gym...',
          hintStyle:
              const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textHint),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  })
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  // ── Upcoming booking reminder ─────────────────────────────────────────────

  Widget _buildUpcomingBooking() {
    final upcoming = context.watch<AppointmentProvider>().upcoming;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final next = upcoming.first;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final d = next.dateTime;
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedNav = 3),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.calendar_today_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming ${"\u2022"} Tap to view',
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  Text(next.itemName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary)),
                  Text(
                      '${next.businessName}  ·  ${d.day} ${months[d.month - 1]} at $h:${d.minute.toString().padLeft(2, '0')} $period',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary),
          ]),
        ),
      ),
    );
  }

  // ── Offers carousel ───────────────────────────────────────────────────────

  Widget _buildOffersCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: _sectionTitle('Special Offers', null),
        ),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _offers.length,
            itemBuilder: (_, i) {
              final o = _offers[i];
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: o['colors'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(o['title'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(o['subtitle'] as String,
                            style: TextStyle(
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: Icon(o['icon'] as IconData,
                        color: Colors.white, size: 22),
                  ),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Business type category grid ───────────────────────────────────────────

  Widget _buildCategoryGrid() {
    final types = BusinessType.customerBrowseTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _sectionTitle('Browse by Category', '${types.length} types'),
        ),
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: types.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                final selected = _selectedBizType == 'all';
                return _categoryChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  color: AppColors.primary,
                  selected: selected,
                  onTap: () => setState(() => _selectedBizType = 'all'),
                );
              }
              final t = types[i - 1];
              final selected = _selectedBizType == t.id;
              return _categoryChip(
                label: t.title,
                icon: t.icon,
                color: t.color,
                selected: selected,
                onTap: () => setState(
                    () => _selectedBizType = selected ? 'all' : t.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top rated horizontal scroll ───────────────────────────────────────────

  Widget _buildTopRated() {
    final mp = context.watch<CustomerMarketplaceProvider>();
    final list = _topRated(mp);
    if (list.isEmpty) return const SizedBox.shrink();

    final fid = _effectiveBrowseTypeId;
    final label = fid == 'all'
        ? 'Top Rated'
        : 'Top ${BusinessType.all.firstWhere((t) => t.id == fid).title}s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: _sectionTitle(label,
              '${_visibleBusinesses(mp).where((b) => b.isOpen).length} open'),
        ),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (_, i) => _featuredCard(list[i]),
          ),
        ),
      ],
    );
  }

  Widget _featuredCard(Business biz) {
    return GestureDetector(
      onTap: () => _open(biz),
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(right: 12, bottom: 4, top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Stack(
          children: [
            // Background image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: biz.imageUrl != null && biz.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(biz.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: !((biz.imageUrl != null && biz.imageUrl!.isNotEmpty))
                    ? biz.color
                    : null,
              ),
            ),
            // Gradient overlay for text
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content (positioned at bottom)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: icon + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                        child: Icon(biz.typeIcon, color: Colors.white, size: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: biz.isOpen
                              ? Colors.green.shade400
                              : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          biz.isOpen ? 'Open' : 'Closed',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Bottom section: name + rating
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biz.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text('${biz.rating}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        Text('(${biz.reviewCount})',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10)),
                      ]),
                      if (!biz.isOpen &&
                          (biz.shopClosedReason ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          biz.shopClosedReason!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  // ── All businesses list ───────────────────────────────────────────────────

  Widget _buildAllBusinesses() {
    final mp = context.watch<CustomerMarketplaceProvider>();
    final list = _visibleBusinesses(mp);
    final fid = _effectiveBrowseTypeId;
    final typeLabel = fid == 'all'
        ? 'All Businesses'
        : BusinessType.all.firstWhere((t) => t.id == fid).title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: _sectionTitle(typeLabel, '${list.length} found'),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(children: [
                const Icon(Icons.search_off_rounded,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 10),
                Text('No results for "$_searchQuery"',
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
              ]),
            ),
          )
        else
          ...list.map(_bizCard),
      ],
    );
  }

  Widget _bizCard(Business biz) {
    return GestureDetector(
      onTap: () => _open(biz),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [biz.color, biz.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(biz.typeIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(biz.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: biz.isOpen
                          ? AppColors.completed
                          : AppColors.cancelled,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      biz.isOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                          color: biz.isOpen
                              ? AppColors.completedText
                              : AppColors.cancelledText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(biz.address,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text('${biz.rating}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  Text('  (${biz.reviewCount})',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(
                    'From Rs. ${_minPrice(biz)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: biz.color,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
                if (!biz.isOpen && (biz.shopClosedReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    biz.shopClosedReason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (biz.tagline != null) ...[
                  const SizedBox(height: 4),
                  Text(biz.tagline!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _open(Business biz) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(business: biz)),
      );

  Business? _resolveCartBusiness() {
    final cartBizId = context.read<CartProvider>().businessId;
    if (cartBizId == null) return null;
    for (final b in context.read<CustomerMarketplaceProvider>().businesses) {
      if (b.id == cartBizId) return b;
    }

    final bizProv = context.read<BusinessProvider>();
    if (bizProv.selectedBusiness?.id != cartBizId) return null;

    final prodProv = context.read<ProductProvider>();
    final allowed = bizProv.categories.toSet();
    final products = prodProv
        .productsForBusiness(cartBizId)
        .where((p) => allowed.contains(p.category))
        .toList();
    final wantsDelivery = bizProv.hasDelivery;
    return Business.fromOwner(
      businessName: bizProv.businessName,
      businessTypeId: cartBizId,
      color: bizProv.selectedBusiness!.color,
      products: products,
      deliveryBaseCharge: wantsDelivery ? bizProv.deliveryBaseCharge : null,
      deliveryPerKmCharge: wantsDelivery ? bizProv.deliveryPerKmCharge : null,
      deliveryRadiusKm: wantsDelivery ? bizProv.deliveryRadiusKm : null,
    );
  }

  String _minPrice(Business biz) {
    if (biz.items.isEmpty) return '0';
    return biz.items
        .map((i) => i.price)
        .reduce((a, b) => a < b ? a : b)
        .toStringAsFixed(0);
  }

  Widget _sectionTitle(String title, String? sub) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.textPrimary)),
          if (sub != null)
            Text(sub,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
        ],
      );
}
