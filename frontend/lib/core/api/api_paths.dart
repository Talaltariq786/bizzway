/// REST paths mounted by the Node backend (`backend/src/app.ts`).
/// Full URL = [ApiConfig.baseUrl] + path (e.g. `http://127.0.0.1:8080` + [health]).
abstract final class ApiPaths {
  ApiPaths._();

  static const health = '/health';

  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';

  static const me = '/api/me';

  static const businesses = '/api/businesses';
  static const businessesMine = '/api/businesses/mine';

  static String businessProducts(String businessId) =>
      '/api/businesses/$businessId/products';

  static const orders = '/api/orders';
}
