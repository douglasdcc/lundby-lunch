import 'package:flutter_test/flutter_test.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/ui/settings/view_models/settings_view_model.dart';

import '../../../testing/fakes.dart';

void main() {
  late SettingsRepository settings;
  late SettingsViewModel viewModel;

  setUp(() async {
    final store = FakeKeyValueStore();
    final menus = MenuRepository(
      source: FakeMenuSource(
        buildMenus(
          restaurants: [
            buildRestaurant('a'),
            buildRestaurant('b'),
            buildRestaurant('c'),
          ],
        ),
      ),
      store: store,
      now: () => wednesday,
    );
    await menus.loadMenus();
    settings = SettingsRepository(store: store);
    viewModel = SettingsViewModel(
      settingsRepository: settings,
      menuRepository: menus,
    );
    addTearDown(viewModel.dispose);
  });

  List<String> ids() => [for (final r in viewModel.restaurants) r.id];

  test('lists hidden restaurants too', () async {
    await viewModel.setVisible('b', visible: false);

    expect(ids(), ['a', 'b', 'c']);
    expect(viewModel.isHidden('b'), isTrue);
  });

  test('moveRestaurant moves down and up', () async {
    await viewModel.moveRestaurant(0, 2);
    expect(ids(), ['b', 'c', 'a']);

    await viewModel.moveRestaurant(2, 0);
    expect(ids(), ['a', 'b', 'c']);
    expect(settings.restaurantOrder, ['a', 'b', 'c']);
  });
}
