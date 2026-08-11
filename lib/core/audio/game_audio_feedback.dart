import 'package:flame_audio/flame_audio.dart';

import '../../domain/game_settings.dart';

abstract final class GameAudioFeedback {
  static bool _loaded = false;
  static String? _ambience;

  static Future<void> prepare() async {
    if (_loaded) return;
    try {
      await FlameAudio.audioCache.loadAll(const [
        'ui_click.wav',
        'confirm.wav',
        'battle_hit.wav',
        'ultimate.wav',
        'camp_loop.wav',
        'battle_loop.wav',
      ]);
      _loaded = true;
    } on Object {
      // Audio must never prevent loading or resuming a battle.
    }
  }

  static Future<void> navigation(GameSettings settings) async {
    if (!settings.soundEnabled) return;
    await _play('ui_click.wav', volume: .32);
  }

  static Future<void> confirmation(GameSettings settings) async {
    if (!settings.soundEnabled) return;
    await _play('confirm.wav', volume: .42);
  }

  static Future<void> ultimate(GameSettings settings) async {
    await ultimateEnabled(settings.soundEnabled);
  }

  static Future<void> ultimateEnabled(bool enabled) async {
    if (!enabled) return;
    await _play('ultimate.wav', volume: .66);
  }

  static Future<void> campAmbience(GameSettings settings) async {
    await _ambienceLoop(settings, 'camp_loop.wav', volume: .2);
  }

  static Future<void> battleAmbience(GameSettings settings) async {
    await _ambienceLoop(settings, 'battle_loop.wav', volume: .27);
  }

  static Future<void> stop() async {
    _ambience = null;
    try {
      await FlameAudio.bgm.stop();
    } on Object {
      // Some web browsers reject audio operations before the first gesture.
    }
  }

  static Future<void> _play(String asset, {required double volume}) async {
    await prepare();
    try {
      await FlameAudio.play(asset, volume: volume);
    } on Object {
      // Keep UI actions deterministic when audio output is unavailable.
    }
  }

  static Future<void> _ambienceLoop(
    GameSettings settings,
    String asset, {
    required double volume,
  }) async {
    if (!settings.soundEnabled) {
      await stop();
      return;
    }
    if (_ambience == asset) return;
    await prepare();
    try {
      await FlameAudio.bgm.stop();
      await FlameAudio.bgm.play(asset, volume: volume);
      _ambience = asset;
    } on Object {
      _ambience = null;
    }
  }
}
