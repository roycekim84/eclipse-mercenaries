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
                    icon: Icons.speed_outlined,
                    title: '저사양 전투 모드',
                    description: '원거리 장식, 일반 그림자와 비핵심 VFX를 줄입니다.',
                    value: settings.performanceMode,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(performanceMode: value)),
                  ),
                  _SettingTile(
                    icon: Icons.text_increase,
                    title: '큰 글자',
                    description: '게임 UI 글자를 약 15% 확대합니다.',
                    value: settings.largeText,
                    onChanged: (value) =>
                        onChanged(settings.copyWith(largeText: value)),
                  ),
                  _ChoiceSettingTile<BattleInputMode>(
                    icon: Icons.gamepad_outlined,
                    title: '전투 이동 조작',
                    description: '손에 맞는 이동 방식을 선택합니다.',
                    value: settings.battleInputMode,
                    options: BattleInputMode.values,
                    labelFor: (value) => switch (value) {
                      BattleInputMode.hybrid => '혼합',
                      BattleInputMode.virtualStick => '가상 스틱',
                      BattleInputMode.touch => '화면 터치',
                    },
                    onChanged: (value) =>
                        onChanged(settings.copyWith(battleInputMode: value)),
                  ),
                  _ChoiceSettingTile<AutoTargetPriority>(
                    icon: Icons.filter_center_focus,
                    title: '자동 공격 우선순위',
                    description: '우선 공격할 적의 전술 기준입니다.',
                    value: settings.autoTargetPriority,
                    options: AutoTargetPriority.values,
                    labelFor: (value) => switch (value) {
                      AutoTargetPriority.nearest => '거리',
                      AutoTargetPriority.elite => '정예',
                      AutoTargetPriority.objectiveThreat => '목표 위협',
                    },
                    onChanged: (value) =>
                        onChanged(settings.copyWith(autoTargetPriority: value)),
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

class _ChoiceSettingTile<T> extends StatelessWidget {
  const _ChoiceSettingTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final T value;
  final List<T> options;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xffd8bd7b), size: 28),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    for (final option in options)
                      ChoiceChip(
                        label: Text(labelFor(option)),
                        selected: option == value,
                        onSelected: (_) => onChanged(option),
                        labelStyle: TextStyle(
                          color: option == value
                              ? const Color(0xffffe4a3)
                              : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        selectedColor: const Color(0xff5c416f),
                        backgroundColor: const Color(0xff171922),
                        side: BorderSide(
                          color: option == value
                              ? const Color(0xffd1aa58)
                              : const Color(0xff46404a),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
