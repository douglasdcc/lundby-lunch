import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';
import 'package:provider/provider.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/ui/core/app.dart';
import 'package:lundby_lunch/utils/clock.dart';

import 'fakes.dart';

/// Pumps the whole app with fake services.
Future<SettingsRepository> pumpApp(
  WidgetTester tester, {
  WeekMenus? menus,
  Language? language = Language.en,
  FakeKeyValueStore? store,
}) async {
  final keyValueStore = store ?? FakeKeyValueStore();
  final settings = SettingsRepository(store: keyValueStore);
  if (language != null) await settings.setLanguage(language);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider.value(value: Clock(() => wednesday)),
        ChangeNotifierProvider.value(value: settings),
        Provider(
          create: (_) => MenuRepository(
            source: FakeMenuSource(menus ?? buildMenus()),
            store: keyValueStore,
            now: () => wednesday,
          ),
        ),
      ],
      child: const LundbyLunchApp(),
    ),
  );
  await tester.pumpAndSettle();
  return settings;
}
