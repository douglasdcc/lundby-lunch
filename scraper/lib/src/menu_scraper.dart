import 'dart:convert';

import 'package:lunch_core/lunch_core.dart';

import 'fetcher.dart';
import 'restaurant_config.dart';
import 'scraped_menu.dart';

/// Builds `menus.json` for the target week. Every restaurant is scraped
/// again; a menu already found for the week is kept when the new scrape
/// fails or finds none. Restaurants whose menu is only an image are not
/// scraped.
class MenuScraper {
  MenuScraper({
    required this.restaurants,
    required this.fetcher,
    DateTime Function()? now,
    void Function(String message)? log,
  }) : _now = now ?? DateTime.now,
       _log = log ?? print;

  final List<RestaurantConfig> restaurants;
  final Fetcher fetcher;
  final DateTime Function() _now;
  final void Function(String message) _log;

  /// [previous] is the currently published `menus.json`, if any.
  Future<WeekMenus> run({WeekMenus? previous}) async {
    final now = _now();
    final target = IsoWeek.targetFor(now);
    final kept = previous != null && previous.week == target
        ? {
            for (final restaurant in previous.restaurants)
              restaurant.id: restaurant,
          }
        : const <String, RestaurantMenu>{};

    _log('Target week: $target');
    final menus = <RestaurantMenu>[];
    for (final config in restaurants) {
      final scraped = await _scrape(config, target, now);
      final existing = kept[config.id];
      if (existing == null || existing.status != MenuStatus.ok) {
        menus.add(scraped);
      } else if (scraped.status case MenuStatus.missing || MenuStatus.error) {
        _log('${config.id}: kept the previous menu');
        menus.add(
          _build(
            config,
            MenuStatus.ok,
            existing.days,
            existing.weekly,
            existing.fetchedAt,
          ),
        );
      } else if (_sameDishes(scraped, existing)) {
        // Keeps the file unchanged, so the site is not deployed again.
        menus.add(
          _build(
            config,
            MenuStatus.ok,
            scraped.days,
            scraped.weekly,
            existing.fetchedAt,
          ),
        );
      } else {
        menus.add(scraped);
      }
    }
    return WeekMenus(
      week: target,
      generatedAt: now.toUtc(),
      restaurants: menus,
    );
  }

  Future<RestaurantMenu> _scrape(
    RestaurantConfig config,
    IsoWeek target,
    DateTime now,
  ) async {
    final parser = config.parser;
    if (parser == null) {
      _log('${config.id}: menu is only an image');
      return _build(config, MenuStatus.imageOnly, const [], const [], null);
    }

    final ScrapedMenu scraped;
    try {
      scraped = await parser.scrape(fetcher, target);
    } on Exception catch (error) {
      _log('${config.id}: error: $error');
      return _build(config, MenuStatus.error, const [], const [], null);
    }

    if (scraped.week != target.week || !scraped.hasDishes) {
      _log(
        '${config.id}: missing (page shows week ${scraped.week}, '
        '${scraped.hasDishes ? 'with' : 'no'} dishes)',
      );
      return _build(config, MenuStatus.missing, const [], const [], null);
    }

    final days = [
      for (final day in scraped.days)
        if (day.dishes.isNotEmpty)
          DayMenu(
            date: target.monday.add(Duration(days: day.weekday - 1)),
            dishes: day.dishes,
          ),
    ];
    _log(
      '${config.id}: ok (${days.length} days, ${scraped.weekly.length} weekly)',
    );
    return _build(config, MenuStatus.ok, days, scraped.weekly, now.toUtc());
  }

  bool _sameDishes(RestaurantMenu a, RestaurantMenu b) {
    String dishes(RestaurantMenu menu) => jsonEncode([
      for (final day in menu.days) day.toJson(),
      for (final dish in menu.weekly) dish.toJson(),
    ]);
    return dishes(a) == dishes(b);
  }

  RestaurantMenu _build(
    RestaurantConfig config,
    MenuStatus status,
    List<DayMenu> days,
    List<Dish> weekly,
    DateTime? fetchedAt,
  ) => RestaurantMenu(
    id: config.id,
    name: config.name,
    website: config.website,
    status: status,
    address: config.address,
    lunchHours: config.lunchHours,
    fetchedAt: fetchedAt,
    days: days,
    weekly: weekly,
  );
}
