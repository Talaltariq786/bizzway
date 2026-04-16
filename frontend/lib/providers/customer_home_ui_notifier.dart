import 'package:flutter/material.dart';

import '../models/business_type.dart';

/// UI-only state for [CustomerHomeScreen] — no [setState]; use with Provider.
class CustomerHomeUiNotifier extends ChangeNotifier {
  CustomerHomeUiNotifier() {
    _syncInitialBizType();
  }

  int _selectedNav = 0;
  int _selectedTopMiniCard = 0;
  String _selectedBizType = 'all';
  String _searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  int get selectedNav => _selectedNav;
  int get selectedTopMiniCard => _selectedTopMiniCard;
  String get selectedBizType => _selectedBizType;
  String get searchQuery => _searchQuery;

  /// Maps excluded browse chips to [all] for filtering dummy lists.
  String get effectiveBrowseTypeId {
    if (_selectedBizType == 'all') return 'all';
    if (BusinessType.excludedFromCustomerBrowse.contains(_selectedBizType)) {
      return 'all';
    }
    return _selectedBizType;
  }

  void _syncInitialBizType() {
    if (BusinessType.excludedFromCustomerBrowse.contains(_selectedBizType)) {
      _selectedBizType = 'all';
      notifyListeners();
    }
  }

  void selectNav(int index) {
    if (_selectedNav == index) return;
    _selectedNav = index;
    notifyListeners();
  }

  void selectTopMiniCard(int index) {
    if (_selectedTopMiniCard == index) return;
    _selectedTopMiniCard = index;
    notifyListeners();
  }

  void setBizType(String id) {
    if (_selectedBizType == id) return;
    _selectedBizType = id;
    notifyListeners();
  }

  /// Category chip: tap again on selected type → browse "all".
  void toggleCategoryType(String typeId) {
    if (_selectedBizType == typeId) {
      setBizType('all');
    } else {
      setBizType(typeId);
    }
  }

  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

