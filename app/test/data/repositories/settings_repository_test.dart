import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/domain/models/settings.dart';

import '../../testing/fakes.dart';

void main() {
  late FakeKeyValueStore store;

  setUp(() => store = FakeKeyValueStore());

  test('has defaults when nothing is saved', () {
    final settings = SettingsRepository(store: store);

    expect(settings.language, isNull);
    expect(settings.theme, ThemePreference.system);
    expect(settings.startView, MenuView.today);
    expect(settings.restaurantOrder, isEmpty);
    expect(settings.hiddenRestaurants, isEmpty);
  });

  test('saved values are read back by a new instance', () async {
    final settings = SettingsRepository(store: store);
    await settings.setLanguage(Language.sv);
    await settings.setTheme(ThemePreference.dark);
    await settings.setStartView(MenuView.week);
    await settings.setRestaurantOrder(['b', 'a']);
    await settings.setRestaurantHidden('a', hidden: true);

    final reloaded = SettingsRepository(store: store);

    expect(reloaded.language, Language.sv);
    expect(reloaded.theme, ThemePreference.dark);
    expect(reloaded.startView, MenuView.week);
    expect(reloaded.restaurantOrder, ['b', 'a']);
    expect(reloaded.hiddenRestaurants, {'a'});
  });

  test('unknown saved values fall back to defaults', () {
    store.values['settings.theme'] = 'neon';
    store.values['settings.language'] = 'de';

    final settings = SettingsRepository(store: store);

    expect(settings.theme, ThemePreference.system);
    expect(settings.language, isNull);
  });

  test('notifies listeners on change', () async {
    final settings = SettingsRepository(store: store);
    var notified = 0;
    settings.addListener(() => notified++);

    await settings.setTheme(ThemePreference.light);
    await settings.setRestaurantHidden('a', hidden: true);

    expect(notified, 2);
  });

  test('setRestaurantHidden(false) shows the restaurant again', () async {
    final settings = SettingsRepository(store: store);
    await settings.setRestaurantHidden('a', hidden: true);
    await settings.setRestaurantHidden('a', hidden: false);

    expect(settings.hiddenRestaurants, isEmpty);
  });

  group('arrange', () {
    final restaurants = [
      buildRestaurant('a'),
      buildRestaurant('b'),
      buildRestaurant('c'),
    ];

    List<String> ids(List<RestaurantMenu> list) => [for (final r in list) r.id];

    test('keeps the original order without preferences', () {
      final settings = SettingsRepository(store: store);
      expect(ids(settings.arrange(restaurants)), ['a', 'b', 'c']);
    });

    test(
      'puts ordered restaurants first, then the rest in original order',
      () async {
        final settings = SettingsRepository(store: store);
        await settings.setRestaurantOrder(['c']);

        expect(ids(settings.arrange(restaurants)), ['c', 'a', 'b']);
      },
    );

    test('drops hidden restaurants unless includeHidden is set', () async {
      final settings = SettingsRepository(store: store);
      await settings.setRestaurantHidden('b', hidden: true);

      expect(ids(settings.arrange(restaurants)), ['a', 'c']);
      expect(ids(settings.arrange(restaurants, includeHidden: true)), [
        'a',
        'b',
        'c',
      ]);
    });
  });
}
