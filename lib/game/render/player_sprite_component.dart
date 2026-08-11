import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';

enum PlayerAnimationState { idle, walk, attack, hit, dead }

class PlayerSpriteComponent
    extends SpriteAnimationGroupComponent<PlayerAnimationState> {
  static const attackFrameCount = 6;
  static const attackStepTime = .05;
  static const attackDuration = attackFrameCount * attackStepTime;

  PlayerSpriteComponent._({
    required super.animations,
    required super.size,
    required this.groundAnchorY,
    required this.combatOriginFactor,
  }) : super(
         current: PlayerAnimationState.idle,
         anchor: Anchor(.5, groundAnchorY),
         autoResize: false,
         priority: 20,
         paint: Paint()..filterQuality = FilterQuality.none,
       );

  static const rows = 5;
  final double groundAnchorY;
  final Vector2 combatOriginFactor;

  double _lockedFor = 0;
  bool _moving = false;
  double _visualClock = 0;

  static PlayerSpriteComponent fromImage(
    Image image, {
    required double displaySize,
    required int columns,
    required List<List<int>> frameIndices,
    required double groundAnchorY,
    required Vector2 combatOriginFactor,
  }) {
    final frameSize = Vector2(image.width / columns, image.height / rows);
    SpriteAnimation animation(
      PlayerAnimationState state, {
      required double stepTime,
      bool loop = true,
      int? amount,
    }) {
      final indices = frameIndices[state.index];
      final selected = amount == null ? indices : indices.take(amount).toList();
      return SpriteAnimation.spriteList(
        selected
            .map(
              (column) => Sprite(
                image,
                srcPosition: Vector2(
                  column * frameSize.x,
                  state.index * frameSize.y,
                ),
                srcSize: frameSize,
              ),
            )
            .toList(growable: false),
        stepTime: stepTime,
        loop: loop,
      );
    }

    return PlayerSpriteComponent._(
      size: Vector2(displaySize * frameSize.x / frameSize.y, displaySize),
      groundAnchorY: groundAnchorY,
      combatOriginFactor: combatOriginFactor,
      animations: {
        PlayerAnimationState.idle: animation(
          PlayerAnimationState.idle,
          stepTime: .14,
        ),
        PlayerAnimationState.walk: animation(
          PlayerAnimationState.walk,
          stepTime: .09,
        ),
        PlayerAnimationState.attack: animation(
          PlayerAnimationState.attack,
          stepTime: attackStepTime,
          loop: false,
          // Generated sheets reserve the final two cells for lingering debris
          // or extreme follow-through poses. Returning before those frames
          // prevents a living mercenary from reading as a fallen sprite.
          amount: math.min(
            attackFrameCount,
            frameIndices[PlayerAnimationState.attack.index].length,
          ),
        ),
        PlayerAnimationState.hit: animation(
          PlayerAnimationState.hit,
          stepTime: .065,
          loop: false,
        ),
        PlayerAnimationState.dead: animation(
          PlayerAnimationState.dead,
          stepTime: .11,
          loop: false,
        ),
      },
    );
  }

  double get markerTopOffset => size.y * groundAnchorY + 7;

  Vector2 get combatOrigin =>
      Vector2(size.x * combatOriginFactor.x, size.y * combatOriginFactor.y);

  void setMoving(bool moving) {
    _moving = moving;
    if (_lockedFor <= 0 && current != PlayerAnimationState.dead) {
      _setState(moving ? PlayerAnimationState.walk : PlayerAnimationState.idle);
    }
  }

  void playAttack() =>
      _lock(PlayerAnimationState.attack, attackDuration, restart: true);

  void playHit() => _lock(PlayerAnimationState.hit, .52);

  void playDead() {
    _lockedFor = double.infinity;
    _setState(PlayerAnimationState.dead);
  }

  void _lock(
    PlayerAnimationState state,
    double seconds, {
    bool restart = false,
  }) {
    if (current == PlayerAnimationState.dead) return;
    _lockedFor = seconds;
    _setState(state, restart: restart);
  }

  void _setState(PlayerAnimationState state, {bool restart = false}) {
    if (current != state) {
      current = state;
      return;
    }
    if (restart) {
      // Non-looping attack animations otherwise remain on their final frame
      // when another equipped weapon attacks before the action lock expires.
      animationTickers?[state]?.reset();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _visualClock += dt;
    // Some generated sheets have intentionally subtle idle frames. A small
    // ground-anchored breathing motion guarantees that every mercenary reads
    // as alive without changing the authored frame coordinates.
    if (current != PlayerAnimationState.dead) {
      final cadence = _moving ? 12.0 : 4.2;
      final pulse = math.sin(_visualClock * cadence);
      final actionScale = current == PlayerAnimationState.attack ? 1.035 : 1.0;
      scale = Vector2(
        actionScale * (1 - pulse.abs() * (_moving ? .018 : .008)),
        actionScale * (1 + pulse * (_moving ? .032 : .014)),
      );
      angle = _moving ? math.sin(_visualClock * 7.0) * .012 : 0;
    } else {
      scale = Vector2.all(1);
      angle = 0;
    }
    if (!_lockedFor.isFinite || _lockedFor <= 0) return;
    _lockedFor -= dt;
    if (_lockedFor <= 0) {
      _lockedFor = 0;
      _setState(
        _moving ? PlayerAnimationState.walk : PlayerAnimationState.idle,
      );
    }
  }
}
