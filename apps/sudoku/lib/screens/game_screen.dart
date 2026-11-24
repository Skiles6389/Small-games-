import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/sudoku_settings.dart';
import '../widgets/action_bar.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_board.dart';
import 'navigation.dart';
import 'settings_screen.dart';
import 'win_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameController get _c => widget.controller;

  /// True when the player pressed pause (as opposed to the app going to the
  /// background), so we don't auto-resume behind their back.
  bool _userPaused = false;
  bool _busy = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.addListener(_onChanged);
    _c.selected ??= 40;
    _c.resumeTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onChanged);
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_userPaused && !_busy) _c.resumeTimer();
    } else {
      _c.pauseTimer();
    }
  }

  void _onChanged() {
    final outcome = _c.outcome;
    if (outcome != null && !_leaving) {
      _leaving = true;
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, _, _) =>
                WinScreen(outcome: outcome, isDaily: _c.isDaily),
            transitionsBuilder: (_, a, _, child) => fadeSlide(a, child),
          ),
        );
      });
    }
  }

  void _haptic() {
    if (_c.settings.hapticsEnabled) HapticFeedback.selectionClick();
  }

  void _onDigit(int d) {
    _haptic();
    _c.input(d);
  }

  void _togglePause() {
    setState(() => _userPaused = !_userPaused);
    _userPaused ? _c.pauseTimer() : _c.resumeTimer();
  }

  Future<void> _hint() async {
    if (_c.isPaused || _c.hintTarget == null) return;
    final services = GameServices.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _busy = true;
    _c.pauseTimer();
    final earned = await services.earnReward(context, placement: 'hint');
    _busy = false;
    if (!mounted) return;
    _c.resumeTimer();
    final target = _c.hintTarget;
    if (earned && target != null) {
      _c.applyHint(target);
    } else if (!earned) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Watch the whole ad to get a hint.')),
      );
    }
  }

  Future<void> _openSettings() async {
    _c.pauseTimer();
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    if (mounted && !_userPaused) _c.resumeTimer();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final label = key.keyLabel;
    final digit = int.tryParse(label);
    if (digit != null && digit >= 1 && digit <= 9) {
      _onDigit(digit);
      return KeyEventResult.handled;
    }
    final sel = _c.selected ?? 40;
    int? move;
    if (key == LogicalKeyboardKey.arrowUp && sel >= 9) move = sel - 9;
    if (key == LogicalKeyboardKey.arrowDown && sel < 72) move = sel + 9;
    if (key == LogicalKeyboardKey.arrowLeft && sel % 9 > 0) move = sel - 1;
    if (key == LogicalKeyboardKey.arrowRight && sel % 9 < 8) move = sel + 1;
    if (move != null) {
      _c.select(move);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        label == '0') {
      _c.erase();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN) {
      _c.toggleNotesMode();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyZ || key == LogicalKeyboardKey.keyU) {
      _c.undo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    final services = GameServices.of(context);
    final puzzle = _c.game.puzzle;
    final title = puzzle.isDaily
        ? 'Daily · ${shortDate(DailyPuzzle.parseKey(puzzle.dailyKey)!)}'
        : puzzle.difficulty.label;

    return PopScope(
      // Save before the home screen refreshes its "Continue" button.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _c.pauseTimer();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: _buildScaffold(context, colors, services, title),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    CalmColors colors,
    GameServices services,
    String title,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _userPaused ? 'Resume' : 'Pause',
            icon: Icon(
              _userPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            onPressed: _togglePause,
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _c,
            services.settings,
            services.purchases,
          ]),
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Row(
                  children: [
                    if (_c.settings.showMistakes)
                      Text(
                        'Mistakes  ${_c.game.mistakes}',
                        style: TextStyle(color: colors.textMuted),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDuration(_c.game.elapsedSeconds),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SudokuBoard(
                              controller: _c,
                              onCellTap: (i) {
                                _haptic();
                                _c.select(i);
                              },
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: !_userPaused,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: _userPaused ? 1 : 0,
                                child: _PausedOverlay(onResume: _togglePause),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ActionBar(
                notesMode: _c.notesMode,
                canUndo: _c.game.canUndo,
                hintNeedsAd: !services.purchases.adsRemoved,
                onUndo: _c.undo,
                onErase: _c.erase,
                onToggleNotes: _c.toggleNotesMode,
                onHint: _hint,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: NumberPad(controller: _c, onDigit: _onDigit),
              ),
              const SizedBox(height: 8),
              const AdBannerSlot(placement: 'game_bottom'),
            ],
          ),
        ),
      ),
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  const _PausedOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final colors = CalmColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.boxLine, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paused',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 160,
            child: FilledButton(
              onPressed: onResume,
              child: const Text('Resume'),
            ),
          ),
        ],
      ),
    );
  }
}
