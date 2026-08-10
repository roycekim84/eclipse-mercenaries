part of '../../app/game_app.dart';

class LandscapeHintBanner extends StatelessWidget {
  const LandscapeHintBanner({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 12,
    right: 12,
    top: 12,
    child: SafeArea(
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          label: '가로 화면 권장 안내',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xf0161215),
              border: Border.all(color: const Color(0xffd0a956)),
              boxShadow: const [
                BoxShadow(color: Colors.black87, blurRadius: 14),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.screen_rotation_outlined, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '가로 화면에서 전장과 UI를 가장 선명하게 볼 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xffffdc8a)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
