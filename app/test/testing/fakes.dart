import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/services/key_value_store.dart';
import 'package:lundby_lunch/data/services/menu_source.dart';

/// Wednesday of week 41, 2026.
final wednesday = DateTime(2026, 10, 7, 12);

const week41 = IsoWeek(2026, 41);

class FakeKeyValueStore implements KeyValueStore {
  final values = <String, Object>{};

  @override
  String? getString(String key) => values[key] as String?;

  @override
  List<String>? getStringList(String key) => values[key] as List<String>?;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      values[key] = List.of(value);
}

class FakeMenuSource implements MenuSource {
  FakeMenuSource([this.menus]);

  /// What the next fetch returns. Ignored when [error] is set.
  WeekMenus? menus;
  Exception? error;
  final requestedWeeks = <IsoWeek>[];

  int get calls => requestedWeeks.length;

  @override
  Future<String> fetchMenus(IsoWeek week) async {
    requestedWeeks.add(week);
    final error = this.error;
    if (error != null) throw error;
    final menus = this.menus;
    if (menus == null) throw const MenuSourceException('No menus');
    return menus.encode();
  }
}

/// A restaurant with one dish per weekday named `<id> <weekday>`, e.g.
/// `spira 1` on Monday, plus an optional weekly dish.
RestaurantMenu buildRestaurant(
  String id, {
  IsoWeek week = week41,
  MenuStatus status = MenuStatus.ok,
  bool withWeekly = false,
  String? name,
}) => RestaurantMenu(
  id: id,
  name: name ?? 'Restaurant $id',
  website: LocalizedText(
    sv: 'https://$id.example/sv',
    en: 'https://$id.example/en',
  ),
  status: status,
  lunchHours: '11:00–13:30',
  days: status != MenuStatus.ok
      ? const []
      : [
          for (final day in week.weekdays)
            DayMenu(
              date: day,
              dishes: [
                Dish(
                  name: LocalizedText(
                    sv: '$id ${day.weekday} sv',
                    en: '$id ${day.weekday} en',
                  ),
                  price: 100 + day.weekday,
                ),
              ],
            ),
        ],
  weekly: withWeekly
      ? const [
          Dish(
            category: LocalizedText(
              sv: 'Veckans soppa',
              en: 'Soup of the week',
            ),
            name: LocalizedText(sv: 'Soppa', en: 'Soup'),
          ),
        ]
      : const [],
);

WeekMenus buildMenus({
  IsoWeek week = week41,
  List<RestaurantMenu>? restaurants,
}) => WeekMenus(
  week: week,
  generatedAt: week.monday.add(const Duration(hours: 6)),
  restaurants:
      restaurants ??
      [buildRestaurant('a', week: week), buildRestaurant('b', week: week)],
);
