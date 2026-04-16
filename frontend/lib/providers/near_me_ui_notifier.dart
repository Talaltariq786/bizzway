import 'package:flutter/foundation.dart';

/// Near Me tab: selected category chip (device-only UI state).
class NearMeUiNotifier extends ChangeNotifier {
  String _selectedCategoryId = 'all';

  String get selectedCategoryId => _selectedCategoryId;

  void selectCategory(String id) {
    if (_selectedCategoryId == id) return;
    _selectedCategoryId = id;
    notifyListeners();
  }
}

