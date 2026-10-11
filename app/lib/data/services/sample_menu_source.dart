import 'package:flutter/services.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/services/menu_source.dart';

/// Serves the bundled sample menus, moved to the requested week so that
/// "today" always has dishes.
class SampleMenuSource implements MenuSource {
  SampleMenuSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/sample/menus.json';

  final AssetBundle _bundle;

  @override
  Future<String> fetchMenus(IsoWeek week) async {
    final sample = WeekMenus.decode(await _bundle.loadString(assetPath));
    return moveToWeek(sample, week).encode();
  }
}

/// Returns a copy of [menus] with every date shifted into [week].
WeekMenus moveToWeek(WeekMenus menus, IsoWeek week) {
  final offset = week.monday.difference(menus.week.monday);
  return WeekMenus(
    week: week,
    generatedAt: menus.generatedAt.add(offset),
    restaurants: [
      for (final restaurant in menus.restaurants)
        RestaurantMenu(
          id: restaurant.id,
          name: restaurant.name,
          website: restaurant.website,
          status: restaurant.status,
          address: restaurant.address,
          lunchHours: restaurant.lunchHours,
          fetchedAt: restaurant.fetchedAt?.add(offset),
          days: [
            for (final day in restaurant.days)
              DayMenu(date: day.date.add(offset), dishes: day.dishes),
          ],
          weekly: restaurant.weekly,
        ),
    ],
  );
}
