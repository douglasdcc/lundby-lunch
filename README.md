# Lundby Lunch

Weekly lunch menus for the restaurants around Lundby, in Swedish and English.
Runs on Android, iOS and the web: <https://douglasdcc.github.io/lundby-lunch/>

## Layout

| Path | What |
| --- | --- |
| `app/` | Flutter app |
| `scraper/` | Dart CLI that reads the restaurants' websites and writes `menus.json` |
| `scraper/restaurants.json` | The restaurants: names, links, addresses and where to read each menu |
| `packages/lunch_core/` | Shared models for `menus.json` (pure Dart) |

This is a Dart pub workspace: run `flutter pub get` once from the root.

## How the menus get to the app

The **Scrape menus and deploy** workflow (`.github/workflows/deploy.yml`) runs
on Sunday evening, several times on Monday morning, and once a day Tuesday to
Friday:

1. Downloads the `menus.json` currently published on GitHub Pages.
2. Runs the scraper for the coming week. Restaurants that already have that
   week's menu are kept, not scraped again.
3. If anything changed, builds the web app and publishes it to GitHub Pages
   together with `data/menus.json`.

Pushes to `main` always rebuild and publish. The app downloads `menus.json`
once and keeps it until the week is complete.

## Run the app

```sh
cd app
flutter run                                  # menus from GitHub Pages
flutter run --dart-define=SAMPLE_DATA=true   # bundled sample menus
```

`--dart-define=MENUS_URL=https://...` overrides where `menus.json` is
downloaded from. The web build reads `data/menus.json` next to `index.html`.

## Run the scraper

```sh
cd scraper
dart run bin/scrape.dart --output menus.json [--previous old-menus.json]
```

To add a restaurant, add an entry to `restaurants.json`. Supported `source`
types: `roots`, `spira`, `barcentro`, `mashie` (Mashie / Matilda Platform menu
pages) and `compass` (Compass Group menu API, by cost center).

## Checks

```sh
cd app && flutter analyze && flutter test
cd scraper && dart analyze && dart test
cd packages/lunch_core && dart analyze && dart test
```

The **Checks** workflow runs these on every pull request.
