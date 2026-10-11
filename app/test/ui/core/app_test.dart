import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/domain/models/settings.dart';
import 'package:lundby_lunch/ui/onboarding/widgets/language_picker_screen.dart';

import '../../testing/app_harness.dart';
import '../../testing/fakes.dart';

void main() {
  testWidgets('first launch asks for a language, then shows the menus', (
    tester,
  ) async {
    final settings = await pumpApp(tester, language: null);

    expect(find.byType(LanguagePickerScreen), findsOneWidget);

    await tester.tap(find.text('Svenska'));
    await tester.pumpAndSettle();

    expect(settings.language, Language.sv);
    expect(find.byType(LanguagePickerScreen), findsNothing);
    expect(find.text('Idag'), findsOneWidget);
    expect(find.text('a 3 sv'), findsOneWidget);
  });

  testWidgets('applies the theme preference', (tester) async {
    final settings = await pumpApp(tester);

    await settings.setTheme(ThemePreference.dark);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('opens on the Week screen when that is the start view', (
    tester,
  ) async {
    final store = FakeKeyValueStore()
      ..values['settings.startView'] = MenuView.week.name;

    await pumpApp(tester, store: store);

    expect(find.text('Week 41'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
