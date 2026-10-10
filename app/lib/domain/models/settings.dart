enum ThemePreference { system, light, dark }

/// The screen shown when the app starts.
enum MenuView { today, week }

/// Returns the value of [values] named [name], or [fallback].
T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
