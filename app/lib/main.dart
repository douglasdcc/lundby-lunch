import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lundby_lunch/config/app_config.dart';
import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/data/services/key_value_store.dart';
import 'package:lundby_lunch/data/services/menu_source.dart';
import 'package:lundby_lunch/data/services/sample_menu_source.dart';
import 'package:lundby_lunch/ui/core/app.dart';
import 'package:lundby_lunch/utils/clock.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final store = SharedPreferencesStore(preferences);
  final MenuSource source = AppConfig.useSampleData
      ? SampleMenuSource()
      : HttpMenuSource(url: AppConfig.menusUrl);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => const Clock()),
        ChangeNotifierProvider(create: (_) => SettingsRepository(store: store)),
        Provider(
          create: (context) => MenuRepository(
            source: source,
            store: store,
            now: context.read<Clock>().now,
          ),
        ),
      ],
      child: const LundbyLunchApp(),
    ),
  );
}
