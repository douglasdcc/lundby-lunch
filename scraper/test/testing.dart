import 'dart:convert';
import 'dart:io';

import 'package:lunch_scraper/lunch_scraper.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Serves canned responses by URL and records the requests.
class FakeFetcher implements Fetcher {
  FakeFetcher([Map<String, String>? responses]) : responses = responses ?? {};

  final Map<String, String> responses;
  final requested = <Uri>[];

  @override
  Future<String> get(Uri uri) async {
    requested.add(uri);
    final body = responses[uri.toString()];
    if (body == null) throw FetchException('No fake response for $uri');
    return body;
  }

  @override
  Future<List<int>> getBytes(Uri uri) async => utf8.encode(await get(uri));
}
