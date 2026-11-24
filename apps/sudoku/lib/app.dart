import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key, required this.services, this.clock});

  final GameServices services;

  /// Overrides "now" (used by tests to pin the daily puzzle's date).
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return GameServicesScope(
      services: services,
      child: MaterialApp(
        title: 'Sudoku',
        debugShowCheckedModeBanner: false,
        theme: CalmTheme.build(),
        darkTheme: CalmTheme.build(),
        themeMode: ThemeMode.dark,
        builder: (context, child) => ColoredBox(
          color: CalmColors.calm.background,
          // On tablets and desktop browsers, keep a phone-like column.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: child,
            ),
          ),
        ),
        home: HomeScreen(clock: clock ?? DateTime.now),
      ),
    );
  }
}
