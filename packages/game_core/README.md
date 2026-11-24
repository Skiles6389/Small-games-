# game_core

Shared building blocks for every game in this repo. Import everything with:

```dart
import 'package:game_core/game_core.dart';
```

| Piece | What it does |
| --- | --- |
| `CalmTheme`, `CalmColors` | The calm dark-mode look. Use `CalmColors.of(context)` in widgets |
| `GameServices`, `GameServicesScope` | Creates and shares everything below. Use `GameServices.of(context)` |
| `SettingsController` | On/off settings saved automatically. Games can add their own keys |
| `KeyValueStore`, `SaveSlot` | Saving data (device storage, or memory in tests) and auto-save slots |
| `StatsRepository` | Games played and won, plus best and average times for each mode |
| `DailyPuzzle`, `StreakTracker` | Daily seeds that match for everyone on the same date, and the streak counter |
| `SeededRandom`, `stableHash` | Random numbers that come out the same on phones and on the web |
| `AdService`, `PurchaseService` | Ad and in-app purchase interfaces, with fake versions |
| `AdBannerSlot` | A banner placeholder that hides itself after "Remove Ads" |

Run the tests with `flutter test`. Add `--platform chrome` to run them in a
browser.
