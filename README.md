# Lundby Lunch

Weekly lunch menus for the restaurants around Lundby, in Swedish and English.
Runs on Android, iOS and the web (GitHub Pages).

## Layout

| Path | What |
|---|---|
| `app/` | Flutter app |
| `packages/lunch_core/` | Shared models for `menus.json` (pure Dart) |

This is a Dart pub workspace: run `flutter pub get` once from the root.

## Run the app

```sh
cd app
flutter run                              # bundled sample data (default)
flutter run --dart-define=SAMPLE_DATA=false   # download menus.json
```

`--dart-define=MENUS_URL=https://...` overrides where `menus.json` is
downloaded from. The web build reads `data/menus.json` next to `index.html`.

## Checks

```sh
cd app && flutter analyze && flutter test
cd packages/lunch_core && dart analyze && dart test
```
