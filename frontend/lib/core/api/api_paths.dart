/// REST paths mounted by the Node backend (`backend/src/app.ts`).
/// Full URL = [ApiConfig.baseUrl] + path (e.g. `http://127.0.0.1:8080` + [health]).
abstract final class ApiPaths {
  ApiPaths._();

  static const health = '/health';

  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';
  static const authLogout = '/api/auth/logout';

  static const me = '/api/me';
  static const mePatch = '/api/me';
  static const meAddresses = '/api/me/addresses';

  static String meSelectAddress(String id) => '/api/me/addresses/$id/select';
  static String meDeleteAddress(String id) => '/api/me/addresses/$id';

  static const businesses = '/api/businesses';
  static const businessesMine = '/api/businesses/mine';

  static String businessProducts(String businessId) =>
      '/api/businesses/$businessId/products';
  static String businessById(String businessId) => '/api/businesses/$businessId';
  static String businessUpdateProduct(String productId) =>
      '/api/businesses/products/$productId';

  static const orders = '/api/orders';
  static String orderUpdateStatus(String orderId) => '/api/orders/$orderId/status';
  static String orderAssignRider(String orderId) => '/api/orders/$orderId/assign-rider';

  static const subscriptionsPlans = '/api/subscriptions/plans';
  static const subscriptionsStatus = '/api/subscriptions/status';
  static const subscriptionsCheckout = '/api/subscriptions/checkout';

  static const bookings = '/api/bookings';

  static const notifications = '/api/notifications';
  static String notificationById(String id) => '/api/notifications/$id';

  static const chats = '/api/chats';
  static String chatMessages(String chatId) => '/api/chats/$chatId/messages';

  static const pushTokens = '/api/push-tokens';
  static const pushTest = '/api/push/test';

  // Location
  static const serviceProvidersMeLocation = '/api/service-providers/me/location';
  static const ridersMeLocation = '/api/riders/me/location';
  static const serviceProvidersSearch = '/api/service-providers';

  static const ridersMe = '/api/riders/me';
  static const ridersMeOrders = '/api/riders/me/orders';
  static const serviceProvidersMe = '/api/service-providers/me';

  static const uploads = '/api/uploads';
}
