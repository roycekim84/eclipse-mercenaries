part of '../../app/game_app.dart';

class FirstDeploymentScreen extends StatelessWidget {
  const FirstDeploymentScreen({super.key, required this.onDeploy});

  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) => SceneFrame(
    background: 'assets/images/battlefield/north_gate_battlefield.png',
    child: SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xee080a12), Color(0x55101828)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 18,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * .48,
            child: Image.asset(
              gameContent.mercenaryById('luna').visual.portraitAsset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ECLIPSE MERCENARIES',
                      style: TextStyle(
                        color: Color(0xffb996d2),
                        letterSpacing: 5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '북문이 무너지고 있다',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '루나 벨하르트 · 묘족 암살자\n먼저 전장에 뛰어들어 살아남으십시오.',
                      style: TextStyle(color: Colors.white70, height: 1.55),
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: 320,
                      child: FantasyButton(
                        key: const ValueKey('first-deploy-button'),
                        label: '첫 출전',
                        icon: Icons.gavel,
                        prominent: true,
                        onTap: onDeploy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '이동만 하십시오. 공격은 루나가 알아서 합니다.',
                      style: TextStyle(color: Color(0xffd6bd81), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
