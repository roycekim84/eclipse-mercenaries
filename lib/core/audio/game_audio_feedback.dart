import 'package:flutter/services.dart';

import '../../domain/game_settings.dart';

abstract final class GameAudioFeedback {
  static Future<void> navigation(GameSettings settings) async {
    if (!settings.soundEnabled) return;
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> confirmation(GameSettings settings) async {
    if (!settings.soundEnabled) return;
    await SystemSound.play(SystemSoundType.alert);
  }
}
