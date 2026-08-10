import 'package:flutter/widgets.dart';

import 'app/game_app.dart';
import 'core/platform/mobile_orientation.dart';
export 'app/game_app.dart' show EclipseMercenariesApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileOrientation.apply();
  runApp(const EclipseMercenariesApp());
}
