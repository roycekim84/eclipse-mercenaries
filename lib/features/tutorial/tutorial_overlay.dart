part of '../../app/game_app.dart';

class TutorialStepSpec {
  const TutorialStepSpec({
    required this.title,
    required this.body,
    required this.icon,
    required this.alignment,
  });
  final String title;
  final String body;
  final IconData icon;
  final Alignment alignment;
}

const tutorialSteps = <TutorialStepSpec>[
  TutorialStepSpec(
    title: '독립 용병단의 단장',
    body: '국가의 영웅이 아니라 계약의 대가로 전쟁에 참여합니다. 캠프에서 용병과 장비를 정비하세요.',
    icon: Icons.local_fire_department_outlined,
    alignment: Alignment.center,
  ),
  TutorialStepSpec(
    title: '첫 전쟁 계약',
    body: '오른쪽의 전쟁터 출전에서 계약을 고르고 권장 전투력, 목표와 보상을 확인합니다.',
    icon: Icons.gavel,
    alignment: Alignment.centerRight,
  ),
  TutorialStepSpec(
    title: '용병과 장비 선택',
    body: '출전 용병의 종족·개인 특성과 장착 무기를 조합합니다. 고유무기 공명은 특별한 궁극기를 엽니다.',
    icon: Icons.groups_2_outlined,
    alignment: Alignment.centerLeft,
  ),
  TutorialStepSpec(
    title: '살아서 보수를 받아라',
    body: '전장 사건은 위험과 보상을 바꿉니다. 불리하면 후퇴해 일부 전리품을 지키고 다음 계약을 준비하세요.',
    icon: Icons.shield_outlined,
    alignment: Alignment.center,
  ),
];

class TutorialOverlay extends StatelessWidget {
  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });
  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  @override
  Widget build(BuildContext context) {
    final item = tutorialSteps[step.clamp(0, tutorialSteps.length - 1)];
    final last = step == tutorialSteps.length - 1;
    return Positioned.fill(
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: '첫 계약 안내 ${step + 1}/${tutorialSteps.length}, ${item.title}',
        child: ColoredBox(
          color: const Color(0xbb03050a),
          child: SafeArea(
            child: Align(
              alignment: item.alignment,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GoldPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xff30263b),
                                  border: Border.all(
                                    color: const Color(0xffb28a5c),
                                  ),
                                ),
                                child: PremiumGameIcon(
                                  item.icon,
                                  color: const Color(0xffffd27c),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FIRST CONTRACT  ${step + 1}/${tutorialSteps.length}',
                                      style: const TextStyle(
                                        color: Color(0xffb99ad3),
                                        letterSpacing: 2,
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.body,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.55,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              TextButton(
                                onPressed: onSkip,
                                child: const Text('건너뛰기'),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 170,
                                child: FantasyButton(
                                  label: last ? '첫 계약 시작' : '다음',
                                  icon: last
                                      ? Icons.gavel
                                      : Icons.arrow_forward,
                                  onTap: onNext,
                                  prominent: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
