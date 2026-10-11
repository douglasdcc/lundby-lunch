import 'dart:io';

import 'package:lunch_core/lunch_core.dart';
import 'package:lunch_scraper/lunch_scraper.dart';

const _usage = '''
Usage: dart run bin/scrape.dart --output <file> [--previous <file>] [--config <file>]

  --output    Where to write the new menus.json.
  --previous  The currently published menus.json. Restaurants already
              complete for the week are kept instead of scraped again.
  --config    Restaurant list (default: restaurants.json).''';

Future<void> main(List<String> args) async {
  final options = _parseOptions(args);
  final output = options['output'];
  if (output == null) {
    stderr.writeln(_usage);
    exit(64);
  }

  final restaurants = RestaurantConfig.decodeList(
    await File(options['config'] ?? 'restaurants.json').readAsString(),
  );
  final fetcher = HttpFetcher();
  try {
    final menus = await MenuScraper(
      restaurants: restaurants,
      fetcher: fetcher,
    ).run(previous: await _readPrevious(options['previous']));
    await File(output).writeAsString(menus.encode());
    stdout.writeln('Wrote $output');
  } finally {
    fetcher.close();
  }
}

/// Reads `--name value` pairs.
Map<String, String> _parseOptions(List<String> args) {
  final options = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--') || i + 1 >= args.length) {
      stderr.writeln(_usage);
      exit(64);
    }
    options[args[i].substring(2)] = args[++i];
  }
  return options;
}

/// A missing or unreadable file means there is nothing to keep.
Future<WeekMenus?> _readPrevious(String? path) async {
  if (path == null) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  try {
    return WeekMenus.decode(await file.readAsString());
  } on FormatException catch (error) {
    stdout.writeln('Ignoring previous menus: $error');
    return null;
  }
}
