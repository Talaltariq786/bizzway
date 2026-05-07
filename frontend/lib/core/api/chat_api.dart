import 'api_client.dart';
import 'api_paths.dart';

class ChatApi {
  ChatApi(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listChats() async {
    final res = await _api.getJson(ApiPaths.chats);
    final data = res['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<Map<String, dynamic>> createChat({
    required String otherUserId,
    String? businessId,
  }) async {
    return _api.postJson(
      ApiPaths.chats,
      body: {
        'otherUserId': otherUserId,
        if (businessId != null && businessId.isNotEmpty) 'businessId': businessId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listMessages(String chatId) async {
    final res = await _api.getJson(ApiPaths.chatMessages(chatId));
    final data = res['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String chatId, {
    required String text,
  }) async {
    return _api.postJson(
      ApiPaths.chatMessages(chatId),
      body: {'text': text},
    );
  }
}

