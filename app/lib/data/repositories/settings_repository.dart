import 'package:flutter/foundation.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/services/key_value_store.dart';
import 'package:lundby_lunch/domain/models/settings.dart';

/// The user's settings. Notifies listeners whenever one changes.
class SettingsRepository extends ChangeNotifier {
  SettingsRepository({required this._store}) {
    _language = Language.tryParse(_store.getString(_languageKey));
    _theme = enumByName(
      ThemePreference.values,
      _store.getString(_themeKey),
      ThemePreference.system,
    );
    _startView = enumByName(
      MenuView.values,
      _store.getString(_startViewKey),
      MenuView.today,
    );
    _restaurantOrder = _store.getStringList(_orderKey) ?? const [];
    _hiddenRestaurants = {...?_store.getStringList(_hiddenKey)};
  }

  static const _languageKey = 'settings.language';
  static const _themeKey = 'settings.theme';
  static const _startViewKey = 'settings.startView';
  static const _orderKey = 'settings.restaurantOrder';
  static const _hiddenKey = 'settings.hiddenRestaurants';

  final KeyValueStore _store;

  late Language? _language;
  late ThemePreference _theme;
  late MenuView _startView;
  late List<String> _restaurantOrder;
  late Set<String> _hiddenRestaurants;

  /// Null until the user has picked a language on first launch.
  Language? get language => _language;

  ThemePreference get theme => _theme;

  MenuView get startView => _startView;

  /// Restaurant ids in the user's preferred order. Restaurants missing from
  /// the list come after these, in their original order.
  List<String> get restaurantOrder => List.unmodifiable(_restaurantOrder);

  Set<String> get hiddenRestaurants => Set.unmodifiable(_hiddenRestaurants);

  Future<void> setLanguage(Language language) async {
    _language = language;
    notifyListeners();
    await _store.setString(_languageKey, language.name);
  }

  Future<void> setTheme(ThemePreference theme) async {
    _theme = theme;
    notifyListeners();
    await _store.setString(_themeKey, theme.name);
  }

  Future<void> setStartView(MenuView view) async {
    _startView = view;
    notifyListeners();
    await _store.setString(_startViewKey, view.name);
  }

  Future<void> setRestaurantOrder(List<String> ids) async {
    _restaurantOrder = List.of(ids);
    notifyListeners();
    await _store.setStringList(_orderKey, _restaurantOrder);
  }

  Future<void> setRestaurantHidden(String id, {required bool hidden}) async {
    if (hidden) {
      _hiddenRestaurants.add(id);
    } else {
      _hiddenRestaurants.remove(id);
    }
    notifyListeners();
    await _store.setStringList(_hiddenKey, _hiddenRestaurants.toList());
  }

  /// Sorts [restaurants] by the user's order, optionally dropping hidden ones.
  List<RestaurantMenu> arrange(
    List<RestaurantMenu> restaurants, {
    bool includeHidden = false,
  }) {
    final rank = {
      for (final (index, id) in _restaurantOrder.indexed) id: index,
    };
    final indexed = restaurants.indexed
        .where(
          (entry) => includeHidden || !_hiddenRestaurants.contains(entry.$2.id),
        )
        .toList();
    indexed.sort((a, b) {
      final rankA = rank[a.$2.id] ?? rank.length + a.$1;
      final rankB = rank[b.$2.id] ?? rank.length + b.$1;
      return rankA.compareTo(rankB);
    });
    return [for (final (_, restaurant) in indexed) restaurant];
  }
}
