import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unauthenticated, authenticated }

enum UserType { businessOwner, customer, serviceWorker }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userEmail;
  String? _serviceProfession;
  String? _serviceNic;
  String? _serviceImagePath;
  String? _servicePlan;
  bool _isLoading = false;
  UserType _userType = UserType.businessOwner;

  AuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get serviceProfession => _serviceProfession;
  String? get serviceNic => _serviceNic;
  String? get serviceImagePath => _serviceImagePath;
  String? get servicePlan => _servicePlan;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserType get userType => _userType;
  bool get isBusinessOwner => _userType == UserType.businessOwner;
  bool get isCustomer => _userType == UserType.customer;
  bool get isServiceWorker => _userType == UserType.serviceWorker;

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    if (email != null) {
      _userEmail = email;
      _status = AuthStatus.authenticated;
      _serviceProfession = prefs.getString('service_profession');
      _serviceNic = prefs.getString('service_nic');
      _serviceImagePath = prefs.getString('service_image_path');
      _servicePlan = prefs.getString('service_plan');
      final savedType = prefs.getString('user_type');
      if (savedType == 'customer') {
        _userType = UserType.customer;
      } else if (savedType == 'serviceWorker') {
        _userType = UserType.serviceWorker;
      } else {
        _userType = UserType.businessOwner;
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.length >= 6) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      _userEmail = email;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Customer phone-only login (no password needed)
  Future<bool> loginWithPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (phone.trim().length >= 10) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', phone.trim());
      await prefs.setString('user_type', 'customer');
      _userEmail = phone.trim();
      _userType = UserType.customer;
      // Load any previously saved service worker profile (if this user is a worker)
      _serviceProfession = prefs.getString('service_profession');
      _serviceNic = prefs.getString('service_nic');
      _serviceImagePath = prefs.getString('service_image_path');
      _servicePlan = prefs.getString('service_plan');
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> setUserType(UserType type) async {
    _userType = type;
    final prefs = await SharedPreferences.getInstance();
    final typeStr = type == UserType.customer
        ? 'customer'
        : type == UserType.serviceWorker
            ? 'serviceWorker'
            : 'businessOwner';
    await prefs.setString('user_type', typeStr);
    // When switching to service worker, ensure profession data is loaded
    if (type == UserType.serviceWorker) {
      _serviceProfession = prefs.getString('service_profession');
      _serviceNic = prefs.getString('service_nic');
      _serviceImagePath = prefs.getString('service_image_path');
      _servicePlan = prefs.getString('service_plan');
    }
    notifyListeners();
  }

  Future<void> setServiceWorkerProfile({
    required String profession,
    required String nic,
    required String imagePath,
    required String plan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _serviceProfession = profession;
    _serviceNic = nic;
    _serviceImagePath = imagePath;
    _servicePlan = plan;
    await prefs.setString('service_profession', profession);
    await prefs.setString('service_nic', nic);
    await prefs.setString('service_image_path', imagePath);
    await prefs.setString('service_plan', plan);
    notifyListeners();
  }

  Future<void> setServiceProfessionOnly(String profession) async {
    _serviceProfession = profession;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('service_profession', profession);
    notifyListeners();
  }

  Future<bool> signUp(String identifier, String password,
      {UserType userType = UserType.businessOwner}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Customer + Service Worker signup: only phone required (no password)
    final isPhoneOnly =
        userType == UserType.customer || userType == UserType.serviceWorker;
    final valid = isPhoneOnly
        ? identifier.isNotEmpty
        : identifier.isNotEmpty && password.length >= 6;

    if (valid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', identifier);
      final typeStr = userType == UserType.customer
          ? 'customer'
          : userType == UserType.serviceWorker
              ? 'serviceWorker'
              : 'businessOwner';
      await prefs.setString('user_type', typeStr);
      _userEmail = identifier;
      _userType = userType;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep business setup data (business_id, business_name, etc.) so that
    // business owners don't need to re-select business type after logout.
    await prefs.remove('user_email');
    await prefs.remove('user_type');
    await prefs.remove('service_profession');
    await prefs.remove('service_nic');
    await prefs.remove('service_image_path');
    await prefs.remove('service_plan');
    _userEmail = null;
    _serviceProfession = null;
    _serviceNic = null;
    _serviceImagePath = null;
    _servicePlan = null;
    _userType = UserType.businessOwner;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
