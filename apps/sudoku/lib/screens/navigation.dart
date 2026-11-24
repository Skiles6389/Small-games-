import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import 'game_screen.dart';

/// Opens the game screen once [controller] is ready.
Future<void> openGame(
  BuildContext context,
  Future<GameController> controller, {
  bool replace = false,
}) async {
  final navigator = Navigator.of(context);
  final ready = await controller;
  final route = PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => GameScreen(controller: ready),
    transitionsBuilder: (_, animation, _, child) => fadeSlide(animation, child),
  );
  if (replace) {
    await navigator.pushReplacement(route);
  } else {
    await navigator.push(route);
  }
}

/// The app's gentle page transition: fade in while rising slightly.
Widget fadeSlide(Animation<double> animation, Widget child) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Tuesday, Nov 24"
String longDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';

/// "Nov 24"
String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';
