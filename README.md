# Lundby Lunch

Weekly lunch menus for the restaurants around Lundby, in Swedish and English.
Runs on Android, iOS and the web: <https://douglasdcc.github.io/lundby-lunch/>

> **Disclaimer:** This is a hobby project for learning web scraping and
> Flutter development. It is not affiliated with any of the restaurants.
> Menus are read automatically from their websites and may be missing,
> wrong or out of date, so check the restaurant's own website if it matters.

## Restaurants

| Restaurant | Address | Lunch | Menu read from |
| --- | --- | --- | --- |
| [Roots](https://www.rootsfoodmarket.se/) | Gropegårdsgatan 2 | 11:00–13:30 | Website (sv and en) |
| [Z:äta](https://www.compass-group.se/restauranger-och-menyer/ovriga-restauranger/zata/) | Gropegårdsgatan 11 | 11:00–13:30 | Mashie menu page |
| [Spira](https://spirafood.se/volvo-lunchmeny) | Gropegårdsgatan 10 | 11:00–13:00 | Website |
| [Bar Centro](https://barcentropavolvo.se/) | Prästvägen 12 | 11:00–13:15 | Website (sv and en) |
| [Nordic Taste Lab](https://www.compass-group.se/restauranger-och-menyer/ovriga-restauranger/restaurang-nordic-taste-lab/) | Prästvägen 15 | 11:00–13:30 | Not read: the menu is an image on the website |
| [Lilla Kathmandu](https://www.lillakathmandu.se/sv/lunch) | Byalagsgatan 13 | 11:00–20:00 | Website |
| [Divan](https://www.restaurangdivan.se/) | Nordanvindsgatan 2 | 11:00–15:00 | PDF menu |
| [Masala Zone](https://www.masalazone.se/indisk-restaurang-masala-zone-hisingen/) | Gropegårdsgatan 3 | 10:45–14:00 | Website |

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
on Sunday evening, several times on Monday morning, every weekday morning,
and again every weekday afternoon and evening to catch same-day updates:

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
types: `roots`, `spira`, `barcentro`, `lillakathmandu`, `masalazone`, `mashie`
(Mashie / Matilda Platform menu pages), `compass` (Compass Group menu API, by
cost center) and `divan` (a PDF menu; needs `pdftotext` from poppler-utils on
the PATH).

## Checks

```sh
cd app && flutter analyze && flutter test
cd scraper && dart analyze && dart test
cd packages/lunch_core && dart analyze && dart test
```

The **Checks** workflow runs these on every pull request.
