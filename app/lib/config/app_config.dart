import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define`.
abstract final class AppConfig {
  /// Shows the bundled sample menus instead of downloading `menus.json`.
  static const useSampleData = bool.fromEnvironment(
    'SAMPLE_DATA',
    defaultValue: true,
  );

  static const _menusUrl = String.fromEnvironment('MENUS_URL');

  static const _defaultMenusUrl =
      'https://douglasdcc.github.io/lundby-lunch/data/menus.json';

  /// Where `menus.json` is downloaded from. The web build is served from the
  /// same GitHub Pages site, so it uses a relative URL.
  static Uri get menusUrl {
    if (_menusUrl.isNotEmpty) return Uri.parse(_menusUrl);
    if (kIsWeb) return Uri.base.resolve('data/menus.json');
    return Uri.parse(_defaultMenusUrl);
  }
}
