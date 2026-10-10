import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/l10n/app_localizations.dart';
import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/core/themes/app_theme.dart';
import 'package:lundby_lunch/ui/home/widgets/home_screen.dart';
import 'package:lundby_lunch/ui/onboarding/widgets/language_picker_screen.dart';

class LundbyLunchApp extends StatelessWidget {
  const LundbyLunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsRepository>();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final language = settings.language;
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: AppTheme.modeFor(settings.theme),
          locale: language?.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: language == null
              ? LanguagePickerScreen(onSelected: settings.setLanguage)
              : const HomeScreen(),
        );
      },
    );
  }
}
