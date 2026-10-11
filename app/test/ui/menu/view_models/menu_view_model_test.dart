import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/data/services/menu_source.dart';
import 'package:lundby_lunch/ui/menu/view_models/menu_view_model.dart';

import '../../../testing/fakes.dart';

void main() {
  late FakeMenuSource source;
  late FakeKeyValueStore store;
  late SettingsRepository settings;

  setUp(() {
    source = FakeMenuSource(buildMenus());
    store = FakeKeyValueStore();
    settings = SettingsRepository(store: store);
  });

  Future<MenuViewModel> loadedViewModel({DateTime? now}) async {
    final clock = now ?? wednesday;
    final viewModel = MenuViewModel(
      menuRepository: MenuRepository(
        source: source,
        store: store,
        now: () => clock,
      ),
      settingsRepository: settings,
      now: () => clock,
    );
    addTearDown(viewModel.dispose);
    // Let the load command started by the constructor finish.
    while (viewModel.load.running) {
      await Future<void>.delayed(Duration.zero);
    }
    return viewModel;
  }

  test('loads the menus and selects today', () async {
    final viewModel = await loadedViewModel();

    expect(viewModel.load.completed, isTrue);
    expect(viewModel.menus?.week, week41);
    expect(viewModel.selectedDate, DateTime.utc(2026, 10, 7));
    expect(viewModel.weekdays, hasLength(5));
    expect(viewModel.isStale, isFalse);
  });

  test('selects Monday when the menus are for next week', () async {
    source.menus = buildMenus(week: const IsoWeek(2026, 42));

    final viewModel = await loadedViewModel(now: DateTime(2026, 10, 10));

    expect(viewModel.selectedDate, DateTime.utc(2026, 10, 12));
    expect(viewModel.isStale, isFalse);
  });

  test(
    'selects Friday and is stale when only last week is available',
    () async {
      final viewModel = await loadedViewModel(now: DateTime(2026, 10, 10));

      expect(viewModel.selectedDate, DateTime.utc(2026, 10, 9));
      expect(viewModel.isStale, isTrue);
      expect(viewModel.targetWeek, const IsoWeek(2026, 42));
    },
  );

  test('reports a load error when nothing can be loaded', () async {
    source.error = const MenuSourceException('offline');

    final viewModel = await loadedViewModel();

    expect(viewModel.load.error, isTrue);
    expect(viewModel.menus, isNull);
  });

  test('a failed refresh keeps the loaded menus', () async {
    final viewModel = await loadedViewModel();
    source.error = const MenuSourceException('offline');

    await viewModel.refresh.execute();

    expect(viewModel.refresh.error, isTrue);
    expect(viewModel.menus?.week, week41);
  });

  test('selectDate keeps the selection on refresh of the same week', () async {
    final viewModel = await loadedViewModel();
    viewModel.selectDate(DateTime(2026, 10, 5, 9));

    await viewModel.refresh.execute();

    expect(viewModel.selectedDate, DateTime.utc(2026, 10, 5));
  });

  test('restaurants follow the order and hidden settings', () async {
    source.menus = buildMenus(
      restaurants: [
        buildRestaurant('a'),
        buildRestaurant('b'),
        buildRestaurant('c'),
      ],
    );
    final viewModel = await loadedViewModel();
    var notified = 0;
    viewModel.addListener(() => notified++);

    await settings.setRestaurantOrder(['c', 'b', 'a']);
    await settings.setRestaurantHidden('b', hidden: true);

    expect([for (final r in viewModel.restaurants) r.id], ['c', 'a']);
    expect(notified, 2);
  });

  test('selectedRestaurant defaults to the first visible one', () async {
    final viewModel = await loadedViewModel();
    expect(viewModel.selectedRestaurant?.id, 'a');

    viewModel.selectRestaurant('b');
    expect(viewModel.selectedRestaurant?.id, 'b');

    await settings.setRestaurantHidden('b', hidden: true);
    expect(viewModel.selectedRestaurant?.id, 'a');
  });
}
