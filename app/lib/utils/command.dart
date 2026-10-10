import 'package:flutter/foundation.dart';

import 'package:lundby_lunch/utils/result.dart';

/// Runs an async action and exposes whether it is running and how it ended.
///
/// A second call while the action is running is ignored.
class Command0<T> extends ChangeNotifier {
  Command0(this._action);

  final Future<Result<T>> Function() _action;

  bool _running = false;
  Result<T>? _result;

  bool get running => _running;

  bool get error => _result is Error<T>;

  bool get completed => _result is Ok<T>;

  Result<T>? get result => _result;

  void clearResult() {
    _result = null;
    notifyListeners();
  }

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();
    try {
      _result = await _action();
    } finally {
      _running = false;
      notifyListeners();
    }
  }
}
