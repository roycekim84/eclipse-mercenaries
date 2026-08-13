import 'dart:async';
import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

import '../../domain/battle_models.dart';
import '../../domain/game_data.dart';
import '../../domain/game_settings.dart';

enum AudioCue {
  navigation,
  back,
  confirm,
  error,
  reward,
  purchase,
  equip,
  forge,
  levelUp,
  choice,
  eventCommon,
  eventSpecial,
  eventRare,
  eventLegendary,
  bossPhase,
  victory,
  defeat,
  retreat,
  recruitContract,
  recruitSeal,
  recruitRarity,
  recruitReveal,
  recruitFeatured,
  duplicate,
  lootRare,
}

enum CombatAudioCue {
  slash,
  blunt,
  pierce,
  magic,
  block,
  playerHurt,
  critical,
  bossImpact,
  enemyDefeat,
}

/// Central music/SFX/UI/voice mixer for the application.
///
/// It intentionally limits combat voices. Hundreds of units can hit in one
/// frame, but only tactically useful player, critical and boss sounds reach the
/// listener.
abstract final class GameAudioFeedback {
  static final _random = math.Random(0xEC11);
  static final Map<CombatAudioCue, DateTime> _lastCombatCue = {};
  static final Map<String, AudioPool> _pools = {};
  static Future<void>? _preparing;
  static String? _music;
  static double _musicBaseVolume = 1;
  static GameSettings _settings = const GameSettings.defaults();

  static const _cueAssets = <AudioCue, String>{
    AudioCue.navigation: 'ui_click.wav',
    AudioCue.back: 'ui_back.wav',
    AudioCue.confirm: 'confirm.wav',
    AudioCue.error: 'ui_error.wav',
    AudioCue.reward: 'reward_claim.wav',
    AudioCue.purchase: 'purchase.wav',
    AudioCue.equip: 'equip.wav',
    AudioCue.forge: 'forge.wav',
    AudioCue.levelUp: 'level_up.wav',
    AudioCue.choice: 'choice_select.wav',
    AudioCue.eventCommon: 'event_common.wav',
    AudioCue.eventSpecial: 'event_special.wav',
    AudioCue.eventRare: 'event_rare.wav',
    AudioCue.eventLegendary: 'event_legendary.wav',
    AudioCue.bossPhase: 'boss_phase.wav',
    AudioCue.victory: 'victory.wav',
    AudioCue.defeat: 'defeat.wav',
    AudioCue.retreat: 'retreat.wav',
    AudioCue.recruitContract: 'recruit_contract.wav',
    AudioCue.recruitSeal: 'recruit_seal.wav',
    AudioCue.recruitRarity: 'recruit_rarity.wav',
    AudioCue.recruitReveal: 'recruit_reveal.wav',
    AudioCue.recruitFeatured: 'recruit_featured.wav',
    AudioCue.duplicate: 'duplicate_convert.wav',
    AudioCue.lootRare: 'loot_rare.wav',
  };

  static const _combatAssets = <CombatAudioCue, List<String>>{
    CombatAudioCue.slash: [
      'hit_slash_1.wav',
      'hit_slash_2.wav',
      'hit_slash_3.wav',
    ],
    CombatAudioCue.blunt: ['hit_blunt.wav'],
    CombatAudioCue.pierce: ['hit_pierce.wav'],
    CombatAudioCue.magic: ['hit_magic.wav'],
    CombatAudioCue.block: ['shield_block.wav'],
    CombatAudioCue.playerHurt: ['player_hurt.wav'],
    CombatAudioCue.critical: ['critical_hit.wav'],
    CombatAudioCue.bossImpact: ['boss_impact.wav'],
    CombatAudioCue.enemyDefeat: ['enemy_defeat.wav'],
  };

  static const _cueGain = <AudioCue, double>{
    AudioCue.navigation: .30,
    AudioCue.back: .32,
    AudioCue.confirm: .42,
    AudioCue.error: .46,
    AudioCue.reward: .55,
    AudioCue.purchase: .46,
    AudioCue.equip: .44,
    AudioCue.forge: .54,
    AudioCue.levelUp: .54,
    AudioCue.choice: .43,
    AudioCue.eventCommon: .42,
    AudioCue.eventSpecial: .48,
    AudioCue.eventRare: .55,
    AudioCue.eventLegendary: .62,
    AudioCue.bossPhase: .62,
    AudioCue.victory: .68,
    AudioCue.defeat: .64,
    AudioCue.retreat: .58,
    AudioCue.recruitContract: .48,
    AudioCue.recruitSeal: .55,
    AudioCue.recruitRarity: .56,
    AudioCue.recruitReveal: .62,
    AudioCue.recruitFeatured: .72,
    AudioCue.duplicate: .48,
    AudioCue.lootRare: .58,
  };

  static const _uiCues = <AudioCue>{
    AudioCue.navigation,
    AudioCue.back,
    AudioCue.confirm,
    AudioCue.error,
    AudioCue.choice,
  };

  static Future<void> prepare() => _preparing ??= _prepare();

  static Future<void> _prepare() async {
    try {
      await FlameAudio.bgm.initialize();
      final poolAssets = _combatAssets.values
          .expand((assets) => assets)
          .toSet();
      await FlameAudio.audioCache.loadAll(
        {
          ..._cueAssets.values,
          ...poolAssets,
          'camp_loop.wav',
          'recruitment_loop.wav',
          'battle_gate_loop.wav',
          'battle_ash_loop.wav',
          'battle_forest_loop.wav',
          'battle_siege_loop.wav',
          'battle_fortress_loop.wav',
          for (final id in const [
            'luna',
            'kael',
            'sera',
            'nyra',
            'aurel',
            'vesta',
            'rask',
            'iris',
          ])
            'ultimate_${id}_charge.wav',
          for (final id in const [
            'luna',
            'kael',
            'sera',
            'nyra',
            'aurel',
            'vesta',
            'rask',
            'iris',
          ])
            'ultimate_${id}_impact.wav',
        }.toList(growable: false),
      );
      for (final asset in poolAssets) {
        _pools[asset] = await FlameAudio.createPool(
          asset,
          minPlayers: 1,
          maxPlayers: 4,
        );
      }
    } on Object {
      _preparing = null;
      // Audio output must never block loading, combat or save recovery.
    }
  }

  static Future<void> applySettings(GameSettings settings) async {
    _settings = settings;
    if (!settings.soundEnabled ||
        settings.masterVolume <= 0 ||
        settings.musicVolume <= 0) {
      await stopMusic();
      return;
    }
    if (_music != null) await _setMusicVolume(_musicBaseVolume);
  }

  static Future<void> cue(AudioCue cue, [GameSettings? settings]) async {
    final active = settings ?? _settings;
    _settings = active;
    final uiCue = _uiCues.contains(cue);
    if (uiCue ? !_uiEnabled(active) : !_sfxEnabled(active)) return;
    final busVolume = uiCue ? active.uiVolume : active.sfxVolume;
    await _play(
      _cueAssets[cue]!,
      volume: (_cueGain[cue] ?? .5) * active.masterVolume * busVolume,
    );
    if (active.hapticsEnabled &&
        const {
          AudioCue.error,
          AudioCue.reward,
          AudioCue.bossPhase,
          AudioCue.victory,
          AudioCue.defeat,
          AudioCue.recruitFeatured,
        }.contains(cue)) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  static Future<void> navigation(GameSettings settings) =>
      cue(AudioCue.navigation, settings);
  static Future<void> confirmation(GameSettings settings) =>
      cue(AudioCue.confirm, settings);

  static Future<void> combat(
    CombatAudioCue cue, {
    CombatStyle style = CombatStyle.blades,
    bool enabled = true,
    bool haptics = false,
  }) async {
    if (!enabled || !_sfxEnabled(_settings)) return;
    final resolved = cue == CombatAudioCue.slash
        ? switch (style) {
            CombatStyle.magic => CombatAudioCue.magic,
            CombatStyle.greatsword => CombatAudioCue.blunt,
            CombatStyle.blades => CombatAudioCue.slash,
          }
        : cue;
    final now = DateTime.now();
    final cooldown = switch (resolved) {
      CombatAudioCue.slash ||
      CombatAudioCue.pierce ||
      CombatAudioCue.magic => 65,
      CombatAudioCue.blunt || CombatAudioCue.block => 90,
      CombatAudioCue.enemyDefeat => 130,
      CombatAudioCue.critical => 110,
      CombatAudioCue.playerHurt || CombatAudioCue.bossImpact => 180,
    };
    final previous = _lastCombatCue[resolved];
    if (previous != null &&
        now.difference(previous).inMilliseconds < cooldown) {
      return;
    }
    _lastCombatCue[resolved] = now;
    final assets = _combatAssets[resolved]!;
    final asset = assets[_random.nextInt(assets.length)];
    await prepare();
    try {
      await _pools[asset]?.start(
        volume: .46 * _settings.masterVolume * _settings.sfxVolume,
      );
      if (haptics && _settings.hapticsEnabled) {
        unawaited(HapticFeedback.lightImpact());
      }
    } on Object {
      // Pool exhaustion and unsupported web audio must not affect combat.
    }
  }

  static Future<void> ultimateCharge(
    String mercenaryId, {
    required bool enabled,
  }) async {
    if (!enabled || !_sfxEnabled(_settings)) return;
    await duckMusic(.38);
    await _play(
      'ultimate_${_safeMercenaryId(mercenaryId)}_charge.wav',
      volume: .70 * _settings.masterVolume * _settings.sfxVolume,
    );
    if (_settings.hapticsEnabled) unawaited(HapticFeedback.mediumImpact());
  }

  static Future<void> ultimateImpact(
    String mercenaryId, {
    required bool enabled,
  }) async {
    if (!enabled || !_sfxEnabled(_settings)) return;
    await _play(
      'ultimate_${_safeMercenaryId(mercenaryId)}_impact.wav',
      volume: .82 * _settings.masterVolume * _settings.sfxVolume,
    );
    if (_settings.hapticsEnabled) unawaited(HapticFeedback.heavyImpact());
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 850), restoreMusic),
    );
  }

  static Future<void> campAmbience(GameSettings settings) =>
      _musicLoop(settings, 'camp_loop.wav', volume: .22);

  static Future<void> recruitmentAmbience(GameSettings settings) =>
      _musicLoop(settings, 'recruitment_loop.wav', volume: .22);

  static Future<void> battleAmbience(
    GameSettings settings,
    BattlefieldType type,
  ) => _musicLoop(settings, switch (type) {
    BattlefieldType.gateDefense => 'battle_gate_loop.wav',
    BattlefieldType.evacuation => 'battle_ash_loop.wav',
    BattlefieldType.supplyEscort ||
    BattlefieldType.ambush => 'battle_forest_loop.wav',
    BattlefieldType.assassination => 'battle_siege_loop.wav',
    BattlefieldType.fortressRetake => 'battle_fortress_loop.wav',
  }, volume: .29);

  static Future<void> result(
    BattleOutcome outcome,
    GameSettings settings,
  ) async {
    _settings = settings;
    await stopMusic();
    await cue(switch (outcome) {
      BattleOutcome.victory => AudioCue.victory,
      BattleOutcome.retreat => AudioCue.retreat,
      BattleOutcome.defeat => AudioCue.defeat,
    }, settings);
  }

  static Future<void> duckMusic([double factor = .48]) =>
      _setMusicVolume(_musicBaseVolume * factor);

  static Future<void> restoreMusic() => _setMusicVolume(_musicBaseVolume);

  static Future<void> pauseAll() async {
    try {
      await FlameAudio.bgm.pause();
    } on Object {
      // Lifecycle audio is best-effort on web and interrupted mobile output.
    }
  }

  static Future<void> resumeAll() async {
    if (_music == null || !_musicEnabled(_settings)) return;
    try {
      await FlameAudio.bgm.resume();
    } on Object {
      // Lifecycle audio is best-effort on web and interrupted mobile output.
    }
  }

  static Future<void> stopMusic() async {
    _music = null;
    try {
      await FlameAudio.bgm.stop();
    } on Object {
      // Stopping unavailable audio must not block navigation.
    }
  }

  static Future<void> _play(String asset, {required double volume}) async {
    await prepare();
    try {
      await FlameAudio.play(asset, volume: volume.clamp(0, 1));
    } on Object {
      // A rejected browser audio gesture must not block the UI action.
    }
  }

  static Future<void> _musicLoop(
    GameSettings settings,
    String asset, {
    required double volume,
  }) async {
    _settings = settings;
    _musicBaseVolume = volume;
    if (!_musicEnabled(settings)) {
      await stopMusic();
      return;
    }
    if (_music == asset) {
      await _setMusicVolume(volume);
      return;
    }
    await prepare();
    try {
      await FlameAudio.bgm.play(
        asset,
        volume: (volume * settings.masterVolume * settings.musicVolume).clamp(
          0,
          1,
        ),
      );
      _music = asset;
    } on Object {
      _music = null;
    }
  }

  static Future<void> _setMusicVolume(double gain) async {
    if (_music == null || !_musicEnabled(_settings)) return;
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(
        (gain * _settings.masterVolume * _settings.musicVolume).clamp(0, 1),
      );
    } on Object {
      // Volume changes are best-effort during platform audio interruption.
    }
  }

  static bool _musicEnabled(GameSettings settings) =>
      settings.soundEnabled &&
      settings.masterVolume > 0 &&
      settings.musicVolume > 0;

  static bool _sfxEnabled(GameSettings settings) =>
      settings.soundEnabled &&
      settings.masterVolume > 0 &&
      settings.sfxVolume > 0;

  static bool _uiEnabled(GameSettings settings) =>
      settings.soundEnabled &&
      settings.masterVolume > 0 &&
      settings.uiVolume > 0;

  static String _safeMercenaryId(String id) =>
      const {
        'luna',
        'kael',
        'sera',
        'nyra',
        'aurel',
        'vesta',
        'rask',
        'iris',
      }.contains(id)
      ? id
      : 'luna';
}
