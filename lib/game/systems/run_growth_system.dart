part of '../survivor_game.dart';

extension RunGrowthSystem on SurvivorGame {
  static const int _maxWeaponLevel = 5;
  static const int _maxTraitLevel = 3;
  static const int _maxWeaponSlots = 4;

  int _passiveLevel(String id) => _passiveLevels[id] ?? 0;

  List<RunUpgradeDefinition> get _upgradeDefinitions => config.isIntroBattle
      ? const [
          RunUpgradeDefinition(
            id: 'moon_blades',
            kind: RunUpgradeKind.weapon,
            maxLevel: _maxWeaponLevel,
            baseWeight: 120,
          ),
          RunUpgradeDefinition(
            id: 'shadow_knife',
            kind: RunUpgradeKind.weapon,
            maxLevel: _maxWeaponLevel,
            baseWeight: 92,
          ),
          RunUpgradeDefinition(
            id: 'ember_orb',
            kind: RunUpgradeKind.weapon,
            maxLevel: _maxWeaponLevel,
            baseWeight: 86,
          ),
          RunUpgradeDefinition(
            id: 'war_bow',
            kind: RunUpgradeKind.weapon,
            maxLevel: _maxWeaponLevel,
            baseWeight: 78,
          ),
          RunUpgradeDefinition(
            id: 'rapid_drill',
            kind: RunUpgradeKind.passive,
            maxLevel: 5,
            baseWeight: 76,
          ),
          RunUpgradeDefinition(
            id: 'mercenary_trait',
            kind: RunUpgradeKind.trait,
            maxLevel: _maxTraitLevel,
            baseWeight: 82,
          ),
        ]
      : [
          for (final availableWeapon in alphaWeapons)
            if (RunGrowthRules.canOfferWeapon(
              ownerId: availableWeapon.ownerId,
              mercenaryId: mercenary.id,
              equippedWeaponId: weapon.id,
              weaponId: availableWeapon.id,
            ))
              RunUpgradeDefinition(
                id: availableWeapon.id,
                kind: RunUpgradeKind.weapon,
                maxLevel: _maxWeaponLevel,
                baseWeight: availableWeapon.id == weapon.id ? 92 : 54,
              ),
          ...alphaPassiveDefinitions,
          const RunUpgradeDefinition(
            id: 'mercenary_trait',
            kind: RunUpgradeKind.trait,
            maxLevel: _maxTraitLevel,
            baseWeight: 58,
          ),
        ];

  RunGrowthState get _runGrowthState => RunGrowthState(
    weaponLevels: {
      for (final state in _runWeapons) state.weapon.id: state.level,
    },
    passiveLevels: Map.unmodifiable(_passiveLevels),
    traitLevel: _traitLevel,
    maxWeaponSlots: _maxWeaponSlots,
  );

  List<RunBuildEntry> get _currentBuildEntries => [
    for (final state in _runWeapons)
      RunBuildEntry(
        id: state.weapon.id,
        kind: RunUpgradeKind.weapon,
        level: state.level,
        maxLevel: _maxWeaponLevel,
      ),
    for (final passive in _passiveLevels.entries)
      RunBuildEntry(
        id: passive.key,
        kind: RunUpgradeKind.passive,
        level: passive.value,
        maxLevel: 5,
      ),
    if (_traitLevel > 0)
      RunBuildEntry(
        id: mercenary.id,
        kind: RunUpgradeKind.trait,
        level: _traitLevel,
        maxLevel: _maxTraitLevel,
      ),
  ];

  bool _sameBuild(List<RunBuildEntry> a, List<RunBuildEntry> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].kind != b[i].kind ||
          a[i].level != b[i].level) {
        return false;
      }
    }
    return true;
  }

  void _updateRunWeapons(double dt) {
    final speedMultiplier = math.max(
      .58,
      1 - _passiveLevel('rapid_drill') * (config.isIntroBattle ? .14 : .07),
    );
    for (final state in _runWeapons) {
      state.attackClock += dt;
      final nocturnalSpeed =
          mercenary.id == 'luna' &&
              config.condition == BattlefieldCondition.moonlitNight
          ? .8
          : 1.0;
      final interval =
          mercenary.attackInterval *
          (100 / (100 + state.weapon.speed)) *
          math.max(.55, 1 - state.level * .045) *
          speedMultiplier *
          nocturnalSpeed;
      if (state.attackClock < interval) continue;
      state.attackClock = 0;
      _attackWithWeapon(state);
      if (_pausedForChoice) break;
    }
  }

  void _requestLevelUp() {
    if (_xp < _nextXp || _pausedForChoice) return;
    final introProfile = config.introProfile;
    if (introProfile != null && _elapsed < introProfile.firstLevelUpAt) {
      _levelUpPending = true;
      return;
    }
    if (_pausedForEvent ||
        eventPrompt.value != null ||
        _bossPhaseBannerClock > 0 ||
        _ultimateClock > 0) {
      _levelUpPending = true;
      return;
    }
    _levelUpPending = false;
    _levelUp();
  }

  void _levelUp() {
    _xp -= _nextXp;
    _nextXp = (_nextXp * 1.32).roundToDouble();
    _level++;
    _firstLevelUpAt ??= _elapsed;
    unawaited(GameAudioFeedback.cue(AudioCue.levelUp, audioSettings));
    final definitions = RunGrowthRules.generateChoices(
      definitions: _upgradeDefinitions,
      state: _runGrowthState,
      random: _upgradeRandom,
    );
    if (definitions.isEmpty) return;
    _pausedForChoice = true;
    pauseEngine();
    choice.value = BattleChoice(
      definitions.map(_toUpgradeOption).toList(growable: false),
    );
  }

  UpgradeOption _toUpgradeOption(RunUpgradeDefinition definition) {
    final currentLevel = _runGrowthState.levelOf(definition);
    if (definition.kind == RunUpgradeKind.weapon) {
      final selectedWeapon = alphaWeapons.firstWhere(
        (candidate) => candidate.id == definition.id,
      );
      final introDescription = switch (selectedWeapon.pattern) {
        WeaponPattern.twinSlash => '검격이 넓어지고 주변 적까지 연속으로 베어냅니다.',
        WeaponPattern.shadowPierce => '관통 투검이 전열을 가로질러 다수의 적을 벱니다.',
        WeaponPattern.emberBurst => '적 무리에서 폭발해 주변을 불태웁니다.',
        WeaponPattern.longBow => '먼 적을 빠르게 꿰뚫는 화살을 발사합니다.',
        _ => selectedWeapon.description,
      };
      return UpgradeOption(
        id: definition.id,
        kind: definition.kind,
        title: currentLevel == 0
            ? '${selectedWeapon.name} 획득'
            : '${selectedWeapon.name} 강화',
        description: config.isIntroBattle
            ? introDescription
            : currentLevel == 0
            ? selectedWeapon.description
            : '공격 피해와 공격 주기가 강화됩니다.',
        iconId: selectedWeapon.id,
        currentLevel: currentLevel,
        maxLevel: definition.maxLevel,
      );
    }
    if (definition.kind == RunUpgradeKind.trait) {
      return UpgradeOption(
        id: definition.id,
        kind: definition.kind,
        title: mercenary.trait,
        description: '${mercenary.traitDescription} · 고유 효과가 강화됩니다.',
        iconId: mercenary.id,
        currentLevel: currentLevel,
        maxLevel: definition.maxLevel,
      );
    }
    final (title, description, iconId) = switch (definition.id) {
      'battle_instinct' => (
        '전투 본능',
        '모든 무기의 피해가 10% 증가합니다.',
        'battle_instinct',
      ),
      'rapid_drill' => (
        config.isIntroBattle ? '쏟아지는 검격' : '속전 훈련',
        config.isIntroBattle
            ? '공격 간격이 크게 짧아져 화면에 공격이 끊이지 않습니다.'
            : '모든 무기의 공격 주기가 7% 감소합니다.',
        'rapid_drill',
      ),
      'swift_step' => ('신속한 발걸음', '이동속도가 8% 증가합니다.', 'swift_step'),
      _ => ('예리한 시선', '치명타 확률이 5% 증가합니다.', 'keen_eye'),
    };
    return UpgradeOption(
      id: definition.id,
      kind: definition.kind,
      title: title,
      description: description,
      iconId: iconId,
      currentLevel: currentLevel,
      maxLevel: definition.maxLevel,
    );
  }

  RunWeaponState? _findRunWeapon(String id) {
    for (final state in _runWeapons) {
      if (state.weapon.id == id) return state;
    }
    return null;
  }

  void selectUpgrade(int index) {
    final activeChoice = choice.value;
    if (activeChoice == null ||
        index < 0 ||
        index >= activeChoice.options.length) {
      return;
    }
    final selected = activeChoice.options[index];
    if (config.isIntroBattle) _funGrowthChoices.add(selected.id);
    unawaited(GameAudioFeedback.cue(AudioCue.choice, audioSettings));
    switch (selected.kind) {
      case RunUpgradeKind.weapon:
        final existing = _findRunWeapon(selected.id);
        if (existing != null) {
          existing.level = math.min(_maxWeaponLevel, existing.level + 1);
        } else if (_runWeapons.length < _maxWeaponSlots) {
          _runWeapons.add(
            RunWeaponState(
              alphaWeapons.firstWhere((weapon) => weapon.id == selected.id),
            ),
          );
        }
      case RunUpgradeKind.passive:
        _passiveLevels[selected.id] = math.min(
          5,
          _passiveLevel(selected.id) + 1,
        );
        if (selected.id == 'swift_step') {
          _speed =
              mercenary.speed *
              (config.condition == BattlefieldCondition.ashWind ? .94 : 1) *
              (1 + _passiveLevel('swift_step') * .08);
        }
      case RunUpgradeKind.trait:
        _traitLevel = math.min(_maxTraitLevel, _traitLevel + 1);
    }
    choice.value = null;
    _pausedForChoice = false;
    if (_xp >= _nextXp) _levelUpPending = true;
    if (!_pausedByUser &&
        !_pausedByLifecycle &&
        !_pausedForEvent &&
        !_pausedForUltimate) {
      resumeEngine();
    }
    _publishStats();
  }
}
