import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/data/services/key_value_store.dart';
import 'package:lundby_lunch/data/services/menu_source.dart';
import 'package:lundby_lunch/utils/result.dart';

/// Source of truth for the week's menus.
///
/// The menus are downloaded at most until a complete copy for the target week
/// is saved; after that the saved copy is used for the rest of the week.
class MenuRepository {
  MenuRepository({
    required this._source,
    required this._store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const cacheKey = 'menus.cache';

  final MenuSource _source;
  final KeyValueStore _store;
  final DateTime Function() _now;

  WeekMenus? _current;
  Future<Result<WeekMenus>>? _inFlight;

  /// The menus returned by the last successful [loadMenus], if any.
  WeekMenus? get current => _current;

  /// Returns the saved menus when they are complete for the target week, and
  /// downloads them otherwise.
  ///
  /// When the download fails, the saved menus are returned instead, unless
  /// [forceRefresh] is set.
  Future<Result<WeekMenus>> loadMenus({bool forceRefresh = false}) {
    return _inFlight ??= _load(forceRefresh)
        .whenComplete(() => _inFlight = null);
  }

  Future<Result<WeekMenus>> _load(bool forceRefresh) async {
    final target = IsoWeek.targetFor(_now());
    final cached = _current ?? _readCache();

    if (!forceRefresh &&
        cached != null &&
        cached.week == target &&
        cached.isComplete) {
      return Result.ok(_current = cached);
    }

    try {
      final fetched = WeekMenus.decode(await _source.fetchMenus(target));
      // Never replace newer saved menus with an older week.
      if (cached != null && cached.week > fetched.week) {
        return Result.ok(_current = cached);
      }
      await _store.setString(cacheKey, fetched.encode());
      return Result.ok(_current = fetched);
    } on Exception catch (error) {
      if (cached != null && !forceRefresh) return Result.ok(_current = cached);
      return Result.error(error);
    }
  }

  WeekMenus? _readCache() {
    final raw = _store.getString(cacheKey);
    if (raw == null) return null;
    try {
      return WeekMenus.decode(raw);
    } on FormatException {
      return null;
    }
  }
}
