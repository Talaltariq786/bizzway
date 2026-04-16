import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/dev_log.dart';
import '../../core/constants/product_image_library_catalog.dart';
import '../../core/constants/stock_photo_catalog.dart';
import '../../widgets/common/app_asset_image.dart';

class ProductImageSelection {
  final String? imagePath; // local file path
  final String? suggestedName; // used for label/fallback asset mapping
  /// HTTPS thumbnail from curated catalog (saved on [Product.imageUrl]).
  final String? stockImageUrl;
  final String category;
  final String businessTypeId;

  const ProductImageSelection({
    required this.businessTypeId,
    required this.category,
    this.imagePath,
    this.suggestedName,
    this.stockImageUrl,
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
  late final List<String> _cats =
      ProductImageLibraryCatalog.categoriesFor(widget.businessTypeId);
  late final TabController _tabCtrl =
      TabController(length: _cats.length, vsync: this);
  final Map<String, List<String>> _userImages = {};

  /// Selected sub-tab label per main category (e.g. Burgers → Chicken).
  final Map<String, String> _subTabPick = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl.addListener(_onMainTabChanged);
    _syncSubTabForIndex(0);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onMainTabChanged);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onMainTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    if (!mounted) return;
    _syncSubTabForIndex(_tabCtrl.index);
    setState(() {});
  }

  void _syncSubTabForIndex(int i) {
    if (i < 0 || i >= _cats.length) return;
    final cat = _cats[i];
    final nest =
        ProductImageLibraryCatalog.nestedFor(widget.businessTypeId)[cat];
    if (nest == null || nest.isEmpty) return;
    final keys = nest.keys.toList();
    final cur = _subTabPick[cat];
    if (cur == null || !nest.containsKey(cur)) {
      _subTabPick[cat] = keys.first;
    }
  }

  String _keyFor(String cat) =>
      'image_lib_${widget.businessTypeId}_${cat.toLowerCase()}';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _keyFor(cat), jsonEncode(_userImages[cat] ?? const []));
    } catch (e, st) {
      devLog('_persist image lib', e, st);
      if (mounted) {
        showAppToast(context, 'Save failed (storage).', error: true);
      }
    }
  }

  Future<void> _addFromGallery(String cat) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (file == null) return;
      if (!mounted) return;
      setState(() {
        _userImages.putIfAbsent(cat, () => <String>[]);
        _userImages[cat]!.insert(0, file.path);
      });
      await _persist(cat);
    } catch (e, st) {
      devLog('_addFromGallery', e, st);
      if (mounted) {
        showAppToast(context, 'Photo add nahi ho saki. Dobara try karein.',
            error: true);
      }
    }
  }

  Future<void> _removeImage(String cat, String path) async {
    setState(() {
      _userImages[cat]?.remove(path);
    });
    await _persist(cat);
  }

  List<String> _suggestedListFor(String cat) {
    final nested =
        ProductImageLibraryCatalog.nestedFor(widget.businessTypeId);
    final flat = ProductImageLibraryCatalog.flatFor(widget.businessTypeId);
    final subMap = nested[cat];
    if (subMap == null || subMap.isEmpty) {
      return flat[cat] ?? const [];
    }
    final keys = subMap.keys.toList();
    if (keys.length == 1) {
      return subMap[keys.first] ?? const [];
    }
    final sub = _subTabPick[cat] ?? keys.first;
    return subMap[sub] ?? const [];
  }

  bool _showSubTabs(String cat) {
    final subMap =
        ProductImageLibraryCatalog.nestedFor(widget.businessTypeId)[cat];
    if (subMap == null) return false;
    return subMap.keys.length > 1;
  }

  Map<String, List<String>>? _subMapFor(String cat) {
    return ProductImageLibraryCatalog.nestedFor(widget.businessTypeId)[cat];
  }

  LinearGradient get _headerGradient => LinearGradient(
        colors: [
          Color.lerp(widget.accent, Colors.black, 0.12) ?? widget.accent,
          Color.lerp(widget.accent, Colors.white, 0.12) ?? widget.accent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.businessTypeId) {
      'restaurant' || 'cafe' => 'Menu photos',
      'rentacar' => 'Vehicle photos',
      'salon' || 'beauty' => 'Salon photos',
      _ => 'Product photos',
    };

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _headerGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 4,
                left: 6,
                right: 6,
                bottom: 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Category choose karke tap karein',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 11.5,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TabBar(
                    controller: _tabCtrl,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.only(left: 2, right: 2),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 1,
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: widget.accent,
                    unselectedLabelColor:
                        Colors.white.withValues(alpha: 0.92),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    splashBorderRadius: BorderRadius.circular(18),
                    overlayColor: WidgetStateProperty.all(
                      Colors.white.withValues(alpha: 0.12),
                    ),
                    tabs: _cats
                        .map(
                          (c) => Tab(
                            height: 32,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(c),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _cats.map((cat) => _tab(cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String cat) {
    final suggested = _suggestedListFor(cat);
    final userImgs = _userImages[cat] ?? const <String>[];
    final subMap = _subMapFor(cat);
    final showChips = _showSubTabs(cat);
    final a = widget.accent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: a,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _addFromGallery(cat),
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (showChips && subMap != null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subMap.keys.map((label) {
                final sel = (_subTabPick[cat] ?? subMap.keys.first) == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? a : AppColors.textPrimary,
                      ),
                    ),
                    selected: sel,
                    onSelected: (v) {
                      if (v) setState(() => _subTabPick[cat] = label);
                    },
                    selectedColor: a.withValues(alpha: 0.14),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: sel ? a : AppColors.border,
                      width: sel ? 2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Suggested — tap to select',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (suggested.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No suggestions for this category yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.68,
            ),
            itemCount: suggested.length,
            itemBuilder: (_, i) => _suggestedThumb(cat, suggested[i], i),
          ),
        const SizedBox(height: 12),
        Text(
          'Your photos — tap use · long press delete',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        if (userImgs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'No photos yet. Tap Add to upload.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: userImgs.length,
            itemBuilder: (_, i) {
              final p = userImgs[i];
              return _userPhotoThumb(cat, p);
            },
          ),
      ],
    );
  }

  Widget _userPhotoThumb(String cat, String path) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(
          context,
          ProductImageSelection(
            businessTypeId: widget.businessTypeId,
            category: cat,
            imagePath: path,
          ),
        ),
        onLongPress: () => _confirmDelete(cat, path),
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.expand(
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primaryLight,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestedThumb(String cat, String name, int i) {
    final stockUrl =
        StockPhotoCatalog.stockUrlForBusiness(widget.businessTypeId, name);
    final a = widget.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.pop(
          context,
          ProductImageSelection(
            businessTypeId: widget.businessTypeId,
            category: cat,
            suggestedName: name,
            stockImageUrl: stockUrl,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (stockUrl != null)
                  CachedNetworkImage(
                    imageUrl: stockUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 400,
                    placeholder: (context, url) => ColoredBox(
                      color: a.withValues(alpha: 0.08),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: a,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, err) => ColoredBox(
                      color: AppColors.backgroundLight,
                      child: Center(
                        child: AppAssetImage(
                          businessTypeId: widget.businessTypeId,
                          seed: 'lib_${cat}_$i',
                          itemName: name,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                else
                  ColoredBox(
                    color: AppColors.backgroundLight,
                    child: Center(
                      child: AppAssetImage(
                        businessTypeId: widget.businessTypeId,
                        seed: 'lib_${cat}_$i',
                        itemName: name,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 5),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
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
