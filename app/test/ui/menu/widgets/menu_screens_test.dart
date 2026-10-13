import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunch_core/lunch_core.dart';

import '../../../testing/app_harness.dart';
import '../../../testing/fakes.dart';

void main() {
  group('Today screen', () {
    testWidgets('shows every restaurant for today', (tester) async {
      await pumpApp(tester);

      expect(find.text('Wednesday, October 7'), findsOneWidget);
      expect(find.text('a 3 en'), findsOneWidget);
      expect(find.text('b 3 en'), findsOneWidget);
      expect(find.text('103 kr'), findsNWidgets(2));
    });

    testWidgets('switches day with the day selector', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Mon'));
      await tester.pumpAndSettle();

      expect(find.text('a 1 en'), findsOneWidget);
      expect(find.text('a 3 en'), findsNothing);
    });

    testWidgets('shows weekly dishes and unavailable menus', (tester) async {
      await pumpApp(
        tester,
        menus: buildMenus(
          restaurants: [
            buildRestaurant('a', withWeekly: true),
            buildRestaurant('b', status: MenuStatus.missing),
            buildRestaurant('c', status: MenuStatus.error),
          ],
        ),
      );

      expect(find.text('ALL WEEK'), findsOneWidget);
      expect(find.text('Soup'), findsOneWidget);
      expect(
        find.text("This week's menu isn't published yet."),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text("Couldn't read this restaurant's menu."),
        200,
      );
      expect(find.text('Open website'), findsWidgets);
    });

    testWidgets('blames restaurants that only post an image', (tester) async {
      await pumpApp(
        tester,
        menus: buildMenus(
          restaurants: [
            buildRestaurant(
              'd',
              status: MenuStatus.imageOnly,
              name: 'Nordic Taste Lab',
            ),
          ],
        ),
      );

      expect(
        find.text(
          'Nordic Taste Lab only posts its menu as a picture, so we can\'t '
          'show it here. Blame them, not us.',
        ),
        findsOneWidget,
      );
      expect(find.text('Open website'), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads the menus', (tester) async {
      await pumpApp(tester);

      await tester.fling(find.text('a 3 en'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('a 3 en'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Week screen', () {
    testWidgets('shows the selected restaurant only', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('Week 41'), findsOneWidget);
      expect(find.text('a 3 en'), findsOneWidget);
      expect(find.text('b 3 en'), findsNothing);

      await tester.tap(find.text('Restaurant b'));
      await tester.pumpAndSettle();

      expect(find.text('b 3 en'), findsOneWidget);
      expect(find.text('a 3 en'), findsNothing);
    });

    testWidgets('keeps the day selected on the Today screen', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();

      expect(find.text('a 5 en'), findsOneWidget);
    });
  });
}
