// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lundby Lunch';

  @override
  String get navToday => 'Today';

  @override
  String get navWeek => 'Week';

  @override
  String get navSettings => 'Settings';

  @override
  String weekNumber(int week) {
    return 'Week $week';
  }

  @override
  String get allWeek => 'All week';

  @override
  String get noMenuForDay => 'No menu for this day.';

  @override
  String get menuMissing => 'This week\'s menu isn\'t published yet.';

  @override
  String get menuError => 'Couldn\'t read this restaurant\'s menu.';

  @override
  String menuImageOnly(String restaurant) {
    return '$restaurant only posts its menu as a picture, so we can\'t show it here. Blame them, not us.';
  }

  @override
  String get openWebsite => 'Open website';

  @override
  String staleWeek(int shown, int target) {
    return 'Showing week $shown. The menus for week $target aren\'t published yet.';
  }

  @override
  String get loadErrorTitle => 'Couldn\'t load the menus';

  @override
  String get loadErrorMessage => 'Check your connection and try again.';

  @override
  String get retry => 'Try again';

  @override
  String get refreshFailed => 'Couldn\'t update. Showing saved menus.';

  @override
  String lastUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String price(int price) {
    return '$price kr';
  }

  @override
  String get allRestaurantsHidden =>
      'All restaurants are hidden. Turn them on in Settings.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsStartScreen => 'Start screen';

  @override
  String get settingsRestaurants => 'Restaurants';

  @override
  String get settingsRestaurantsHint => 'Drag to reorder. Turn off to hide.';

  @override
  String get settingsRestaurantsEmpty =>
      'Restaurants appear here once the menus have loaded.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutText =>
      'Menus are collected once a week from the restaurants\' websites. Dishes and prices can change, so check with the restaurant.';

  @override
  String get sampleDataNotice => 'This build shows sample data.';
}
