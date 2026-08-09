part of '../survivor_game.dart';

extension BattlefieldEventSystem on SurvivorGame {
  void _updateBattlefieldEvents() {
    if (_eventClock < _nextEventAt || eventPrompt.value != null) return;
    final progress = (_elapsed / config.durationSeconds).clamp(0.0, 1.0);
    final selected = BattlefieldEventRules.pickNext(
      definitions: alphaBattlefieldEvents,
      triggeredIds: _triggeredEventIds,
      progress: progress,
      random: _eventRandom,
    );
    _nextEventAt += 14;
    if (selected == null) return;
    _triggeredEventIds.add(selected.id);
    _pausedForEvent = true;
    pauseEngine();
    eventPrompt.value = selected;
  }

  void selectBattlefieldEventChoice(int index) {
    final activeEvent = eventPrompt.value;
    if (activeEvent == null ||
        index < 0 ||
        index >= activeEvent.choices.length) {
      return;
    }
    final selected = activeEvent.choices[index];
    _applyBattlefieldEventChoice(selected);
    _eventRecords.add(
      BattlefieldEventRecord(
        eventId: activeEvent.id,
        title: activeEvent.title,
        choiceId: selected.id,
        choiceLabel: selected.label,
        resultText: selected.resultText,
        rarity: activeEvent.rarity,
      ),
    );
    eventPrompt.value = null;
    _pausedForEvent = false;
    event.value = BattleEvent(
      _eventRarityLabel(activeEvent.rarity),
      activeEvent.title,
      selected.resultText,
      id: activeEvent.id,
    );
    Future<void>.delayed(const Duration(seconds: 4), () {
      if (event.value?.id == activeEvent.id) event.value = null;
    });
    if (selected.retreat) {
      _finishBattle(BattleOutcome.retreat);
      return;
    }
    if (!_pausedByUser && !_pausedByLifecycle && !_pausedForChoice) {
      resumeEngine();
    }
    _publishStats();
  }

  void _applyBattlefieldEventChoice(BattlefieldEventChoiceSpec selected) {
    switch (selected.id) {
      case 'stand_and_fight':
        _spawnEventWave(count: 42, archetypeId: 'vargar_conscript');
        _eventGoldBonus += 650;
        _eventXpBonus += 180;
      case 'tactical_retreat' || 'royal_retreat':
        return;
      case 'secure_supplies':
        _eventGoldBonus += 900;
        _eventXpBonus += 120;
      case 'hold_objective' || 'maintain_mission' || 'decline_duel':
        return;
      case 'accept_duel':
        _spawnEventWave(count: 1, archetypeId: 'nameless_knight');
        _eventGoldBonus += 500;
      case 'rescue_commander':
        final commander = _allyCommander;
        if (commander != null) {
          commander
            ..dead = false
            ..hp = commander.maxHp
            ..stance = UnitStance.support;
        }
        _eventXpBonus += 220;
      case 'hire_company':
        _eventGoldBonus -= 350;
        _spawnEventWave(count: 24, ally: true);
      case 'fight_company':
        _spawnEventWave(count: 32, archetypeId: 'free_skirmisher');
        _eventGoldBonus += 800;
      case 'hunt_monsters':
        _spawnEventWave(count: 28, archetypeId: 'cinder_hexer');
        _eventGoldBonus += 700;
        _eventXpBonus += 240;
      case 'tighten_lines':
        if (config.battlefield == BattlefieldType.gateDefense) {
          _gateHp = math.min(GateDefenseRules.maxGateHp, _gateHp + 110);
        } else {
          for (final escort in _escorts) {
            if (!escort.dead && !escort.escaped) {
              escort.hp = math.min(escort.maxHp.toDouble(), escort.hp + 6);
            }
          }
        }
      case 'embrace_red_moon':
        _enemySpeedMultiplier *= 1.18;
        _enemyDamageBonus += 1;
        _eventRewardMultiplier *= 1.35;
        _eventXpBonus += 400;
      case 'challenge_royal_guard':
        _spawnEventWave(
          count: 1,
          archetypeId: config.battlefield == BattlefieldType.evacuation
              ? 'hunt_captain'
              : 'siege_marshal',
        );
        _spawnEventWave(count: 18, archetypeId: 'iron_guard');
        _eventGoldBonus += 1600;
        _eventXpBonus += 500;
    }
  }

  void _spawnEventWave({
    required int count,
    bool ally = false,
    String? archetypeId,
  }) {
    final archetype = archetypeId == null
        ? null
        : EnemyCatalog.byId(archetypeId);
    for (var i = 0; i < count; i++) {
      final role = archetype?.role ?? _roleForFactionIndex(i + 1);
      final hpBonus = (archetype?.hpBonus ?? 0).clamp(-8, 80).toInt();
      final maxHp = UnitRoleRules.maxHp(role) + hpBonus;
      final unit = BattleUnit(
        position: Vector2(
          ally ? 90 + _random.nextDouble() * 120 : size.x - 45,
          28 + _random.nextDouble() * math.max(80, size.y - 56),
        ),
        ally: ally,
        elite: archetype?.rank == EnemyRank.elite,
        hp: maxHp,
        maxHp: maxHp,
        playerAggro:
            !ally && (archetype?.ability == EnemyAbility.flank || i % 4 == 0),
        objectiveAggro:
            !ally &&
            (archetype?.ability == EnemyAbility.breach ||
                archetype?.ability == EnemyAbility.blast),
        role: role,
        stance: role == UnitRole.commander
            ? UnitStance.support
            : UnitStance.advance,
        squadId: 900 + _triggeredEventIds.length * 10 + i ~/ 8,
        archetype: archetype,
      );
      _units.add(unit);
    }
    _peakActiveUnits = math.max(
      _peakActiveUnits,
      _units.where((unit) => !unit.dead).length + _escortAlive,
    );
  }

  String _eventRarityLabel(BattlefieldEventRarity rarity) => switch (rarity) {
    BattlefieldEventRarity.common => '일반 전장 사건',
    BattlefieldEventRarity.special => '특수 전장 사건',
    BattlefieldEventRarity.rare => '희귀 전장 사건',
    BattlefieldEventRarity.legendary => '전설 전장 사건',
  };
}
