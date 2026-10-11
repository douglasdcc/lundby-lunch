import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/domain/models/settings.dart';

import '../../../testing/app_harness.dart';

void main() {
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('changes language, theme and start screen', (tester) async {
    final settings = await pumpApp(tester);
    await openSettings(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.theme, ThemePreference.dark);

    await tester.tap(find.widgetWithText(SegmentedButton<MenuView>, 'Week'));
    await tester.pumpAndSettle();
    expect(settings.startView, MenuView.week);

    await tester.tap(find.text('Svenska'));
    await tester.pumpAndSettle();
    expect(settings.language, Language.sv);
    expect(find.text('Inställningar'), findsWidgets);
  });

  testWidgets('hiding a restaurant removes it from the Today screen', (
    tester,
  ) async {
    final settings = await pumpApp(tester);
    await openSettings(tester);

    await tester.scrollUntilVisible(
      find.byType(Switch).first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(settings.hiddenRestaurants, {'a'});

    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Today')),
    );
    await tester.pumpAndSettle();
    expect(find.text('a 3 en'), findsNothing);
    expect(find.text('b 3 en'), findsOneWidget);
  });
}
