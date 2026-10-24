import 'package:lunch_core/lunch_core.dart';

import '../fetcher.dart';
import '../scraped_menu.dart';
import 'bar_centro_parser.dart';
import 'compass_api_parser.dart';
import 'lilla_kathmandu_parser.dart';
import 'mashie_parser.dart';
import 'roots_parser.dart';
import 'spira_parser.dart';

/// Reads one restaurant's menu from its website.
abstract interface class MenuParser {
  /// Throws a [FormatException] when [source] is not a valid configuration.
  factory MenuParser.fromSource(JsonMap source) {
    String url(String key) => switch (source[key]) {
      final String value when value.startsWith('https://') => value,
      _ => throw FormatException('Source needs an https "$key" URL: $source'),
    };

    return switch (source['type']) {
      'roots' => RootsParser(
        sv: Uri.parse(url('sv')),
        en: Uri.parse(url('en')),
      ),
      'spira' => SpiraParser(Uri.parse(url('url'))),
      'barcentro' => BarCentroParser(
        sv: Uri.parse(url('sv')),
        en: Uri.parse(url('en')),
      ),
      'mashie' => MashieParser(Uri.parse(url('url'))),
      'lillakathmandu' => LillaKathmanduParser(Uri.parse(url('url'))),
      'compass' => switch (source['costCenter']) {
        final String costCenter => CompassApiParser(costCenter),
        _ => throw FormatException(
          'Compass source needs a "costCenter": $source',
        ),
      },
      _ => throw FormatException('Unknown source type: $source'),
    };
  }

  /// Downloads and reads the menu, preferring [week] when the site shows
  /// more than one week.
  Future<ScrapedMenu> scrape(Fetcher fetcher, IsoWeek week);
}
