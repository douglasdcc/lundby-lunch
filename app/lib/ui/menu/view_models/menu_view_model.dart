import 'package:flutter/foundation.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/utils/command.dart';
import 'package:lundby_lunch/utils/result.dart';

/// State shared by the Today and Week screens: the loaded menus, the selected
/// day and the selected restaurant.
class MenuViewModel extends ChangeNotifier {
  MenuViewModel({
    required this._menuRepository,
    required this._settingsRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    load = Command0(_load)..execute();
    refresh = Command0(_refresh);
    _settingsRepository.addListener(notifyListeners);
  }

  final MenuRepository _menuRepository;
  final SettingsRepository _settingsRepository;
  final DateTime Function() _now;

  late final Command0<void> load;
  late final Command0<void> refresh;

  WeekMenus? _menus;
  DateTime? _selectedDate;
  String? _selectedRestaurantId;

  WeekMenus? get menus => _menus;

  /// Visible restaurants in the user's order.
  List<RestaurantMenu> get restaurants =>
      _settingsRepository.arrange(_menus?.restaurants ?? const []);

  /// Monday to Friday of the loaded week.
  List<DateTime> get weekdays => _menus?.week.weekdays ?? const [];

  DateTime? get selectedDate => _selectedDate;

  DateTime get today => dateOnly(_now());

  /// The week the user should be seeing: the next one on weekends.
  IsoWeek get targetWeek => IsoWeek.targetFor(_now());

  /// Whether the loaded menus are older than [targetWeek].
  bool get isStale {
    final menus = _menus;
    return menus != null && menus.week < targetWeek;
  }

  RestaurantMenu? get selectedRestaurant {
    final visible = restaurants;
    for (final restaurant in visible) {
      if (restaurant.id == _selectedRestaurantId) return restaurant;
    }
    return visible.firstOrNull;
  }

  void selectDate(DateTime date) {
    _selectedDate = dateOnly(date);
    notifyListeners();
  }

  void selectRestaurant(String id) {
    _selectedRestaurantId = id;
    notifyListeners();
  }

  Future<Result<void>> _load() => _apply(_menuRepository.loadMenus());

  Future<Result<void>> _refresh() =>
      _apply(_menuRepository.loadMenus(forceRefresh: true));

  Future<Result<void>> _apply(Future<Result<WeekMenus>> request) async {
    final result = await request;
    switch (result) {
      case Ok<WeekMenus>(:final value):
        final weekChanged = _menus?.week != value.week;
        _menus = value;
        if (weekChanged || _selectedDate == null) {
          _selectedDate = _defaultDate(value.week);
        }
        notifyListeners();
        return const Result.ok(null);
      case Error<WeekMenus>(:final error):
        return Result.error(error);
    }
  }

  /// Today when it is in [week]; otherwise the closest weekday of [week].
  DateTime _defaultDate(IsoWeek week) {
    final days = week.weekdays;
    final today = this.today;
    if (days.contains(today)) return today;
    return today.isBefore(days.first) ? days.first : days.last;
  }

  @override
  void dispose() {
    _settingsRepository.removeListener(notifyListeners);
    load.dispose();
    refresh.dispose();
    super.dispose();
  }
}
