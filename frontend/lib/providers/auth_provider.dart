import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/auth/auth_api.dart';
import '../core/config/api_config.dart';
import '../core/config/offline_mode.dart';
import '../core/auth/auth_token_storage.dart';
import '../core/services/provider_background_location.dart';

enum AuthStatus { unauthenticated, authenticated }

enum UserType { businessOwner, customer, serviceWorker, rider }

class AuthProvider extends ChangeNotifier {
  final AuthApi _authApi = AuthApi(ApiClient());

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userEmail;
  String? _serviceProfession;
  String? _serviceNic;
  String? _serviceImagePath;
  String? _serviceNicFrontImagePath;
  String? _serviceNicBackImagePath;
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
  bool _onlineForWork = true;
  bool _isLoading = false;
  UserType _userType = UserType.businessOwner;

  // ── Login tab intent (phone flows): which UI the user chose on Login screen.
  /// Overrides JWT `roles` for routing so Service tab → service worker UI even if DB still has `customer`.
  static const String _kLoginTabIntentKey = 'bizzway_login_tab_intent';

  // ── Team rider (owner-assigned) session ────────────────────────────────────
  String? _teamRiderId;
  String? _teamRiderBusinessId;
  String? _teamRiderDisplayName;

  AuthStatus get status => _status;
  String? get userEmail => _userEmail;
  String? get serviceProfession => _serviceProfession;
  String? get serviceNic => _serviceNic;
  String? get serviceImagePath => _serviceImagePath;
  String? get serviceNicFrontImagePath => _serviceNicFrontImagePath;
  String? get serviceNicBackImagePath => _serviceNicBackImagePath;
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
  bool get isOnlineForWork => _onlineForWork;
  bool get isTeamRiderAccount =>
      _userType == UserType.rider && (_teamRiderId ?? '').trim().isNotEmpty;
  String? get teamRiderId => _teamRiderId;
  String? get teamRiderBusinessId => _teamRiderBusinessId;
  String? get teamRiderDisplayName => _teamRiderDisplayName;

  /// Blocks network auth until a real device has a LAN URL (not 127.0.0.1 / 10.0.2.2).
  void _ensureBackendUrlForDevice() {
    if (OfflineMode.enabled) return;
    if (ApiConfig.shouldPromptForLanHost) {
      throw ApiException(
        'Pehle login screen par neeche "API" line se Mac/PC ka URL set karein, '
        'jaise http://192.168.1.10:8080 — same Wi‑Fi par backend (npm run dev) chalna chahiye.',
      );
    }
  }

  /// Maps backend role strings to [UserType]. Accepts common aliases / casing.
  UserType _userTypeFromRoles(List<String> roles) {
    bool has(String canonical) {
      for (final r in roles) {
        if (_canonicalRole(r) == canonical) return true;
      }
      return false;
    }

    if (has('businessOwner')) return UserType.businessOwner;
    if (has('rider')) return UserType.rider;
    if (has('serviceWorker')) return UserType.serviceWorker;
    if (has('customer')) return UserType.customer;
    return UserType.customer;
  }

  /// Normalizes e.g. `service_worker`, `ServiceWorker`, `serviceProvider` → camelCase keys we compare.
  String _canonicalRole(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '';
    final lower = t.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    return switch (lower) {
      'businessowner' => 'businessOwner',
      'serviceworker' => 'serviceWorker',
      'serviceprovider' => 'serviceWorker',
      'customer' => 'customer',
      'rider' => 'rider',
      'admin' => 'admin',
      _ => t,
    };
  }

  String _prefsKeyForUserType(UserType t) {
    return switch (t) {
      UserType.customer => 'customer',
      UserType.serviceWorker => 'serviceWorker',
      UserType.rider => 'rider',
      UserType.businessOwner => 'businessOwner',
    };
  }

  void _applyLoginTabIntentIfPresent(SharedPreferences prefs) {
    final intent = prefs.getString(_kLoginTabIntentKey);
    if (intent == null) return;
    switch (intent) {
      case 'customer':
        _userType = UserType.customer;
        break;
      case 'serviceWorker':
        _userType = UserType.serviceWorker;
        break;
      case 'rider':
        _userType = UserType.rider;
        break;
    }
  }

  Future<void> _applyUserDto(AuthUserDto me) async {
    final prefs = await SharedPreferences.getInstance();
    final display = me.phone ?? me.email ?? '';
    _userEmail = display.isNotEmpty ? display : _userEmail;
    if (_userEmail != null) {
      await prefs.setString('user_email', _userEmail!);
    }
    _userType = _userTypeFromRoles(me.roles);
    _applyLoginTabIntentIfPresent(prefs);
    await prefs.setString('user_type', _prefsKeyForUserType(_userType));
    if (_userType == UserType.serviceWorker) {
      await prefs.setString('active_provider_id', _userEmail ?? '');
      await ProviderBackgroundLocation.setEnabled(_onlineForWork);
    }
    _status = AuthStatus.authenticated;
  }

  /// Call after successful login / sign-up from the Login UI so [userType] matches the tab user picked.
  Future<void> persistLoginTabIntent({
    required UserType loginTab,
    bool serviceBranchHome = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (loginTab == UserType.businessOwner) {
      await prefs.remove(_kLoginTabIntentKey);
    } else if (loginTab == UserType.customer) {
      await prefs.setString(_kLoginTabIntentKey, 'customer');
    } else if (loginTab == UserType.serviceWorker) {
      await prefs.setString(
        _kLoginTabIntentKey,
        serviceBranchHome ? 'serviceWorker' : 'rider',
      );
    }
    _applyLoginTabIntentIfPresent(prefs);
    await prefs.setString('user_type', _prefsKeyForUserType(_userType));
    if (_userType == UserType.serviceWorker) {
      await prefs.setString('active_provider_id', _userEmail ?? '');
      await ProviderBackgroundLocation.setEnabled(_onlineForWork);
    }
    notifyListeners();
  }

  Future<void> _persistSessionFromAuthResponse(
    ({AuthUserDto user, String accessToken, String refreshToken}) r,
  ) async {
    await AuthTokenStorage.instance.save(
      accessToken: r.accessToken,
      refreshToken: r.refreshToken,
      userId: r.user.id,
    );
    await _applyUserDto(r.user);
  }

  void _hydrateLocalProfileFields(
    SharedPreferences prefs, {
    bool applyUserTypeFromPrefs = true,
  }) {
    _serviceProfession = prefs.getString('service_profession');
    _serviceNic = prefs.getString('service_nic');
    _serviceImagePath = prefs.getString('service_image_path');
    _serviceNicFrontImagePath = prefs.getString('service_nic_front_image_path');
    _serviceNicBackImagePath = prefs.getString('service_nic_back_image_path');
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
    _onlineForWork = prefs.getBool('worker_online_for_work') ?? true;
    _teamRiderId = prefs.getString('team_rider_id');
    _teamRiderBusinessId = prefs.getString('team_rider_business_id');
    _teamRiderDisplayName = prefs.getString('team_rider_display_name');
    if (applyUserTypeFromPrefs) {
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
    }
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final access = await AuthTokenStorage.instance.getAccessToken();

    if (OfflineMode.enabled) {
      final saved = prefs.getString('user_email');
      if (saved != null && saved.trim().isNotEmpty) {
        _userEmail = saved;
        _status = AuthStatus.authenticated;
        _hydrateLocalProfileFields(prefs);
        notifyListeners();
      }
      return;
    }

    if (access == null || access.isEmpty) {
      final teamRider = prefs.getString('team_rider_id');
      if ((teamRider ?? '').trim().isNotEmpty) {
        final email = prefs.getString('user_email');
        if (email != null) {
          _userEmail = email;
          _status = AuthStatus.authenticated;
          _hydrateLocalProfileFields(prefs);
          if (_userType == UserType.serviceWorker) {
            await prefs.setString('active_provider_id', email);
            await ProviderBackgroundLocation.setEnabled(_onlineForWork);
          }
          notifyListeners();
        }
        return;
      }
      if (prefs.getString('user_email') != null) {
        await logout();
      }
      return;
    }

    if (ApiConfig.shouldPromptForLanHost) {
      _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
      notifyListeners();
      return;
    }

    final refresh = await AuthTokenStorage.instance.getRefreshToken();
    try {
      try {
        final me = await _authApi.me();
        await _applyUserDto(me);
      } on ApiException catch (e) {
        if (e.statusCode == 401 &&
            refresh != null &&
            refresh.trim().isNotEmpty) {
          final next = await _authApi.refresh(refreshToken: refresh);
          await AuthTokenStorage.instance.save(
            accessToken: next.accessToken,
            refreshToken: next.refreshToken,
          );
          final me = await _authApi.me();
          await _applyUserDto(me);
        } else {
          rethrow;
        }
      }
      _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
      notifyListeners();
    } on ApiException catch (e) {
      // Server off / no network: `statusCode` is null. Don't wipe the session.
      if (e.statusCode == null) {
        _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
        notifyListeners();
        return;
      }
      await logout();
    } catch (e) {
      final s = e.toString();
      if (s.contains('SocketException') || s.contains('Connection refused')) {
        _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
        notifyListeners();
        return;
      }
      await logout();
    }
  }

  Future<void> setOnlineForWork(bool value) async {
    if (_onlineForWork == value) return;
    _onlineForWork = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('worker_online_for_work', value);
    // Background location updates for service workers only.
    if (_userType == UserType.serviceWorker) {
      await ProviderBackgroundLocation.setEnabled(value);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (email.trim().isEmpty || password.length < 6) {
      return false;
    }
    _ensureBackendUrlForDevice();
    if (OfflineMode.enabled) {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = email.trim();
      _userType = UserType.businessOwner;
      _status = AuthStatus.authenticated;
      await prefs.setString('user_email', _userEmail!);
      await prefs.setString('user_type', 'businessOwner');
      notifyListeners();
      return true;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final session = await _authApi.login(
        identifier: email.trim(),
        password: password,
      );
      await _persistSessionFromAuthResponse(session);
      final prefs = await SharedPreferences.getInstance();
      _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Phone login (same API as email: `identifier` + password).
  Future<bool> loginWithPhone(
    String phone, {
    required String password,
  }) async {
    if (phone.trim().length < 10 || password.length < 6) {
      return false;
    }
    _ensureBackendUrlForDevice();
    if (OfflineMode.enabled) {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = phone.trim();
      // For offline: treat phone logins as customer by default.
      _userType = UserType.customer;
      _status = AuthStatus.authenticated;
      await prefs.setString('user_email', _userEmail!);
      await prefs.setString('user_type', 'customer');
      notifyListeners();
      return true;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final session = await _authApi.login(
        identifier: phone.trim(),
        password: password,
      );
      await _persistSessionFromAuthResponse(session);
      final prefs = await SharedPreferences.getInstance();
      _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);

      // Pool rider login clears any prior team-rider session when server says rider.
      if (_userType == UserType.rider) {
        _teamRiderId = null;
        _teamRiderBusinessId = null;
        _teamRiderDisplayName = null;
        await prefs.remove('team_rider_id');
        await prefs.remove('team_rider_business_id');
        await prefs.remove('team_rider_display_name');
      }
      if (_userType == UserType.serviceWorker) {
        await prefs.setString('active_provider_id', _userEmail ?? phone.trim());
        await ProviderBackgroundLocation.setEnabled(_onlineForWork);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Team rider login (owner-added riders). Uses riderId + phone pair.
  /// Local-only session (no JWT); clears any API tokens first.
  Future<bool> loginAsTeamRider({
    required String phone,
    required String riderId,
    required String businessId,
    required String riderName,
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 450));

    final p = phone.trim();
    final id = riderId.trim();
    if (p.length < 10 || id.isEmpty || businessId.trim().isEmpty) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    await AuthTokenStorage.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoginTabIntentKey);
    await prefs.setString('user_email', p);
    await prefs.setString('user_type', 'rider');
    await prefs.setString('team_rider_id', id);
    await prefs.setString('team_rider_business_id', businessId.trim());
    await prefs.setString('team_rider_display_name', riderName.trim());

    _userEmail = p;
    _userType = UserType.rider;
    _teamRiderId = id;
    _teamRiderBusinessId = businessId.trim();
    _teamRiderDisplayName = riderName.trim();
    _onlineForWork = prefs.getBool('worker_online_for_work') ?? true;

    _status = AuthStatus.authenticated;
    _isLoading = false;
    notifyListeners();
    return true;
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
    _onlineForWork = prefs.getBool('worker_online_for_work') ?? true;
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
    required String nicFrontImagePath,
    required String nicBackImagePath,
    required String plan,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _serviceProfession = profession;
    _serviceNic = nic;
    _serviceImagePath = imagePath;
    _serviceNicFrontImagePath = nicFrontImagePath;
    _serviceNicBackImagePath = nicBackImagePath;
    _servicePlan = plan;
    await prefs.setString('service_profession', profession);
    await prefs.setString('service_nic', nic);
    await prefs.setString('service_image_path', imagePath);
    await prefs.setString('service_nic_front_image_path', nicFrontImagePath);
    await prefs.setString('service_nic_back_image_path', nicBackImagePath);
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
    _onlineForWork = prefs.getBool('worker_online_for_work') ?? true;
    notifyListeners();
  }

  /// Demo top-up: adds money to rider wallet and persists on device.
  Future<void> addRiderWalletTopUp(double amount) async {
    final next = (_riderWallet ?? 0) + amount;
    _riderWallet = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rider_wallet', next);
    notifyListeners();
  }

  Future<void> setServiceProfessionOnly(String profession) async {
    _serviceProfession = profession;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('service_profession', profession);
    notifyListeners();
  }

  String _apiRoleForSignUp(UserType userType) {
    return switch (userType) {
      UserType.customer => 'customer',
      UserType.businessOwner => 'businessOwner',
      UserType.serviceWorker => 'serviceWorker',
      UserType.rider => 'rider',
    };
  }

  Future<bool> signUp(
    String identifier,
    String password, {
    UserType userType = UserType.businessOwner,
    String? name,
  }) async {
    if (password.length < 6) {
      return false;
    }
    final nm = (name ?? '').trim();
    if (nm.length < 2) {
      return false;
    }
    final trimmed = identifier.trim();
    final isPhoneRole = userType == UserType.customer ||
        userType == UserType.serviceWorker ||
        userType == UserType.rider;
    if (isPhoneRole) {
      final digits = trimmed.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10 || digits.length > 15) {
        return false;
      }
    }
    if (!isPhoneRole && trimmed.isEmpty) {
      return false;
    }

    _ensureBackendUrlForDevice();
    if (OfflineMode.enabled) {
      final prefs = await SharedPreferences.getInstance();
      _userEmail = trimmed;
      _userType = userType;
      _status = AuthStatus.authenticated;
      await prefs.setString('user_email', _userEmail!);
      await prefs.setString('user_type', _prefsKeyForUserType(_userType));
      notifyListeners();
      return true;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final session = await _authApi.register(
        phone: isPhoneRole ? trimmed : null,
        email: isPhoneRole ? null : trimmed,
        password: password,
        role: _apiRoleForSignUp(userType),
        name: nm,
      );
      await _persistSessionFromAuthResponse(session);
      final prefs = await SharedPreferences.getInstance();
      _hydrateLocalProfileFields(prefs, applyUserTypeFromPrefs: false);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException {
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await AuthTokenStorage.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_type');
    await prefs.remove('team_rider_id');
    await prefs.remove('team_rider_business_id');
    await prefs.remove('team_rider_display_name');
    await prefs.remove('service_profession');
    await prefs.remove('service_nic');
    await prefs.remove('service_image_path');
    await prefs.remove('service_nic_front_image_path');
    await prefs.remove('service_nic_back_image_path');
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
    await prefs.remove('worker_online_for_work');
    await prefs.remove('remote_business_mongo_id');
    await prefs.remove(_kLoginTabIntentKey);
    _userEmail = null;
    _serviceProfession = null;
    _serviceNic = null;
    _serviceImagePath = null;
    _serviceNicFrontImagePath = null;
    _serviceNicBackImagePath = null;
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
    _onlineForWork = true;
    _userType = UserType.businessOwner;
    _teamRiderId = null;
    _teamRiderBusinessId = null;
    _teamRiderDisplayName = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
