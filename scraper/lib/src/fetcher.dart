import 'dart:convert';

import 'package:http/http.dart' as http;

/// Downloads web pages as text.
abstract interface class Fetcher {
  Future<String> get(Uri uri);
}

class FetchException implements Exception {
  const FetchException(this.message);

  final String message;

  @override
  String toString() => 'FetchException: $message';
}

class HttpFetcher implements Fetcher {
  HttpFetcher({http.Client? client}) : _client = client ?? http.Client();

  static const userAgent =
      'Mozilla/5.0 (compatible; LundbyLunchBot/1.0; +https://github.com/douglasdcc/lundby-lunch)';

  final http.Client _client;

  @override
  Future<String> get(Uri uri) async {
    final response = await _client
        .get(uri, headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw FetchException('HTTP ${response.statusCode} for $uri');
    }
    // Some pages mix encodings; a stray byte must not fail the whole page.
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  void close() => _client.close();
}
