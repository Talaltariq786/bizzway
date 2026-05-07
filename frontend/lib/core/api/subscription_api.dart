import 'api_client.dart';
import 'api_paths.dart';

/// Bizzway merchant subscription (JazzCash / EasyPaisa) — `bizzwaybackend` `/api/subscriptions/*`.
class SubscriptionApi {
  SubscriptionApi._();

  static Future<List<Map<String, dynamic>>> fetchPlans() async {
    final m = await ApiClient().getJson(ApiPaths.subscriptionsPlans);
    final plans = m['plans'];
    if (plans is! List) return const [];
    return plans
        .map((e) => e is Map<String, dynamic>
            ? e
            : (e is Map
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{}))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<({String plan, DateTime? expiresAt})> fetchStatus(
    String businessId,
  ) async {
    final m = await ApiClient().getJson(
      ApiPaths.subscriptionsStatus,
      query: {'businessId': businessId},
    );
    final plan = m['subscriptionPlan']?.toString() ?? 'free';
    final raw = m['subscriptionExpiresAt'];
    DateTime? ex;
    if (raw != null) {
      ex = DateTime.tryParse(raw.toString());
    }
    return (plan: plan, expiresAt: ex);
  }

  static Future<Map<String, dynamic>> checkout({
    required String businessId,
    required String planId, // starter | pro | business
    required String provider, // jazzcash | easypaisa
  }) async {
    return ApiClient().postJson(
      ApiPaths.subscriptionsCheckout,
      body: {
        'businessId': businessId,
        'planId': planId,
        'provider': provider,
      },
    );
  }
}

String? firstHttpUrlInJson(Object? o) {
  if (o == null) return null;
  if (o is String) {
    final u = RegExp(r'https?://[^\s"<>]+').firstMatch(o);
    return u?.group(0);
  }
  if (o is Map) {
    for (final e in o.values) {
      final f = firstHttpUrlInJson(e);
      if (f != null) return f;
    }
  }
  if (o is List) {
    for (final e in o) {
      final f = firstHttpUrlInJson(e);
      if (f != null) return f;
    }
  }
  return null;
}

String buildEasypaisaFormHtml(String postUrl, Map<String, dynamic> fields) {
  final buf = StringBuffer();
  buf.writeln('<!DOCTYPE html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width" /></head>'
      '<body onload="document.getElementById(\'f\').submit()">'
      '<form id="f" method="POST" action="${_escapeAttr(postUrl)}">');
  for (final e in fields.entries) {
    buf.writeln(
      '<input type="hidden" name="${_escapeAttr(e.key)}" value="${_escapeAttr(e.value?.toString() ?? '')}" />',
    );
  }
  buf.writeln('</form><p>Payment page khul raha hai…</p></body></html>');
  return buf.toString();
}

String _escapeAttr(String s) {
  return s
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
