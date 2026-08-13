enum BattleInputMode { hybrid, virtualStick, touch }

enum AutoTargetPriority { nearest, elite, objectiveThreat }

class GameSettings {
  const GameSettings({
    required this.tutorialCompleted,
    required this.soundEnabled,
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
    required this.uiVolume,
    required this.voiceVolume,
    required this.hapticsEnabled,
    required this.screenShakeEnabled,
    required this.reducedFlash,
    required this.performanceMode,
    required this.largeText,
    required this.battleInputMode,
    required this.autoTargetPriority,
  });

  const GameSettings.defaults()
    : tutorialCompleted = false,
      soundEnabled = true,
      masterVolume = .8,
      musicVolume = .72,
      sfxVolume = .88,
      uiVolume = .82,
      voiceVolume = .8,
      hapticsEnabled = true,
      screenShakeEnabled = true,
      reducedFlash = false,
      performanceMode = false,
      largeText = false,
      battleInputMode = BattleInputMode.hybrid,
      autoTargetPriority = AutoTargetPriority.nearest;

  final bool tutorialCompleted;
  final bool soundEnabled;
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final double uiVolume;
  final double voiceVolume;
  final bool hapticsEnabled;
  final bool screenShakeEnabled;
  final bool reducedFlash;
  final bool performanceMode;
  final bool largeText;
  final BattleInputMode battleInputMode;
  final AutoTargetPriority autoTargetPriority;

  GameSettings copyWith({
    bool? tutorialCompleted,
    bool? soundEnabled,
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
    double? uiVolume,
    double? voiceVolume,
    bool? hapticsEnabled,
    bool? screenShakeEnabled,
    bool? reducedFlash,
    bool? performanceMode,
    bool? largeText,
    BattleInputMode? battleInputMode,
    AutoTargetPriority? autoTargetPriority,
  }) => GameSettings(
    tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    masterVolume: masterVolume ?? this.masterVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    uiVolume: uiVolume ?? this.uiVolume,
    voiceVolume: voiceVolume ?? this.voiceVolume,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    screenShakeEnabled: screenShakeEnabled ?? this.screenShakeEnabled,
    reducedFlash: reducedFlash ?? this.reducedFlash,
    performanceMode: performanceMode ?? this.performanceMode,
    largeText: largeText ?? this.largeText,
    battleInputMode: battleInputMode ?? this.battleInputMode,
    autoTargetPriority: autoTargetPriority ?? this.autoTargetPriority,
  );

  Map<String, Object> toJson() => {
    'tutorialCompleted': tutorialCompleted,
    'soundEnabled': soundEnabled,
    'masterVolume': masterVolume,
    'musicVolume': musicVolume,
    'sfxVolume': sfxVolume,
    'uiVolume': uiVolume,
    'voiceVolume': voiceVolume,
    'hapticsEnabled': hapticsEnabled,
    'screenShakeEnabled': screenShakeEnabled,
    'reducedFlash': reducedFlash,
    'performanceMode': performanceMode,
    'largeText': largeText,
    'battleInputMode': battleInputMode.name,
    'autoTargetPriority': autoTargetPriority.name,
  };

  factory GameSettings.fromJson(Object? raw) {
    const defaults = GameSettings.defaults();
    if (raw is! Map) return defaults;
    double volume(String key, double fallback) {
      final value = (raw[key] as num?)?.toDouble();
      if (value == null || !value.isFinite) return fallback;
      return value.clamp(0.0, 1.0).toDouble();
    }

    return GameSettings(
      tutorialCompleted: raw['tutorialCompleted'] as bool? ?? false,
      soundEnabled: raw['soundEnabled'] as bool? ?? defaults.soundEnabled,
      masterVolume: volume('masterVolume', defaults.masterVolume),
      musicVolume: volume('musicVolume', defaults.musicVolume),
      sfxVolume: volume('sfxVolume', defaults.sfxVolume),
      uiVolume: volume('uiVolume', defaults.uiVolume),
      voiceVolume: volume('voiceVolume', defaults.voiceVolume),
      hapticsEnabled: raw['hapticsEnabled'] as bool? ?? defaults.hapticsEnabled,
      screenShakeEnabled:
          raw['screenShakeEnabled'] as bool? ?? defaults.screenShakeEnabled,
      reducedFlash: raw['reducedFlash'] as bool? ?? defaults.reducedFlash,
      performanceMode:
          raw['performanceMode'] as bool? ?? defaults.performanceMode,
      largeText: raw['largeText'] as bool? ?? defaults.largeText,
      battleInputMode: BattleInputMode.values.firstWhere(
        (value) => value.name == raw['battleInputMode'],
        orElse: () => defaults.battleInputMode,
      ),
      autoTargetPriority: AutoTargetPriority.values.firstWhere(
        (value) => value.name == raw['autoTargetPriority'],
        orElse: () => defaults.autoTargetPriority,
      ),
    );
  }
}
