import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unauthenticated, authenticated }

enum UserType { businessOwner, customer, serviceWorker, rider }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userEmail;
  String? _serviceProfession;
  String? _serviceNic;
  String? _serviceImagePath;
  String? _servicePlan;
  String? _riderLicense;
  String? _riderBike;
  String? _riderNic;
  double? _riderWallet;
  String? _riderPlan;
  String? _riderLicenseImagePath;
  String? _riderNicImagePath;
  /// Delivery radius centre (rider “home” pin). Default: Karachi Saddar area.
  static const double defaultRiderHubLat = 24.8607;
  static const double defaultRiderHubLng = 67.0011;
  double _riderHubLat = defaultRiderHubLat;
  double _riderHubLng = defaultRiderHubLng;
  bool _isLoading = false;
  UserType _userType = UserType.businessOwner;

  AuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get serviceProfession => _serviceProfession;
  String? get serviceNic => _serviceNic;
  String? get serviceImagePath => _serviceImagePath;
  String? get servicePlan => _servicePlan;
  String? get riderLicense => _riderLicense;
  String? get riderBike => _riderBike;
  String? get riderNic => _riderNic;
  double? get riderWallet => _riderWallet;
  String? get riderPlan => _riderPlan;
  String? get riderLicenseImagePath => _riderLicenseImagePath;
  String? get riderNicImagePath => _riderNicImagePath;
  double get riderHubLat => _riderHubLat;
  double get riderHubLng => _riderHubLng;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserType get userType => _userType;
  bool get isBusinessOwner => _userType == UserType.businessOwner;
  bool get isCustomer => _userType == UserType.customer;
  bool get isServiceWorker => _userType == UserType.serviceWorker;
  bool get isRider => _userType == UserType.rider;

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
      _riderLicense = prefs.getString('rider_license');
      _riderBike = prefs.getString('rider_bike');
      _riderNic = prefs.getString('rider_nic');
      _riderWallet = prefs.getDouble('rider_wallet');
      _riderPlan = prefs.getString('rider_plan');
      _riderLicenseImagePath = prefs.getString('rider_license_image_path');
      _riderNicImagePath = prefs.getString('rider_nic_image_path');
      _riderHubLat = prefs.getDouble('rider_hub_lat') ?? defaultRiderHubLat;
      _riderHubLng = prefs.getDouble('rider_hub_lng') ?? defaultRiderHubLng;
      final savedType = prefs.getString('user_type');
      if (savedType == 'customer') {
        _userType = UserType.customer;
      } else if (savedType == 'serviceWorker') {
        _userType = UserType.serviceWorker;
      } else if (savedType == 'rider') {
        _userType = UserType.rider;
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
      await prefs.setString('user_type', 'businessOwner');
      _userEmail = email;
      _userType = UserType.businessOwner;
      _status = AuthStatus.authenticated;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Phone login for customer, service worker, or rider.
  Future<bool> loginWithPhone(
    String phone, {
    UserType phoneRole = UserType.customer,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (phone.trim().length >= 10) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', phone.trim());
      _userEmail = phone.trim();

      if (phoneRole == UserType.serviceWorker) {
        await prefs.setString('user_type', 'serviceWorker');
        _userType = UserType.serviceWorker;
        _serviceProfession = prefs.getString('service_profession');
        _serviceNic = prefs.getString('service_nic');
        _serviceImagePath = prefs.getString('service_image_path');
        _servicePlan = prefs.getString('service_plan');
      } else if (phoneRole == UserType.rider) {
        await prefs.setString('user_type', 'rider');
        _userType = UserType.rider;
        _riderLicense = prefs.getString('rider_license');
        _riderBike = prefs.getString('rider_bike');
        _riderNic = prefs.getString('rider_nic');
        _riderWallet = prefs.getDouble('rider_wallet');
        _riderPlan = prefs.getString('rider_plan');
        _riderLicenseImagePath = prefs.getString('rider_license_image_path');
        _riderNicImagePath = prefs.getString('rider_nic_image_path');
        _riderHubLat = prefs.getDouble('rider_hub_lat') ?? defaultRiderHubLat;
        _riderHubLng = prefs.getDouble('rider_hub_lng') ?? defaultRiderHubLng;
      } else {
        await prefs.setString('user_type', 'customer');
        _userType = UserType.customer;
        _serviceProfession = prefs.getString('service_profession');
        _serviceNic = prefs.getString('service_nic');
        _serviceImagePath = prefs.getString('service_image_path');
        _servicePlan = prefs.getString('service_plan');
      }

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
    final typeStr = switch (type) {
      UserType.customer => 'customer',
      UserType.serviceWorker => 'serviceWorker',
      UserType.rider => 'rider',
      UserType.businessOwner => 'businessOwner',
    };
    await prefs.setString('user_type', typeStr);
    if (type == UserType.serviceWorker) {
      _serviceProfession = prefs.getString('service_profession');
      _serviceNic = prefs.getString('service_nic');
      _serviceImagePath = prefs.getString('service_image_path');
      _servicePlan = prefs.getString('service_plan');
    }
    if (type == UserType.rider) {
      _riderLicense = prefs.getString('rider_license');
      _riderBike = prefs.getString('rider_bike');
      _riderNic = prefs.getString('rider_nic');
      _riderWallet = prefs.getDouble('rider_wallet');
      _riderPlan = prefs.getString('rider_plan');
      _riderLicenseImagePath = prefs.getString('rider_license_image_path');
      _riderNicImagePath = prefs.getString('rider_nic_image_path');
      _riderHubLat = prefs.getDouble('rider_hub_lat') ?? defaultRiderHubLat;
      _riderHubLng = prefs.getDouble('rider_hub_lng') ?? defaultRiderHubLng;
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

  Future<void> setRiderProfile({
    required String licenseNo,
    required String nic,
    required String bikeNumber,
    required double walletAmount,
    required String planId,
    required String licenseImagePath,
    required String nicImagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _riderLicense = licenseNo;
    _riderNic = nic;
    _riderBike = bikeNumber;
    _riderWallet = walletAmount;
    _riderPlan = planId;
    _riderLicenseImagePath = licenseImagePath;
    _riderNicImagePath = nicImagePath;
    await prefs.setString('rider_license', licenseNo);
    await prefs.setString('rider_nic', nic);
    await prefs.setString('rider_bike', bikeNumber);
    await prefs.setDouble('rider_wallet', walletAmount);
    await prefs.setString('rider_plan', planId);
    await prefs.setString('rider_license_image_path', licenseImagePath);
    await prefs.setString('rider_nic_image_path', nicImagePath);
    _riderHubLat = defaultRiderHubLat;
    _riderHubLng = defaultRiderHubLng;
    await prefs.setDouble('rider_hub_lat', _riderHubLat);
    await prefs.setDouble('rider_hub_lng', _riderHubLng);
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

    final isPhoneOnly = userType == UserType.customer ||
        userType == UserType.serviceWorker ||
        userType == UserType.rider;
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
              : userType == UserType.rider
                  ? 'rider'
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
    await prefs.remove('user_email');
    await prefs.remove('user_type');
    await prefs.remove('service_profession');
    await prefs.remove('service_nic');
    await prefs.remove('service_image_path');
    await prefs.remove('service_plan');
    await prefs.remove('rider_license');
    await prefs.remove('rider_bike');
    await prefs.remove('rider_nic');
    await prefs.remove('rider_wallet');
    await prefs.remove('rider_plan');
    await prefs.remove('rider_license_image_path');
    await prefs.remove('rider_nic_image_path');
    await prefs.remove('rider_hub_lat');
    await prefs.remove('rider_hub_lng');
    _userEmail = null;
    _serviceProfession = null;
    _serviceNic = null;
    _serviceImagePath = null;
    _servicePlan = null;
    _riderLicense = null;
    _riderBike = null;
    _riderNic = null;
    _riderWallet = null;
    _riderPlan = null;
    _riderLicenseImagePath = null;
    _riderNicImagePath = null;
    _riderHubLat = defaultRiderHubLat;
    _riderHubLng = defaultRiderHubLng;
    _userType = UserType.businessOwner;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
