import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/services/menu_source.dart';
import 'package:lundby_lunch/data/services/sample_menu_source.dart';

import '../../testing/fakes.dart';

void main() {
  group('HttpMenuSource', () {
    test('requests the URL with the week key and decodes UTF-8', () async {
      late Uri requested;
      final client = MockClient((request) async {
        requested = request.url;
        // No charset header, so only explicit UTF-8 decoding gets "ä" right.
        return http.Response.bytes(utf8.encode('{"name":"Z:äta"}'), 200);
      });
      final source = HttpMenuSource(
        url: Uri.parse('https://example.com/data/menus.json'),
        client: client,
      );

      final body = await source.fetchMenus(week41);

      expect(
        requested.toString(),
        'https://example.com/data/menus.json?w=2026-W41',
      );
      expect(body, '{"name":"Z:äta"}');
    });

    test('throws MenuSourceException on a non-200 response', () async {
      final source = HttpMenuSource(
        url: Uri.parse('https://example.com/menus.json'),
        client: MockClient((_) async => http.Response('missing', 404)),
      );

      expect(
        () => source.fetchMenus(week41),
        throwsA(isA<MenuSourceException>()),
      );
    });
  });

  group('SampleMenuSource', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('bundled sample is valid and moved to the requested week', () async {
      const week = IsoWeek(2027, 2);

      final menus = WeekMenus.decode(await SampleMenuSource().fetchMenus(week));

      expect(menus.week, week);
      expect(menus.restaurants, isNotEmpty);
      final firstDay = menus.restaurants
          .firstWhere((restaurant) => restaurant.days.isNotEmpty)
          .days
          .first;
      expect(firstDay.date, week.monday);
    });
  });

  test('moveToWeek shifts every date by whole weeks', () {
    final moved = moveToWeek(buildMenus(), const IsoWeek(2026, 43));

    expect(moved.week, const IsoWeek(2026, 43));
    expect(
      moved.restaurants.first.days.map((day) => day.date),
      const IsoWeek(2026, 43).weekdays,
    );
    expect(
      moved.restaurants.first.dishesOn(DateTime(2026, 10, 19)).single.name.en,
      'a 1 en',
    );
  });
}
