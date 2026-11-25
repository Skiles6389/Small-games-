# Small Games

A family of small, calm mobile puzzle games built with [Flutter](https://flutter.dev).
**Sudoku** is the first one. Minesweeper, nonograms, 2048, word puzzles and
solitaire can follow, reusing the same shared building blocks.

Everything runs offline. There are no accounts, no paid services, no secrets
and no real ads yet. Ads and purchases are replaced by fake versions behind
clean interfaces, so the real ones can be plugged in later.

---

## Playtest link (no install needed)

**<https://skiles6389.github.io/Small-games-/>** (works in any modern phone or desktop browser)

Open it in your phone's browser. To make it feel like an app, use *Share →
Add to Home Screen* (iPhone, Safari) or *⋮ → Add to Home screen* (Android,
Chrome). Your games, stats and streak are saved in that browser.

Every push to `main` rebuilds and republishes it automatically. The workflow
is `.github/workflows/deploy-pages.yml`, and you can also run it by hand from
the repo's *Actions* tab → *Deploy playtest to GitHub Pages* → *Run workflow*.
After a deploy, a page that is already open may need a refresh to show the
new version.

**One-time setup (repo owner):** on GitHub, go to *Settings → Pages →
Build and deployment → Source* and choose **GitHub Actions**. Then re-run
the workflow once from the *Actions* tab. Until this is switched on, the
deploy step fails with a "Pages not enabled"-style error.

---

## Folder layout

```
Small-games-/
├── pubspec.yaml              ← lists every package in the repo (a "pub workspace")
├── packages/
│   └── game_core/            ← shared code every game can use
│       ├── lib/src/theme/          calm dark-mode colors and styles
│       ├── lib/src/settings/       on/off settings, saved automatically
│       ├── lib/src/storage/        saving data + auto-save slots
│       ├── lib/src/stats/          games played / won, best times
│       ├── lib/src/daily/          daily puzzle seeds + streak counter
│       ├── lib/src/monetization/   ad + purchase interfaces (with fakes)
│       ├── lib/src/random/         random numbers that match on every device
│       ├── lib/src/services/       bundles all of the above for an app
│       └── test/
└── apps/
    └── sudoku/               ← the Sudoku app
        ├── lib/
        │   ├── main.dart           app start-up
        │   ├── app.dart            theme + first screen
        │   ├── engine/             puzzle generator, solver, difficulty grading
        │   ├── game/               game rules, undo, notes, timer, saving
        │   ├── screens/            home, game, win, stats, settings
        │   └── widgets/            board, number pad, action buttons
        ├── test/                   unit + widget tests
        ├── web/  android/  ios/    platform folders made by Flutter
```

Rule of thumb: if a future game could use it, it goes in `game_core`.
If only Sudoku needs it, it stays in `apps/sudoku`.

---

## One-time setup

1. Install Flutter by following the
   [official guide](https://docs.flutter.dev/get-started/install) for your
   computer. This project was built with **Flutter 3.50 (Dart 3.14)**. Check
   your version with `flutter --version`.
2. Install Google Chrome. You'll use it to playtest in a browser.
3. From the top folder of this repo, download the dependencies for every
   package at once:

   ```bash
   flutter pub get
   ```

---

## Play it in a browser

The quickest way to try changes:

```bash
cd apps/sudoku
flutter run -d chrome
```

A Chrome window opens with the game. While it runs, press `r` in the terminal
to reload your code changes instantly, or `q` to quit.

Tip: in Chrome, open DevTools (F12), click the phone icon, and pick a phone
size to see the game in portrait, the way it looks on a phone.

**Keyboard shortcuts (browser):** `1`–`9` enter a number, arrow keys move,
`Backspace` erases, `N` toggles notes, `Z` undoes.

### Make a web build you can share

```bash
cd apps/sudoku
flutter build web
cd build/web
python3 -m http.server 8080
```

Then open <http://localhost:8080>. You can upload the `build/web` folder to
any free static host (GitHub Pages, Netlify, Cloudflare Pages, and so on).

---

## Play it on a phone

### Android (works from Windows, macOS or Linux)

1. Install [Android Studio](https://developer.android.com/studio). It brings
   the Android SDK. Run `flutter doctor` and follow any instructions it prints.
2. On the phone, turn on **Developer options**: go to *Settings → About
   phone* and tap *Build number* 7 times. Then turn on **USB debugging** in
   *Developer options*.
3. Plug the phone in with USB and accept the "Allow USB debugging?" prompt.
4. Run:

   ```bash
   cd apps/sudoku
   flutter devices      # your phone should be listed
   flutter run          # installs and starts the game on the phone
   ```

To build an installable file instead, run `flutter build apk`. The file ends
up in `build/app/outputs/flutter-apk/app-release.apk`.

### iPhone (needs a Mac)

1. Install Xcode from the Mac App Store and run `flutter doctor`.
2. Open `apps/sudoku/ios/Runner.xcworkspace` in Xcode. Select *Runner* →
   *Signing & Capabilities*, then choose your (free) Apple ID as the *Team*.
3. Plug in the iPhone, trust the computer, then run `flutter run` from
   `apps/sudoku`. The first time, you may need to trust the developer on the
   phone under *Settings → General → VPN & Device Management*.

---

## Check that everything still works

Run these before committing:

```bash
# Shared package
cd packages/game_core
flutter analyze
flutter test

# Sudoku app
cd ../../apps/sudoku
flutter analyze
flutter test
```

The tests check that every generated puzzle has **exactly one solution**,
follows the rules, and matches its difficulty. They also check that the daily
puzzle is the same for everyone, and cover gameplay (notes, undo, hints,
winning), saving and resuming, stats, streaks and settings.

To confirm the web version generates the same daily puzzle as phones, run the
engine tests inside Chrome:
`flutter test --platform chrome test/engine_test.dart`.

---

## What's in version 1

- **Puzzle generator and solver.** Every puzzle has exactly one solution.
  There are 4 levels: Easy (about 40 starting numbers), Medium (about 32),
  Hard (about 27) and Expert (about 23–26). Easy and Medium can always be
  solved with the two basic techniques. Expert puzzles are picked to need
  more than that.
- **Gameplay.** Tap a cell and use the number pad. You also get pencil notes,
  undo, erase, highlighting of the same number and of the row/column/box,
  an optional "show mistakes" setting, a timer, pause, and a win screen.
- **Hints.** A hint reveals one cell, after watching a (fake) rewarded ad.
- **Daily puzzle.** It's the same for everyone on the same date, and it comes
  with a streak counter.
- **Stats.** You get games played and won, plus best and average times for
  each difficulty and for daily puzzles.
- **Auto-save.** Your game is saved after every move and when you leave the
  app, so you can resume with "Continue".

## What's stubbed (fake for now)

| Piece | Interface | Fake used today |
| --- | --- | --- |
| Rewarded ads (for hints) | `AdService.showRewarded` | A small "Ad placeholder" dialog that counts down for 2 seconds |
| Interstitial ads | `AdService.showInterstitial` | Does nothing. It only logs, after every 3rd finished game |
| Banner ads | `AdService.buildBanner` | A quiet "Banner ad placeholder" strip under the game |
| "Remove Ads" purchase | `PurchaseService` | "Buying" is free and instant, and is remembered on the device |

All of these live in `packages/game_core/lib/src/monetization/`. Once
"Remove Ads" is bought, banners and interstitials disappear, and hints no
longer need an ad.

### Adding real ads or purchases later (outline)

1. Add the official package, for example `google_mobile_ads` or
   `in_app_purchase`, to `packages/game_core/pubspec.yaml`.
2. Create `AdMobAdService implements AdService` (or
   `StorePurchaseService extends PurchaseService`) next to the fakes.
3. In `GameServices.create` (`packages/game_core/lib/src/services/game_services.dart`),
   use the real class instead of the fake one, but only on Android and iOS.
   Keep the fakes for web and tests.
4. Add your ad unit IDs and store product IDs. Never commit private keys.

No game code needs to change, because games only talk to the interfaces.

---

## Adding the next game

1. From `apps/`, run
   `flutter create --platforms android,ios,web --empty minesweeper`.
2. Add `apps/minesweeper` to the `workspace:` list in the top-level
   `pubspec.yaml`.
3. In `apps/minesweeper/pubspec.yaml`, add `resolution: workspace`, and add
   `game_core: {path: ../../packages/game_core}` under `dependencies`.
4. In `main.dart`, call `GameServices.create(gameId: 'minesweeper')` and wrap
   the app in `GameServicesScope` and `CalmTheme.build()`, just like
   `apps/sudoku/lib/main.dart` and `app.dart` do.

Settings, stats, streaks, saves, ads and the look then work the same way.

---

## Good to know

- In this Flutter version, Material widgets come from the `material_ui`
  package. Import them with `import 'package:material_ui/material_ui.dart';`.
- Daily puzzles use the phone's local calendar date, so everyone who plays on
  "November 24" gets the same puzzle, whatever their time zone.
- Changing the generator changes every future puzzle, including the daily
  one. A test in `apps/sudoku/test/engine_test.dart` pins one daily puzzle,
  so this can't happen by accident.
