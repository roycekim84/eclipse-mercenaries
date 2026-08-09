import 'package:flutter/widgets.dart';

import 'app/game_app.dart';
export 'app/game_app.dart' show EclipseMercenariesApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EclipseMercenariesApp());
}
