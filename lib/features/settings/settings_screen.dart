part of '../../app/game_app.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.notice,
    required this.onChanged,
    required this.onReplayTutorial,
    required this.onBack,
  });
  final GameSettings settings;
  final String? notice;
  final ValueChanged<GameSettings> onChanged;
  final VoidCallback onReplayTutorial;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '환경 설정',
            subtitle: '접근성 · 연출 · 조작 피드백',
            onBack: onBack,
          ),
          if (notice != null) StatusBanner(message: notice!),
          Expanded(
            child: LayoutBuilder(
              builder: (_, constraints) => GridView.count(
                padding: const EdgeInsets.all(14),
                crossAxisCount: constraints.maxWidth < 700 ? 1 : 2,
                childAspectRatio: constraints.maxWidth < 700 ? 4.2 : 3.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _SettingTile(
                    icon: Icons.volume_up_outlined,
                    title: '효과음',
                    description: '전투 타격음과 UI 효과음을 재생합니다.',
                    value: settings.soundEnabled,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(soundEnabled: value)),
                  ),
                  _SettingTile(
                    icon: Icons.vibration,
                    title: '진동 피드백',
                    description: '궁극기와 중요한 선택에 진동을 사용합니다.',
                    value: settings.hapticsEnabled,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(hapticsEnabled: value)),
                  ),
                  _SettingTile(
                    icon: Icons.videocam_outlined,
                    title: '화면 흔들림',
                    description: '강한 공격의 카메라 흔들림을 허용합니다.',
                    value: settings.screenShakeEnabled,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(screenShakeEnabled: value)),
                  ),
                  _SettingTile(
                    icon: Icons.flare_outlined,
                    title: '섬광 줄이기',
                    description: '궁극기와 사건의 밝은 섬광을 완화합니다.',
                    value: settings.reducedFlash,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(reducedFlash: value)),
                  ),
                  _SettingTile(
                    icon: Icons.text_increase,
                    title: '큰 글자',
                    description: '게임 UI 글자를 약 15% 확대합니다.',
                    value: settings.largeText,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(largeText: value)),
                  ),
                  GoldPanel(
                    child: Padding(
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Color(0xffd8bd7b),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '첫 계약 안내',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '캠프와 첫 출전 흐름을 다시 확인합니다.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 145,
                            child: FantasyButton(
                              label: '안내 다시 보기',
                              icon: Icons.replay,
                              onTap: onReplayTutorial,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: '$title, ${value ? '켜짐' : '꺼짐'}',
    child: GoldPanel(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Icon(
                icon,
                color: value ? const Color(0xffd8bd7b) : Colors.white38,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                activeThumbColor: const Color(0xffffcf70),
                activeTrackColor: const Color(0xff725684),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
