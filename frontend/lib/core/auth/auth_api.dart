import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/api_paths.dart';

class AuthUserDto {
  AuthUserDto({
    required this.id,
    required this.roles,
    this.phone,
    this.email,
    this.name,
  });

  final String id;
  final List<String> roles;
  final String? phone;
  final String? email;
  final String? name;

  static AuthUserDto fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((e) => e.toString()).toList()
        : <String>[];
    return AuthUserDto(
      id: (json['id'] ?? '').toString(),
      roles: roles,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      name: json['name']?.toString(),
    );
  }
}

/// Login / register / me / refresh against `/api/auth/*` and `/api/me`.
class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  Future<({AuthUserDto user, String accessToken, String refreshToken})> register({
    String? phone,
    String? email,
    required String password,
    required String role,
    String? name,
  }) async {
    final body = <String, dynamic>{
      'password': password,
      'role': role,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    };
    final res = await _api.postJson(ApiPaths.authRegister, body: body);
    return _parseAuthPayload(res);
  }

  Future<({AuthUserDto user, String accessToken, String refreshToken})> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _api.postJson(
      ApiPaths.authLogin,
      body: {
        'identifier': identifier.trim(),
        'password': password,
      },
    );
    return _parseAuthPayload(res);
  }

  Future<({String accessToken, String refreshToken})> refresh({
    required String refreshToken,
  }) async {
    final res = await _api.postJson(
      ApiPaths.authRefresh,
      body: {'refreshToken': refreshToken},
    );
    final access = res['accessToken']?.toString();
    final refresh = res['refreshToken']?.toString();
    if (access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      throw ApiException('Invalid refresh response');
    }
    return (accessToken: access, refreshToken: refresh);
  }

  Future<AuthUserDto> me() async {
    final res = await _api.getJson(ApiPaths.me);
    return AuthUserDto.fromJson(res);
  }

  ({AuthUserDto user, String accessToken, String refreshToken}) _parseAuthPayload(
    Map<String, dynamic> res,
  ) {
    final userRaw = res['user'];
    final access = res['accessToken']?.toString();
    final refresh = res['refreshToken']?.toString();
    if (userRaw is! Map ||
        access == null ||
        refresh == null ||
        access.isEmpty ||
        refresh.isEmpty) {
      throw ApiException('Invalid auth response');
    }
    final user = AuthUserDto.fromJson(userRaw.cast<String, dynamic>());
    return (user: user, accessToken: access, refreshToken: refresh);
  }
}
