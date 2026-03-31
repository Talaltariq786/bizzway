import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import 'dart:io';
import '../../models/product.dart';
import '../../providers/business_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/app_asset_image.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  late TabController _tabCtrl;

  bool _isServiceBiz(String id) => ['salon', 'gym', 'clinic'].contains(id);
  bool _isFoodBiz(String id) => ['restaurant', 'cafe'].contains(id);
  bool _isGymBiz(String id) => id == 'gym';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final biz = context.watch<BusinessProvider>();
    final bizId = biz.selectedBusiness?.id ?? '';
    final isService = _isServiceBiz(bizId);
    final isFood = _isFoodBiz(bizId);
    final isGym = _isGymBiz(bizId);
    final bizColor = biz.themeColor;
    final allowedCategories = biz.categories.toSet();
    final categories = ['All', ...biz.categories];
    final selectedCategory =
        categories.contains(_selectedCategory) ? _selectedCategory : 'All';
    final scopedProducts = bizId.isEmpty
        ? productProv.products
        : productProv.productsForBusiness(bizId);
    final products = scopedProducts
        .where((p) => allowedCategories.contains(p.category))
        .where((p) => selectedCategory == 'All' || p.category == selectedCategory)
        .toList();
    final deals = (bizId.isEmpty
            ? productProv.activeDeals
            : productProv.activeDealsForBusiness(bizId))
        .where((p) => allowedCategories.contains(p.category))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isGym ? 'Packages & Services' : isService ? 'My Services' : isFood ? 'My Menu' : 'My Products',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_rounded, color: bizColor, size: 28),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
          ),
        ],
        // Tab bar for food businesses (Products / Deals)
        bottom: isFood
            ? TabBar(
                controller: _tabCtrl,
                indicatorColor: bizColor,
                labelColor: bizColor,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: 'Menu (${scopedProducts.length})'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Deals'),
                        if (deals.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${deals.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: isFood
          ? TabBarView(
              controller: _tabCtrl,
              children: [
                _productList(products, bizId, bizColor, categories, selectedCategory),
                _dealsList(deals, bizColor, productProv),
              ],
            )
          : _productList(products, bizId, bizColor, categories, selectedCategory),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-product-fab',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addProduct),
        backgroundColor: bizColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          isGym ? 'Add Package' : isService ? 'Add Service' : isFood ? 'Add Item' : 'Add Product',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 52,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? bizColor : bizColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          color: selected ? Colors.white : bizColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              );
            },
          ),
        ),
        // Product list
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64,
                          color: bizColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('Nothing here yet',
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: products[i],
                    bizId: bizId,
                    bizColor: bizColor,
                    onDelete: () => context
                        .read<ProductProvider>()
                        .deleteProduct(products[i].id),
                    onToggle: () => context
                        .read<ProductProvider>()
                        .toggleAvailability(products[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _dealsList(
      List<Product> deals, Color bizColor, ProductProvider prov) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 64, color: Colors.orange.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No active deals',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            const Text('Add a discount when creating a menu item',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: deals.length,
      itemBuilder: (_, i) {
        final p = deals[i];
        return Container(
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
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              // Discount badge
              Container(
                width: 64, height: 64,
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
                    Text('${p.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const Text('OFF',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Rs. ${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textHint,
                              fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rs. ${p.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    Text(p.category,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
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
        );
      },
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final String bizId;
  final Color bizColor;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.bizId,
    required this.bizColor,
    required this.onDelete,
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
              offset: const Offset(0, 2)),
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
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: bizColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: (product.imageUrl.isNotEmpty &&
                            !product.imageUrl.startsWith('http') &&
                            File(product.imageUrl).existsSync())
                        ? Image.file(
                            File(product.imageUrl),
                            fit: BoxFit.cover,
                          )
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
                    top: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
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
                  Text(product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(product.category,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.hasDiscount) ...[
                        Text('Rs. ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textHint,
                                fontSize: 11)),
                        const SizedBox(width: 6),
                        Text('Rs. ${product.discountedPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ] else
                        Text('Rs. ${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                color: bizColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      if (!_isGym && product.unit != null) ...[
                        Text('  ${product.unit}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                      if (_isService && !_isGym && product.durationMinutes != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_rounded,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text('${product.durationMinutes} min',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                  // Gym: duration + trainer + session badges
                  if (_isGym) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (product.unit != null)
                        _badge(Icons.calendar_month_rounded,
                            product.unit!, bizColor),
                      if (_isGymMembership && product.withTrainer == true)
                        _badge(Icons.sports_gymnastics_rounded,
                            'With Trainer', Colors.green.shade600),
                      if (_isGymMembership && product.withTrainer == false)
                        _badge(Icons.fitness_center_rounded,
                            'Self Workout', Colors.blueGrey),
                      if (product.durationMinutes != null)
                        _badge(Icons.access_time_rounded,
                            '${product.durationMinutes} min', Colors.purple),
                    ]),
                  ],
                ],
              ),
            ),

            // ── Controls ─────────────────────────────────────────────
            Column(
              children: [
                Switch(
                  value: product.isAvailable,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: bizColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                ),
              ],
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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ]),
      );

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete?'),
        content: Text('Remove "${product.name}" from your listing?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
