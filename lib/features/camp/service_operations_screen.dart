part of '../../app/game_app.dart';

class ServiceOperationsScreen extends StatefulWidget {
  const ServiceOperationsScreen({
    super.key,
    required this.ownedMercenaries,
    required this.inventory,
    required this.skillLevels,
    required this.dispatchProgress,
    required this.injuryUntil,
    required this.activeDispatch,
    required this.notice,
    required this.onUpgrade,
    required this.onStartDispatch,
    required this.onClaimDispatch,
    required this.onBack,
  });

  final List<MercenarySpec> ownedMercenaries;
  final Map<String, int> inventory;
  final Map<String, int> skillLevels;
  final Map<String, int> dispatchProgress;
  final Map<String, int> injuryUntil;
  final ActiveDispatch? activeDispatch;
  final String? notice;
  final ValueChanged<MercenarySpec> onUpgrade;
  final void Function(DispatchMissionSpec, MercenarySpec) onStartDispatch;
  final VoidCallback onClaimDispatch;
  final VoidCallback onBack;

  @override
  State<ServiceOperationsScreen> createState() =>
      _ServiceOperationsScreenState();
}

class _ServiceOperationsScreenState extends State<ServiceOperationsScreen> {
  Timer? _timer;
  bool _supportTab = true;
  String? _selectedDispatchId;
  String? _selectedMissionId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.activeDispatch != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<MercenarySpec> get _supports => widget.ownedMercenaries
      .where((m) => m.duty == MercenaryDuty.support)
      .toList(growable: false);

  List<MercenarySpec> get _dispatches => widget.ownedMercenaries
      .where((m) => m.duty == MercenaryDuty.dispatch)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(
            title: '용병단 작전실',
            subtitle: '지원 전술을 성장시키고 후방 파견을 지휘합니다',
            onBack: widget.onBack,
          ),
          if (widget.notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: StatusBanner(message: widget.notice!),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Expanded(child: _tab('전투 지원', Icons.health_and_safety, true)),
                const SizedBox(width: 8),
                Expanded(child: _tab('후방 파견', Icons.route_outlined, false)),
              ],
            ),
          ),
          Expanded(child: _supportTab ? _supportView() : _dispatchView()),
        ],
      ),
    ),
  );

  Widget _tab(String label, IconData icon, bool support) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => setState(() => _supportTab = support),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: _supportTab == support
              ? const Color(0xff233f61)
              : const Color(0xff171820),
          border: Border.all(
            color: _supportTab == support
                ? const Color(0xffffd274)
                : const Color(0xff655337),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xffffd274), size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );

  Widget _supportView() {
    if (_supports.isEmpty) {
      return const _EmptyServiceState('지원 용병을 모집하면 전투 지원 전술이 열립니다.');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _supports.length,
      itemBuilder: (_, index) {
        final mercenary = _supports[index];
        final level = ServiceOperationRules.supportSkillLevel(
          widget.skillLevels,
          mercenary.id,
        );
        final token = widget.inventory['${mercenary.id}_token'] ?? 0;
        final cost = ServiceOperationRules.supportUpgradeTokenCost(level);
        final maxed = level >= ServiceOperationRules.maxSupportSkillLevel;
        return _ServicePanel(
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: .82,
                child: Image.asset(
                  mercenary.visual.portraitAsset,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mercenary.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${ServiceOperationRules.serviceSkillName(mercenary)} · Lv.$level',
                        style: const TextStyle(
                          color: Color(0xffffcc70),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mercenary.supportEffect,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Container(
                              width: 20,
                              height: 4,
                              margin: const EdgeInsets.only(right: 3),
                              color: i < level
                                  ? const Color(0xffb88af0)
                                  : Colors.white12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '증표 $token',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 86,
                            height: 30,
                            child: Material(
                              color: maxed
                                  ? const Color(0xff20242d)
                                  : const Color(0xff27486e),
                              child: InkWell(
                                onTap: maxed
                                    ? null
                                    : () => widget.onUpgrade(mercenary),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: maxed
                                          ? Colors.white24
                                          : const Color(0xff7394b8),
                                    ),
                                  ),
                                  child: Text(
                                    maxed ? '최대 단계' : '강화 · $cost',
                                    style: TextStyle(
                                      color: maxed
                                          ? Colors.white38
                                          : Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dispatchView() {
    final active = widget.activeDispatch;
    if (active != null) {
      return _activeDispatch(active);
    }
    if (_dispatches.isEmpty) {
      return const _EmptyServiceState('파견 용병을 모집하면 후방 작전을 시작할 수 있습니다.');
    }
    MercenarySpec? selectedMercenary;
    for (final mercenary in _dispatches) {
      if (mercenary.id == _selectedDispatchId) {
        selectedMercenary = mercenary;
      }
    }
    DispatchMissionSpec? selectedMission;
    for (final mission in ServiceOperationRules.missions) {
      if (mission.id == _selectedMissionId) {
        selectedMission = mission;
      }
    }
    return Row(
      children: [
        SizedBox(
          width: 290,
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: _dispatches.length,
            itemBuilder: (_, index) {
              final mercenary = _dispatches[index];
              final injured =
                  (widget.injuryUntil[mercenary.id] ?? 0) >
                  DateTime.now().millisecondsSinceEpoch;
              final mastery = ServiceOperationRules.dispatchMasteryLevel(
                widget.dispatchProgress[mercenary.id] ?? 0,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChoiceTile(
                  selected: _selectedDispatchId == mercenary.id,
                  enabled: !injured,
                  onTap: () =>
                      setState(() => _selectedDispatchId = mercenary.id),
                  image: mercenary.visual.portraitAsset,
                  title: mercenary.name,
                  subtitle: injured
                      ? '부상 회복 중'
                      : '파견 숙련 Lv.$mastery · ${mercenary.supportEffect}',
                ),
              );
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
            ),
            itemCount: ServiceOperationRules.missions.length,
            itemBuilder: (_, index) {
              final mission = ServiceOperationRules.missions[index];
              final selected = _selectedMissionId == mission.id;
              final chance = selectedMercenary == null
                  ? mission.baseSuccessChance
                  : ServiceOperationRules.successChance(
                      mission: mission,
                      mercenaryId: selectedMercenary.id,
                      completed:
                          widget.dispatchProgress[selectedMercenary.id] ?? 0,
                    );
              return _ServicePanel(
                selected: selected,
                onTap: () => setState(() => _selectedMissionId = mission.id),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: Color(0xffffcc70),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              mission.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${mission.durationSeconds ~/ 60}:${(mission.durationSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                      Text(
                        '${mission.region} · ${ServiceOperationRules.riskLabel(mission.risk)}',
                        style: const TextStyle(
                          color: Color(0xff83c8ba),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        mission.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            '성공 $chance%',
                            style: const TextStyle(
                              color: Color(0xffffcc70),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${mission.gold} G · 전리품 ${mission.itemAmount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: 210,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FantasyButton(
                  label: selectedMercenary == null || selectedMission == null
                      ? '용병·임무 선택'
                      : '파견 출발',
                  icon: Icons.outbound_outlined,
                  prominent: true,
                  onTap: selectedMercenary == null || selectedMission == null
                      ? null
                      : () => widget.onStartDispatch(
                          selectedMission!,
                          selectedMercenary!,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeDispatch(ActiveDispatch active) {
    final mission = ServiceOperationRules.missions.firstWhere(
      (m) => m.id == active.missionId,
    );
    final mercenary = widget.ownedMercenaries.firstWhere(
      (m) => m.id == active.mercenaryId,
    );
    final remaining = active.remainingAt(DateTime.now());
    final complete = remaining == Duration.zero;
    final progress =
        (1 - remaining.inMilliseconds / (active.durationSeconds * 1000)).clamp(
          0.0,
          1.0,
        );
    return Center(
      child: SizedBox(
        width: 720,
        child: _ServicePanel(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Image.asset(
                    mercenary.visual.portraitAsset,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE DISPATCH',
                        style: TextStyle(
                          color: Color(0xff83c8ba),
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        mission.name,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${mercenary.name} · ${mission.region}',
                        style: const TextStyle(color: Color(0xffffcc70)),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        color: const Color(0xff83c8ba),
                        backgroundColor: Colors.black45,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        complete
                            ? '귀환 보고가 도착했습니다.'
                            : '남은 시간 ${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                      const SizedBox(height: 14),
                      FantasyButton(
                        label: complete ? '파견 보고 수령' : '작전 진행 중',
                        icon: complete
                            ? Icons.inventory_2_outlined
                            : Icons.hourglass_bottom,
                        prominent: complete,
                        onTap: complete ? widget.onClaimDispatch : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicePanel extends StatelessWidget {
  const _ServicePanel({required this.child, this.selected = false, this.onTap});
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xee171920),
          border: Border.all(
            color: selected ? const Color(0xffffcf70) : const Color(0xff655337),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x447956a0), blurRadius: 14)]
              : null,
        ),
        child: child,
      ),
    ),
  );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.image,
    required this.title,
    required this.subtitle,
  });
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final String image;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .48,
    child: _ServicePanel(
      selected: selected,
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 84,
        child: Row(
          children: [
            SizedBox(width: 68, child: Image.asset(image, fit: BoxFit.cover)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
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
  );
}

class _EmptyServiceState extends StatelessWidget {
  const _EmptyServiceState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: GameStatePanel(
      icon: Icons.assignment_ind_outlined,
      title: '배치 가능한 용병 없음',
      message: message,
    ),
  );
}
