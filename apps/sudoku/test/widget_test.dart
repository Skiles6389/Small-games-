import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sudoku/app.dart';
import 'package:sudoku/engine/difficulty.dart';
import 'package:sudoku/game/game_controller.dart';
import 'package:sudoku/screens/win_screen.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Unmounts the app so the game timer is cancelled before the test ends.
Future<void> closeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final today = DateTime(2026, 11, 24, 10);

  testWidgets('home screen shows daily puzzle and new game', (tester) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    await tester.pumpWidget(SudokuApp(services: services, clock: () => today));

    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Daily puzzle'), findsOneWidget);
    expect(find.text('Tuesday, Nov 24'), findsOneWidget);
    expect(find.text('New game'), findsOneWidget);
    expect(find.textContaining('Continue'), findsNothing);
  });

  testWidgets('start a game, enter digits, notes, undo and hint', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    await tester.pumpWidget(SudokuApp(services: services, clock: () => today));

    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Easy'));
    await tester.pumpAndSettle();

    expect(find.text('Easy'), findsOneWidget, reason: 'app bar title');
    expect(find.text('Banner ad placeholder'), findsOneWidget);
    expect(find.text('AD'), findsOneWidget);

    final c = GameController.resume(services)!;
    final empty = c.game.values.indexOf(0);
    c.dispose();

    await tester.tap(find.byKey(ValueKey('cell-$empty')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('action-notes')));
    await tester.pump();
    expect(find.text('ON'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pad-1')));
    await tester.tap(find.byKey(const ValueKey('pad-2')));
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey('cell-$empty'));
    expect(find.descendant(of: cell, matching: find.text('1')), findsOneWidget);
    expect(find.descendant(of: cell, matching: find.text('2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('action-undo')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: cell, matching: find.text('2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('action-hint')));
    await tester.pumpAndSettle();
    final saved = GameController.resume(services)!;
    expect(saved.game.isRevealed(empty), isTrue);
    expect(saved.game.hintsUsed, 1);
    saved.dispose();

    await closeApp(tester);
  });

  testWidgets('leaving a game shows its time on the continue button', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    await tester.pumpWidget(SudokuApp(services: services, clock: () => today));
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medium'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.textContaining('Continue'), findsOneWidget);
    expect(find.textContaining('Medium  0:03'), findsOneWidget);
  });

  testWidgets('continue button appears for a saved game', (tester) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    final c = await GameController.newGame(services, Difficulty.hard, seed: 3);
    c.dispose();
    await tester.pumpWidget(SudokuApp(services: services, clock: () => today));
    expect(find.textContaining('Continue'), findsOneWidget);
    expect(find.textContaining('Hard'), findsOneWidget);
  });

  testWidgets('win screen shows the result', (tester) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    await tester.pumpWidget(
      GameServicesScope(
        services: services,
        child: MaterialApp(
          theme: CalmTheme.build(),
          home: const WinScreen(
            isDaily: false,
            outcome: GameOutcome(
              seconds: 245,
              difficulty: Difficulty.medium,
              isNewBest: true,
              mistakes: 1,
              hintsUsed: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solved!'), findsOneWidget);
    expect(find.text('4:05'), findsOneWidget);
    expect(find.text('New best time'), findsOneWidget);
    expect(find.text('New Medium game'), findsOneWidget);
  });

  testWidgets('settings and stats screens open', (tester) async {
    usePhoneScreen(tester);
    final services = GameServices.inMemory(gameId: 'sudoku');
    await tester.pumpWidget(SudokuApp(services: services, clock: () => today));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Show mistakes'), findsOneWidget);
    await tester.tap(find.text('Show mistakes'));
    await tester.pump();
    expect(
      services.settings.getBool('sudoku.showMistakes', defaultValue: true),
      isFalse,
    );
    await tester.tap(find.text('Remove ads'));
    await tester.pump();
    expect(services.purchases.adsRemoved, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Expert'), findsOneWidget);
  });
}
