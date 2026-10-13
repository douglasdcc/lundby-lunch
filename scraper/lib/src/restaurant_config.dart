import 'dart:convert';

import 'package:lunch_core/lunch_core.dart';

import 'parsers/menu_parser.dart';

/// One entry of `restaurants.json`.
final class RestaurantConfig {
  const RestaurantConfig({
    required this.id,
    required this.name,
    required this.website,
    this.parser,
    this.address,
    this.lunchHours,
  });

  /// Throws a [FormatException] when [json] is not a valid entry.
  factory RestaurantConfig.fromJson(JsonMap json) {
    try {
      return RestaurantConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        website: LocalizedText.fromJson(json['website'] as JsonMap),
        address: json['address'] as String?,
        lunchHours: json['lunchHours'] as String?,
        parser: switch (json['source'] as JsonMap) {
          {'type': 'image'} => null,
          final source => MenuParser.fromSource(source),
        },
      );
    } on TypeError catch (error) {
      throw FormatException('Invalid restaurant entry $json: $error');
    }
  }

  /// Throws a [FormatException] when [source] is not a valid list of entries.
  static List<RestaurantConfig> decodeList(String source) {
    final json = jsonDecode(source);
    if (json is! List<Object?>) {
      throw const FormatException('Expected a JSON list');
    }
    final restaurants = [
      for (final entry in json) RestaurantConfig.fromJson(entry as JsonMap),
    ];
    final ids = {for (final restaurant in restaurants) restaurant.id};
    if (ids.length != restaurants.length) {
      throw const FormatException('Restaurant ids must be unique');
    }
    return restaurants;
  }

  final String id;
  final String name;
  final LocalizedText website;
  final String? address;
  final String? lunchHours;

  /// Null when the menu is only published as an image, which can't be read.
  final MenuParser? parser;
}
