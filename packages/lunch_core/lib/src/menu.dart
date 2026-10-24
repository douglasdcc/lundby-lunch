import 'dart:convert';

import 'dates.dart';
import 'iso_week.dart';
import 'json.dart';
import 'localized_text.dart';

/// How spicy a dish is.
enum SpiceLevel {
  mild,
  medium,
  hot;

  /// Null for an unknown or missing level.
  static SpiceLevel? tryParse(String? value) {
    for (final level in values) {
      if (level.name == value) return level;
    }
    return null;
  }
}

final class Dish {
  const Dish({
    required this.name,
    this.description,
    this.category,
    this.price,
    this.spice,
    this.tags = const [],
  });

  factory Dish.fromJson(JsonMap json) => Dish(
    name: LocalizedText.fromJson(json['name'] as JsonMap),
    description: switch (json['description']) {
      final JsonMap description => LocalizedText.fromJson(description),
      _ => null,
    },
    category: switch (json['category']) {
      final JsonMap category => LocalizedText.fromJson(category),
      _ => null,
    },
    price: json['price'] as int?,
    spice: SpiceLevel.tryParse(json['spice'] as String?),
    tags: [
      for (final tag in json['tags'] as List<Object?>? ?? const [])
        tag as String,
    ],
  );

  final LocalizedText name;

  /// What the dish is made of, when the restaurant writes it apart from
  /// the name.
  final LocalizedText? description;

  /// For example "Vegetarian" or "Soup of the week".
  final LocalizedText? category;

  /// Price in SEK.
  final int? price;
  final SpiceLevel? spice;

  /// Diet labels as printed by the restaurant, such as `L` or `G`.
  final List<String> tags;

  JsonMap toJson() => {
    'name': name.toJson(),
    'description': ?description?.toJson(),
    'category': ?category?.toJson(),
    'price': ?price,
    'spice': ?spice?.name,
    if (tags.isNotEmpty) 'tags': tags,
  };
}

final class DayMenu {
  const DayMenu({required this.date, required this.dishes});

  factory DayMenu.fromJson(JsonMap json) => DayMenu(
    date: parseDate(json['date'] as String),
    dishes: readList(json, 'dishes', Dish.fromJson),
  );

  /// UTC midnight of the day.
  final DateTime date;
  final List<Dish> dishes;

  JsonMap toJson() => {
    'date': formatDate(date),
    'dishes': [for (final dish in dishes) dish.toJson()],
  };
}

enum MenuStatus {
  /// The menu for the week was scraped successfully.
  ok,

  /// The restaurant has not published the menu for the week yet.
  missing,

  /// Scraping failed.
  error,

  /// The restaurant only publishes its menu in a form that can't be read,
  /// such as an image, so only its website is shown.
  imageOnly;

  static MenuStatus parse(String? value) =>
      values.firstWhere((status) => status.name == value, orElse: () => error);
}

final class RestaurantMenu {
  const RestaurantMenu({
    required this.id,
    required this.name,
    required this.website,
    required this.status,
    this.address,
    this.lunchHours,
    this.notes,
    this.fetchedAt,
    this.days = const [],
    this.weekly = const [],
  });

  factory RestaurantMenu.fromJson(JsonMap json) => RestaurantMenu(
    id: json['id'] as String,
    name: json['name'] as String,
    website: LocalizedText.fromJson(json['website'] as JsonMap),
    status: MenuStatus.parse(json['status'] as String?),
    address: json['address'] as String?,
    lunchHours: json['lunchHours'] as String?,
    notes: switch (json['notes']) {
      final JsonMap notes => LocalizedText.fromJson(notes),
      _ => null,
    },
    fetchedAt: switch (json['fetchedAt']) {
      final String value => DateTime.parse(value),
      _ => null,
    },
    days: readList(json, 'days', DayMenu.fromJson),
    weekly: readList(json, 'weekly', Dish.fromJson),
  );

  final String id;
  final String name;

  /// Website URL for each language.
  final LocalizedText website;
  final MenuStatus status;
  final String? address;
  final String? lunchHours;

  /// Text printed with the menu that is not a dish, such as what the price
  /// includes.
  final LocalizedText? notes;

  /// When the menu was last scraped successfully.
  final DateTime? fetchedAt;
  final List<DayMenu> days;

  /// Dishes served all week, such as "Soup of the week".
  final List<Dish> weekly;

  /// The dishes served on [date], or an empty list.
  List<Dish> dishesOn(DateTime date) {
    final day = dateOnly(date);
    for (final menu in days) {
      if (menu.date == day) return menu.dishes;
    }
    return const [];
  }

  JsonMap toJson() => {
    'id': id,
    'name': name,
    'website': website.toJson(),
    'status': status.name,
    'address': ?address,
    'lunchHours': ?lunchHours,
    'notes': ?notes?.toJson(),
    'fetchedAt': ?fetchedAt?.toUtc().toIso8601String(),
    'days': [for (final day in days) day.toJson()],
    'weekly': [for (final dish in weekly) dish.toJson()],
  };
}

/// The content of `menus.json`: every restaurant's menu for one week.
final class WeekMenus {
  const WeekMenus({
    required this.week,
    required this.generatedAt,
    required this.restaurants,
  });

  /// Throws a [FormatException] when [json] is not valid menus data.
  factory WeekMenus.fromJson(JsonMap json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Unsupported schemaVersion: $version');
    }
    try {
      return WeekMenus(
        week: IsoWeek(json['isoYear'] as int, json['isoWeek'] as int),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        restaurants: readList(json, 'restaurants', RestaurantMenu.fromJson),
      );
    } on TypeError catch (error) {
      throw FormatException('Invalid menus data: $error');
    }
  }

  /// Throws a [FormatException] when [source] is not valid menus JSON.
  factory WeekMenus.decode(String source) {
    final json = jsonDecode(source);
    if (json is! JsonMap) throw const FormatException('Expected a JSON object');
    return WeekMenus.fromJson(json);
  }

  static const schemaVersion = 1;

  final IsoWeek week;
  final DateTime generatedAt;
  final List<RestaurantMenu> restaurants;

  /// Whether every restaurant has its menu for the week, or never has one
  /// that can be read.
  bool get isComplete => restaurants.every(
    (restaurant) => switch (restaurant.status) {
      MenuStatus.ok || MenuStatus.imageOnly => true,
      MenuStatus.missing || MenuStatus.error => false,
    },
  );

  JsonMap toJson() => {
    'schemaVersion': schemaVersion,
    'isoYear': week.year,
    'isoWeek': week.week,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'restaurants': [for (final restaurant in restaurants) restaurant.toJson()],
  };

  String encode() => jsonEncode(toJson());
}
