import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps native mobile builds in the game's landscape presentation.
///
/// Web deliberately follows the browser and device orientation so the public
/// alpha can still be embedded, resized, and tested in responsive viewports.
abstract final class MobileOrientation {
  static const landscapeOrientations = <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> apply() async {
    if (kIsWeb) return;
    await SystemChrome.setPreferredOrientations(landscapeOrientations);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0x00000000),
          systemNavigationBarColor: Color(0x00000000),
          systemNavigationBarDividerColor: Color(0x00000000),
        ),
      );
    }
  }
}
