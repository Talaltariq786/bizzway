import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../providers/api_catalog_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_asset_image.dart';
import '../../widgets/common/themed_dialog_wrapper.dart';
import '../../core/constants/dashboard_header_layout.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  late TabController _tabCtrl;
  String _lastLoadedBizId = '';

  bool _isServiceBiz(String id) => ['salon', 'gym', 'clinic'].contains(id);
  bool _isFoodBiz(String id) => ['restaurant', 'cafe'].contains(id);
  bool _isGymBiz(String id) => id == 'gym';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final apiCatalog = context.watch<ApiCatalogProvider>();
    final biz = context.watch<BusinessProvider>();
    final bizId = biz.selectedBusiness?.id ?? '';
    if (bizId.isNotEmpty && bizId != _lastLoadedBizId) {
      _lastLoadedBizId = bizId;
      Future.microtask(
        () => apiCatalog.loadProductsForBusinessType(
          bizId,
          remoteBusinessMongoId: biz.remoteBusinessMongoId,
        ),
      );
    }
    final isService = _isServiceBiz(bizId);
    final isFood = _isFoodBiz(bizId);
    final isGym = _isGymBiz(bizId);
    final bizColor = biz.themeColor;
    final headerGradient = AppColors.gradientFrom(bizColor);
    final allowedCategories = biz.categories.toSet();
    final categories = ['All', ...biz.categories];
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory
        : 'All';
    final scopedProducts = apiCatalog.products.isNotEmpty
        ? apiCatalog.products
        : (bizId.isEmpty ? productProv.products : productProv.productsForBusiness(bizId));
    final products = scopedProducts
        .where((p) => allowedCategories.contains(p.category))
        .where(
          (p) => selectedCategory == 'All' || p.category == selectedCategory,
        )
        .toList();
    final deals =
        (bizId.isEmpty
                ? productProv.activeDeals
                : productProv.activeDealsForBusiness(bizId))
            .where((p) => allowedCategories.contains(p.category))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          if (apiCatalog.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primary.withValues(alpha: 0.07),
                    AppColors.primaryLight,
                  ],
                ),
              ),
              child: Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
            ),
          if (apiCatalog.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'API error: ${apiCatalog.error}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: bizId.isEmpty
                        ? null
                        : () => apiCatalog.loadProductsForBusinessType(
                              bizId,
                              remoteBusinessMongoId: biz.remoteBusinessMongoId,
                            ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
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
              left: DashboardHeaderOverlay.inset,
              right: DashboardHeaderOverlay.inset,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isGym
                      ? 'Packages & Services'
                      : isService
                          ? 'My Services'
                          : isFood
                              ? 'My Menu'
                              : 'My Products',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isService
                      ? 'Manage services, pricing and availability'
                      : 'Manage products, categories and stock visibility',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isFood)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: List.generate(2, (index) {
                    final isSelected = _tabCtrl.index == index;
                    final labels = ['Menu', 'Deals'];
                    final counts = [scopedProducts.length, deals.length];
                    final icons = [
                      Icons.restaurant_menu_rounded,
                      Icons.local_offer_rounded,
                    ];
                    return GestureDetector(
                      onTap: () => setState(() => _tabCtrl.animateTo(index)),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              size: 14,
                              color: isSelected ? bizColor : Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              labels[index],
                              style: TextStyle(
                                color: isSelected ? bizColor : Colors.white,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                            if (counts[index] > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE91E3F),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${counts[index]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          Expanded(
            child: isFood
                ? TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _productList(
                        products,
                        bizId,
                        bizColor,
                        categories,
                        selectedCategory,
                      ),
                      _dealsList(deals, bizColor, productProv),
                    ],
                  )
                : _productList(
                    products,
                    bizId,
                    bizColor,
                    categories,
                    selectedCategory,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product-fab',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
        backgroundColor: bizColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isGym
              ? 'Add Package'
              : isService
              ? 'Add Service'
              : isFood
              ? 'Add Item'
              : 'Add Product',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _productList(
    List<Product> products,
    String bizId,
    Color bizColor,
    List<String> categories,
    String selectedCategory,
  ) {
    Widget categoryBar() {
      Widget chip(String cat) {
        final selected = cat == selectedCategory;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedCategory = cat),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? bizColor : bizColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? bizColor : bizColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : bizColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in categories) chip(c)],
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: categoryBar()),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: bizColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedCategory == 'All'
                          ? 'Nothing here yet'
                          : 'No items in "$selectedCategory"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selectedCategory != 'All') ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedCategory = 'All'),
                        child: const Text('Show all categories'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final p = products[i];
                  return _SwipeableProductShell(
                    slidableKey: ValueKey('product_slidable_${p.id}'),
                    bizColor: bizColor,
                    onEdit: () => Navigator.pushNamed(
                      context,
                      AppRoutes.addProduct,
                      arguments: p,
                    ),
                    onDelete: () => _confirmDeleteProduct(
                      context,
                      product: p,
                      bizColor: bizColor,
                      onDelete: () => context
                          .read<ProductProvider>()
                          .deleteProduct(p.id),
                    ),
                    child: _ProductCard(
                      product: p,
                      bizId: bizId,
                      bizColor: bizColor,
                      onToggle: () => context
                          .read<ProductProvider>()
                          .toggleAvailability(p.id),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _dealsList(List<Product> deals, Color bizColor, ProductProvider prov) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.orange.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No active deals',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a discount when creating a menu item',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deals.length,
      itemBuilder: (_, i) {
        final p = deals[i];
        return _SwipeableProductShell(
          slidableKey: ValueKey('deal_slidable_${p.id}'),
          bizColor: Colors.orange,
          onEdit: () => Navigator.pushNamed(
            context,
            AppRoutes.addProduct,
            arguments: p,
          ),
          onDelete: () => _confirmDeleteProduct(
            context,
            product: p,
            bizColor: Colors.orange,
            onDelete: () => prov.deleteProduct(p.id),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Discount badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Color(0xFFFF6F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${p.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Rs. ${p.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rs. ${p.discountedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        p.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: p.isAvailable,
                  onChanged: (_) => prov.toggleAvailability(p.id),
                  activeThumbColor: Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteProduct(
    BuildContext context, {
    required Product product,
    required Color bizColor,
    required VoidCallback onDelete,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => wrapDialogWithTheme(
        context,
        accentColor: bizColor,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete?'),
          content: Text('Remove "${product.name}" from your listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onDelete();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableProductShell extends StatelessWidget {
  const _SwipeableProductShell({
    required this.slidableKey,
    required this.bizColor,
    required this.onEdit,
    required this.onDelete,
    required this.child,
  });

  final Key slidableKey;
  final Color bizColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: slidableKey,
      closeOnScroll: true,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.30,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.only(left: 6, right: 4),
            child: Center(
              child: Material(
                color: bizColor,
                elevation: 2,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.only(left: 4, right: 10),
            child: Center(
              child: Material(
                color: AppColors.error,
                elevation: 2,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final String bizId;
  final Color bizColor;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.bizId,
    required this.bizColor,
    required this.onToggle,
  });

  bool get _isService => ['salon', 'gym', 'clinic'].contains(bizId);
  bool get _isGym => bizId == 'gym';
  bool get _isGymMembership => _isGym && product.category == 'Memberships';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Image / icon ─────────────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: bizColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: product.imageUrl.isNotEmpty &&
                            product.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: bizColor.withValues(alpha: 0.08),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: bizColor,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Center(
                              child: AppAssetImage(
                                businessTypeId: bizId,
                                seed: '${product.id}_owner',
                                itemName: product.name,
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        : (product.imageUrl.isNotEmpty &&
                                !product.imageUrl.startsWith('http') &&
                                File(product.imageUrl).existsSync())
                            ? Image.file(File(product.imageUrl),
                                fit: BoxFit.cover)
                            : Center(
                                child: AppAssetImage(
                                  businessTypeId: bizId,
                                  seed: '${product.id}_owner',
                                  itemName: product.name,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.contain,
                                ),
                              ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Rs. ${product.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ] else
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: bizColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      if (!_isGym && product.unit != null) ...[
                        Text(
                          '  ${product.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_isService &&
                          !_isGym &&
                          product.durationMinutes != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 11,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.durationMinutes} min',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Gym: duration + trainer + session badges
                  if (_isGym) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (product.unit != null)
                          _badge(
                            Icons.calendar_month_rounded,
                            product.unit!,
                            bizColor,
                          ),
                        if (_isGymMembership && product.withTrainer == true)
                          _badge(
                            Icons.sports_gymnastics_rounded,
                            'With Trainer',
                            Colors.green.shade600,
                          ),
                        if (_isGymMembership && product.withTrainer == false)
                          _badge(
                            Icons.fitness_center_rounded,
                            'Self Workout',
                            Colors.blueGrey,
                          ),
                        if (product.durationMinutes != null)
                          _badge(
                            Icons.access_time_rounded,
                            '${product.durationMinutes} min',
                            Colors.purple,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Controls ─────────────────────────────────────────────
            SizedBox(
              height: 26,
              width: 46,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: product.isAvailable,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: bizColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
