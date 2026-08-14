import 'package:eclipse_mercenaries/domain/battle_models.dart';
import 'package:eclipse_mercenaries/domain/service_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('service operation progression', () {
    test('support skills use bounded levels and escalating token costs', () {
      expect(ServiceOperationRules.supportSkillLevel(const {}, 'mira'), 1);
      expect(
        ServiceOperationRules.supportSkillLevel(const {'mira': 99}, 'mira'),
        5,
      );
      expect(
        List.generate(
          4,
          (index) => ServiceOperationRules.supportUpgradeTokenCost(index + 1),
        ),
        [10, 20, 30, 40],
      );
    });

    test(
      'dispatch mastery grows only across defined completion thresholds',
      () {
        expect(ServiceOperationRules.dispatchMasteryLevel(0), 1);
        expect(ServiceOperationRules.dispatchMasteryLevel(3), 2);
        expect(ServiceOperationRules.dispatchMasteryLevel(8), 3);
        expect(ServiceOperationRules.dispatchMasteryLevel(15), 4);
        expect(ServiceOperationRules.dispatchMasteryLevel(25), 5);
      },
    );

    test(
      'affinity and mastery improve mission success without exceeding cap',
      () {
        final mission = ServiceOperationRules.missions.first;
        final base = ServiceOperationRules.successChance(
          mission: mission,
          mercenaryId: 'corva',
          completed: 0,
        );
        final preferred = ServiceOperationRules.successChance(
          mission: mission,
          mercenaryId: 'talia',
          completed: 25,
        );
        expect(preferred, greaterThan(base));
        expect(preferred, lessThanOrEqualTo(98));
      },
    );

    test(
      'dispatch result is deterministic and gives no item on failed run',
      () {
        final mission = ServiceOperationRules.missions.last;
        const active = ActiveDispatch(
          missionId: 'whitewall_intelligence',
          mercenaryId: 'talia',
          startedAtEpochMs: 1,
          durationSeconds: 3600,
          seed: 5,
        );
        final first = ServiceOperationRules.resolve(
          active: active,
          mission: mission,
          completed: 0,
        );
        final second = ServiceOperationRules.resolve(
          active: active,
          mission: mission,
          completed: 0,
        );
        expect(first.success, second.success);
        expect(first.gold, second.gold);
        expect(first.event, second.event);
        if (!first.success) expect(first.itemAmount, 0);
      },
    );

    test('each contract objective has a service recommendation', () {
      for (final objective in ContractObjective.values) {
        final recommendation = ServiceOperationRules.recommendationFor(
          objective,
        );
        expect(recommendation.supportId, isNotEmpty);
        expect(recommendation.dispatchId, isNotEmpty);
      }
    });
  });

  test('active dispatch persists timing and completes at its deadline', () {
    const active = ActiveDispatch(
      missionId: 'nearby_supply_run',
      mercenaryId: 'fenn',
      startedAtEpochMs: 1000,
      durationSeconds: 300,
      seed: 9,
    );
    final restored = ActiveDispatch.fromJson(active.toJson());
    expect(restored.missionId, active.missionId);
    expect(
      restored.isCompleteAt(DateTime.fromMillisecondsSinceEpoch(300999)),
      isFalse,
    );
    expect(
      restored.isCompleteAt(DateTime.fromMillisecondsSinceEpoch(301000)),
      isTrue,
    );
  });
}
