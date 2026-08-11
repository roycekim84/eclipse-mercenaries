import 'dart:ui' as ui;

import 'package:eclipse_mercenaries/game/render/player_sprite_component.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consecutive attacks restart and always return to idle', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 60, 50),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    final image = await recorder.endRecording().toImage(60, 50);
    final component = PlayerSpriteComponent.fromImage(
      image,
      displaySize: 48,
      columns: 6,
      frameIndices: List.generate(5, (_) => [0, 1, 2, 3, 4, 5]),
      groundAnchorY: .82,
      combatOriginFactor: Vector2(.5, .5),
    );

    component.playAttack();
    component.update(.26);
    expect(component.current, PlayerAnimationState.attack);
    expect(component.animationTicker!.currentIndex, greaterThan(0));

    component.playAttack();
    expect(component.animationTicker!.currentIndex, 0);
    expect(component.animationTicker!.elapsed, 0);

    component.update(PlayerSpriteComponent.attackDuration + .01);
    expect(component.current, PlayerAnimationState.idle);
  });
}
