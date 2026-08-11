import 'dart:ui';

import 'package:flame/components.dart';

enum PlayerAnimationState { idle, walk, attack, hit, dead }

class PlayerSpriteComponent
    extends SpriteAnimationGroupComponent<PlayerAnimationState> {
  PlayerSpriteComponent._({required super.animations, required super.size})
    : super(
        current: PlayerAnimationState.idle,
        anchor: const Anchor(.5, 208 / 224),
        autoResize: false,
        priority: 20,
        paint: Paint()..filterQuality = FilterQuality.none,
      );

  static const columns = 8;
  static const rows = 5;
  static const groundAnchorY = 208 / 224;

  double _lockedFor = 0;
  bool _moving = false;

  static PlayerSpriteComponent fromImage(
    Image image, {
    required double displaySize,
  }) {
    final frameSize = Vector2(image.width / columns, image.height / rows);
    SpriteAnimation animation(
      PlayerAnimationState state, {
      required double stepTime,
      bool loop = true,
    }) {
      return SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: columns,
          stepTime: stepTime,
          textureSize: frameSize,
          texturePosition: Vector2(0, state.index * frameSize.y),
          loop: loop,
        ),
      );
    }

    return PlayerSpriteComponent._(
      size: Vector2.all(displaySize),
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
          stepTime: .055,
          loop: false,
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

  Vector2 get combatOrigin => Vector2(0, -size.y * .38);

  void setMoving(bool moving) {
    _moving = moving;
    if (_lockedFor <= 0 && current != PlayerAnimationState.dead) {
      _setState(moving ? PlayerAnimationState.walk : PlayerAnimationState.idle);
    }
  }

  void playAttack() => _lock(PlayerAnimationState.attack, .44);

  void playHit() => _lock(PlayerAnimationState.hit, .52);

  void playDead() {
    _lockedFor = double.infinity;
    _setState(PlayerAnimationState.dead);
  }

  void _lock(PlayerAnimationState state, double seconds) {
    if (current == PlayerAnimationState.dead) return;
    _lockedFor = seconds;
    _setState(state);
  }

  void _setState(PlayerAnimationState state) {
    if (current != state) current = state;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_lockedFor.isFinite || _lockedFor <= 0) return;
    _lockedFor -= dt;
    if (_lockedFor <= 0) {
      _setState(
        _moving ? PlayerAnimationState.walk : PlayerAnimationState.idle,
      );
    }
  }
}
