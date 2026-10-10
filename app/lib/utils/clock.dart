/// Source of the current time, replaceable in tests.
class Clock {
  const Clock([this._now = DateTime.now]);

  final DateTime Function() _now;

  DateTime now() => _now();
}
