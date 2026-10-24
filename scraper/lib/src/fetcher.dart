import 'dart:convert';

import 'package:http/http.dart' as http;

/// Downloads web pages and files.
abstract interface class Fetcher {
  /// The body of [uri] as text.
  Future<String> get(Uri uri);

  /// The body of [uri] as raw bytes, for files such as PDFs.
  Future<List<int>> getBytes(Uri uri);
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
  Future<String> get(Uri uri) async =>
      // Some pages mix encodings; a stray byte must not fail the whole page.
      utf8.decode(await getBytes(uri), allowMalformed: true);

  @override
  Future<List<int>> getBytes(Uri uri) async {
    final response = await _client
        .get(uri, headers: {'User-Agent': userAgent})
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw FetchException('HTTP ${response.statusCode} for $uri');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}
