import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lunch_core/lunch_core.dart';

/// Provides the raw `menus.json` content.
abstract interface class MenuSource {
  /// Returns the JSON for the latest published menus. [week] is the week the
  /// app wants; the response may still contain an older week.
  Future<String> fetchMenus(IsoWeek week);
}

class MenuSourceException implements Exception {
  const MenuSourceException(this.message);

  final String message;

  @override
  String toString() => 'MenuSourceException: $message';
}

/// Downloads `menus.json` over HTTPS.
class HttpMenuSource implements MenuSource {
  HttpMenuSource({required this._url, http.Client? client})
    : _client = client ?? http.Client();

  final Uri _url;
  final http.Client _client;

  @override
  Future<String> fetchMenus(IsoWeek week) async {
    // The week parameter makes caches treat each week as a new file.
    final uri = _url.replace(
      queryParameters: {..._url.queryParameters, 'w': week.key},
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw MenuSourceException('HTTP ${response.statusCode} for $uri');
    }
    return utf8.decode(response.bodyBytes);
  }
}
