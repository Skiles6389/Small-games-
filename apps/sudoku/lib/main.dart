import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'engine/sudoku_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay in portrait. Browsers ignore this.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final services = await GameServices.create(gameId: SudokuGenerator.gameId);
  runApp(SudokuApp(services: services));
}
