import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/services/menu_source.dart';
import 'package:lundby_lunch/utils/result.dart';

import '../../testing/fakes.dart';

void main() {
  late FakeMenuSource source;
  late FakeKeyValueStore store;

  MenuRepository repository({DateTime? now}) =>
      MenuRepository(source: source, store: store, now: () => now ?? wednesday);

  void saveCache(WeekMenus menus) =>
      store.values[MenuRepository.cacheKey] = menus.encode();

  WeekMenus? savedCache() => switch (store.getString(MenuRepository.cacheKey)) {
    final String raw => WeekMenus.decode(raw),
    null => null,
  };

  WeekMenus unwrap(Result<WeekMenus> result) => switch (result) {
    Ok(:final value) => value,
    Error(:final error) => throw StateError('Expected Ok, got $error'),
  };

  setUp(() {
    source = FakeMenuSource(buildMenus());
    store = FakeKeyValueStore();
  });

  test('downloads and saves the menus when nothing is cached', () async {
    final menus = unwrap(await repository().loadMenus());

    expect(menus.week, week41);
    expect(source.requestedWeeks, [week41]);
    expect(savedCache()?.week, week41);
  });

  test(
    'uses a complete cache for the target week without downloading',
    () async {
      saveCache(buildMenus());

      final menus = unwrap(await repository().loadMenus());

      expect(menus.week, week41);
      expect(source.calls, 0);
    },
  );

  test('downloads again when the cached week is incomplete', () async {
    saveCache(
      buildMenus(
        restaurants: [
          buildRestaurant('a'),
          buildRestaurant('b', status: MenuStatus.missing),
        ],
      ),
    );

    final menus = unwrap(await repository().loadMenus());

    expect(source.calls, 1);
    expect(menus.isComplete, isTrue);
    expect(savedCache()?.isComplete, isTrue);
  });

  test('downloads again when the cache is from an older week', () async {
    saveCache(buildMenus(week: const IsoWeek(2026, 40)));

    final menus = unwrap(await repository().loadMenus());

    expect(source.calls, 1);
    expect(menus.week, week41);
  });

  test('asks for next week on weekends', () async {
    source.menus = buildMenus(week: const IsoWeek(2026, 42));

    await repository(now: DateTime(2026, 10, 10)).loadMenus();

    expect(source.requestedWeeks, [const IsoWeek(2026, 42)]);
  });

  test(
    'keeps newer cached menus when the download returns an older week',
    () async {
      final cached = buildMenus(
        week: const IsoWeek(2026, 42),
        restaurants: [
          buildRestaurant(
            'a',
            week: const IsoWeek(2026, 42),
            status: MenuStatus.missing,
          ),
        ],
      );
      saveCache(cached);
      source.menus = buildMenus();

      final menus = unwrap(
        await repository(now: DateTime(2026, 10, 12)).loadMenus(),
      );

      expect(menus.week, const IsoWeek(2026, 42));
      expect(savedCache()?.week, const IsoWeek(2026, 42));
    },
  );

  test('falls back to the cache when the download fails', () async {
    saveCache(buildMenus(week: const IsoWeek(2026, 40)));
    source.error = const MenuSourceException('offline');

    final menus = unwrap(await repository().loadMenus());

    expect(menus.week, const IsoWeek(2026, 40));
  });

  test(
    'returns an error when the download fails and nothing is cached',
    () async {
      source.error = const MenuSourceException('offline');

      final result = await repository().loadMenus();

      expect(result, isA<Error<WeekMenus>>());
    },
  );

  test('forceRefresh downloads even with a complete cache', () async {
    saveCache(buildMenus());

    await repository().loadMenus(forceRefresh: true);

    expect(source.calls, 1);
  });

  test(
    'forceRefresh reports a failed download instead of using the cache',
    () async {
      saveCache(buildMenus());
      source.error = const MenuSourceException('offline');

      final result = await repository().loadMenus(forceRefresh: true);

      expect(result, isA<Error<WeekMenus>>());
    },
  );

  test('ignores a corrupt cache', () async {
    store.values[MenuRepository.cacheKey] = 'not json';

    final menus = unwrap(await repository().loadMenus());

    expect(menus.week, week41);
    expect(source.calls, 1);
  });

  test('returns an error for invalid downloaded data', () async {
    source.error = const FormatException('bad data');

    final result = await repository().loadMenus();

    expect(result, isA<Error<WeekMenus>>());
  });

  test('shares one download between concurrent calls', () async {
    final repo = repository();

    await Future.wait([repo.loadMenus(), repo.loadMenus()]);

    expect(source.calls, 1);
  });

  test('current holds the last loaded menus', () async {
    final repo = repository();
    expect(repo.current, isNull);

    await repo.loadMenus();

    expect(repo.current?.week, week41);
  });
}
