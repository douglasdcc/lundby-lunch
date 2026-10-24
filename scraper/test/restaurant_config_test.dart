import 'dart:convert';
import 'dart:io';

import 'package:lunch_scraper/lunch_scraper.dart';
import 'package:test/test.dart';

void main() {
  test('restaurants.json is valid', () {
    final restaurants = RestaurantConfig.decodeList(
      File('restaurants.json').readAsStringSync(),
    );

    expect(
      [for (final r in restaurants) r.id],
      [
        'roots',
        'zata',
        'spira',
        'barcentro',
        'nordic-taste-lab',
        'lilla-kathmandu',
      ],
    );
    expect(
      [for (final r in restaurants) r.parser.runtimeType],
      [
        RootsParser,
        MashieParser,
        SpiraParser,
        BarCentroParser,
        Null, // Nordic Taste Lab only publishes its menu as an image.
        LillaKathmanduParser,
      ],
    );
    for (final restaurant in restaurants) {
      for (final url in [
        restaurant.website.sv,
        restaurant.website.en,
      ].nonNulls) {
        expect(url, startsWith('https://'), reason: restaurant.id);
      }
    }
  });

  String entry(Map<String, Object?> source, {String id = 'a'}) => jsonEncode({
    'id': id,
    'name': 'A',
    'website': {'sv': 'https://a.example'},
    'source': source,
  });

  test('an image source has no parser', () {
    final restaurant = RestaurantConfig.decodeList(
      '[${entry({'type': 'image'})}]',
    ).single;
    expect(restaurant.parser, isNull);
  });

  test('rejects an unknown source type', () {
    expect(
      () => RestaurantConfig.decodeList('[${entry({'type': 'pdf'})}]'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects URLs that are not https', () {
    expect(
      () => RestaurantConfig.decodeList(
        '[${entry({'type': 'spira', 'url': 'http://a.example'})}]',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects missing fields and duplicate ids', () {
    expect(
      () => RestaurantConfig.decodeList('[{"id": "a"}]'),
      throwsA(isA<FormatException>()),
    );
    final spira = {'type': 'spira', 'url': 'https://a.example'};
    expect(
      () => RestaurantConfig.decodeList('[${entry(spira)}, ${entry(spira)}]'),
      throwsA(isA<FormatException>()),
    );
  });
}
