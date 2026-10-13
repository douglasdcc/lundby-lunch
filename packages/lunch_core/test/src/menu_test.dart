import 'package:lunch_core/lunch_core.dart';
import 'package:test/test.dart';

WeekMenus _sample({MenuStatus secondStatus = MenuStatus.ok}) => WeekMenus(
  week: const IsoWeek(2026, 41),
  generatedAt: DateTime.utc(2026, 10, 5, 6),
  restaurants: [
    RestaurantMenu(
      id: 'barcentro',
      name: 'Bar Centro',
      website: const LocalizedText(
        sv: 'https://sv.example',
        en: 'https://en.example',
      ),
      status: MenuStatus.ok,
      address: 'Prästvägen 12',
      lunchHours: '11:00–13:15',
      fetchedAt: DateTime.utc(2026, 10, 5, 6),
      days: [
        DayMenu(
          date: DateTime.utc(2026, 10, 5),
          dishes: const [
            Dish(
              name: LocalizedText(sv: 'Dagens fisk', en: 'Fish of the day'),
              price: 115,
              tags: ['L'],
            ),
          ],
        ),
      ],
      weekly: const [
        Dish(
          category: LocalizedText(sv: 'Veckans soppa', en: 'Soup of the week'),
          name: LocalizedText(sv: 'Potatissoppa', en: 'Potato soup'),
          price: 100,
        ),
      ],
    ),
    RestaurantMenu(
      id: 'zata',
      name: 'Z:äta',
      website: const LocalizedText(sv: 'https://zata.example'),
      status: secondStatus,
    ),
  ],
);

void main() {
  test('encode and decode round-trip all fields', () {
    final menus = _sample();
    final decoded = WeekMenus.decode(menus.encode());

    expect(decoded.toJson(), menus.toJson());
    expect(decoded.week, const IsoWeek(2026, 41));
    expect(
      decoded.restaurants.first.days.first.date,
      DateTime.utc(2026, 10, 5),
    );
  });

  test('isComplete is false when any restaurant is not ok', () {
    expect(_sample().isComplete, isTrue);
    expect(_sample(secondStatus: MenuStatus.missing).isComplete, isFalse);
  });

  test('isComplete counts a menu only published as an image', () {
    expect(_sample(secondStatus: MenuStatus.imageOnly).isComplete, isTrue);
    expect(MenuStatus.parse('imageOnly'), MenuStatus.imageOnly);
  });

  test('dishesOn matches the calendar day regardless of time', () {
    final restaurant = _sample().restaurants.first;
    expect(restaurant.dishesOn(DateTime(2026, 10, 5, 12, 30)), hasLength(1));
    expect(restaurant.dishesOn(DateTime(2026, 10, 6)), isEmpty);
  });

  test('unknown status is read as error', () {
    expect(MenuStatus.parse('weird'), MenuStatus.error);
  });

  test('decode rejects an unsupported schema version', () {
    expect(
      () => WeekMenus.decode('{"schemaVersion": 99}'),
      throwsA(isA<FormatException>()),
    );
  });

  test('decode rejects malformed data with a FormatException', () {
    expect(
      () => WeekMenus.decode('{"schemaVersion": 1, "isoYear": "x"}'),
      throwsA(isA<FormatException>()),
    );
    expect(() => WeekMenus.decode('[]'), throwsA(isA<FormatException>()));
  });
}
