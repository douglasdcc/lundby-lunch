import 'package:flutter/foundation.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/domain/models/settings.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this._settingsRepository,
    required this._menuRepository,
  }) {
    _settingsRepository.addListener(notifyListeners);
  }

  final SettingsRepository _settingsRepository;
  final MenuRepository _menuRepository;

  Language? get language => _settingsRepository.language;

  ThemePreference get theme => _settingsRepository.theme;

  MenuView get startView => _settingsRepository.startView;

  /// All known restaurants, hidden ones included, in the user's order.
  List<RestaurantMenu> get restaurants => _settingsRepository.arrange(
    _menuRepository.current?.restaurants ?? const [],
    includeHidden: true,
  );

  bool isHidden(String restaurantId) =>
      _settingsRepository.hiddenRestaurants.contains(restaurantId);

  Future<void> setLanguage(Language language) =>
      _settingsRepository.setLanguage(language);

  Future<void> setTheme(ThemePreference theme) =>
      _settingsRepository.setTheme(theme);

  Future<void> setStartView(MenuView view) =>
      _settingsRepository.setStartView(view);

  Future<void> setVisible(String restaurantId, {required bool visible}) =>
      _settingsRepository.setRestaurantHidden(restaurantId, hidden: !visible);

  /// Moves the restaurant at [oldIndex] so that it ends up at [newIndex].
  Future<void> moveRestaurant(int oldIndex, int newIndex) {
    final ids = [for (final restaurant in restaurants) restaurant.id];
    ids.insert(newIndex, ids.removeAt(oldIndex));
    return _settingsRepository.setRestaurantOrder(ids);
  }

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    super.dispose();
  }
}
