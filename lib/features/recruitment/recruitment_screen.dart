part of '../../app/game_app.dart';

enum _RecruitStage { idle, seal, reveal }

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({
    super.key,
    required this.crystals,
    required this.tickets,
    required this.recruitmentCount,
    required this.mercenaryCopies,
    required this.notice,
    required this.onRecruit,
    required this.onRoster,
    required this.onBack,
  });
  final int crystals;
  final int tickets;
  final int recruitmentCount;
  final Map<String, int> mercenaryCopies;
  final String? notice;
  final RecruitmentReceipt? Function(int count) onRecruit;
  final VoidCallback onRoster;
  final VoidCallback onBack;

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  _RecruitStage stage = _RecruitStage.idle;
  RecruitmentReceipt? receipt;

  Future<void> _recruit(int count) async {
    if (stage == _RecruitStage.seal) return;
    final result = widget.onRecruit(count);
    if (result == null) return;
    setState(() {
      receipt = result;
      stage = _RecruitStage.seal;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => stage = _RecruitStage.reveal);
  }

  void _again() => setState(() {
    stage = _RecruitStage.idle;
    receipt = null;
  });

  @override
  Widget build(BuildContext context) => SceneFrame(
    background: 'assets/images/recruitment/contract_hall_v2.png',
    child: SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xee080a10),
                    Color(0x22080a10),
                    Color(0x88080a10),
                  ],
                  stops: [0, .52, 1],
                ),
              ),
            ),
          ),
          Column(
            children: [
              TitleBar(
                title: '특별 용병 계약',
                subtitle: '달빛의 그림자 · 루나 보증 계약',
                onBack: widget.onBack,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  child: switch (stage) {
                    _RecruitStage.idle => _RecruitLobby(
                      key: const ValueKey('recruit-lobby'),
                      crystals: widget.crystals,
                      tickets: widget.tickets,
                      recruitmentCount: widget.recruitmentCount,
                      onSingle: () => _recruit(1),
                      onTen: () => _recruit(10),
                    ),
                    _RecruitStage.seal => const _ContractSeal(
                      key: ValueKey('contract-seal'),
                    ),
                    _RecruitStage.reveal => _RecruitReveal(
                      key: const ValueKey('recruit-reveal'),
                      receipt: receipt!,
                      onAgain: _again,
                      onRoster: widget.onRoster,
                    ),
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RecruitLobby extends StatelessWidget {
  const _RecruitLobby({
    super.key,
    required this.crystals,
    required this.tickets,
    required this.recruitmentCount,
    required this.onSingle,
    required this.onTen,
  });
  final int crystals;
  final int tickets;
  final int recruitmentCount;
  final VoidCallback onSingle;
  final VoidCallback onTen;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 500;
    final guaranteeProgress =
        recruitmentCount % RecruitmentRules.featuredGuarantee;
    return Stack(
      children: [
        Positioned(
          top: 0,
          right: 10,
          bottom: 0,
          width: MediaQuery.sizeOf(context).width * .53,
          child: IgnorePointer(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.transparent, Colors.white, Colors.white],
                stops: [0, .24, 1],
              ).createShader(bounds),
              child: Image.asset(
                gameContent.mercenaryById('luna').visual.portraitAsset,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 470,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 34 : 42,
                compact ? 12 : 22,
                18,
                compact ? 12 : 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPECIAL CONTRACT',
                    style: TextStyle(
                      color: Color(0xffb99ad3),
                      letterSpacing: 4,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 8),
                  Text(
                    '달빛의 그림자\n루나',
                    style: TextStyle(
                      fontSize: compact ? 30 : 37,
                      height: 1.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 9),
                  const Text(
                    '묘족 암살자 · 고유 특성 「야행성」\n고유무기 월광쌍검과 공명 시 궁극기 활성화',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xbb17101f),
                      border: Border.all(color: const Color(0xff8e67a5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          size: 17,
                          color: Color(0xffffd27c),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '달빛 계약 보증 · 현재 $guaranteeProgress/${RecruitmentRules.featuredGuarantee} · ${RecruitmentRules.guaranteeRemaining(recruitmentCount)}회 이내 확정',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                minHeight: 4,
                                value:
                                    guaranteeProgress /
                                    RecruitmentRules.featuredGuarantee,
                                backgroundColor: Color(0xff14121a),
                                color: Color(0xffa878c3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 22),
                  Row(
                    children: [
                      _CurrencyPill(
                        icon: Icons.description_outlined,
                        label: '계약서 $tickets',
                      ),
                      const SizedBox(width: 8),
                      _CurrencyPill(
                        icon: Icons.diamond_outlined,
                        label: '크리스탈 $crystals',
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 7 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: FantasyButton(
                          label: '1회 계약  ${tickets > 0 ? '계약서 1' : '◆ 300'}',
                          icon: Icons.edit_document,
                          onTap: onSingle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FantasyButton(
                          label: '10회 계약  ◆ 2,700',
                          icon: Icons.auto_awesome,
                          onTap: onTen,
                          prominent: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 3 : 9),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '8명 균등 순환 · 40회째 루나 보증 · 중복 증표 10개',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, color: Colors.white54),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                        ),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => const _ProbabilityDialog(),
                        ),
                        icon: const Icon(Icons.info_outline, size: 15),
                        label: const Text('확률 안내'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  const _CurrencyPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xcc10131a),
      border: Border.all(color: const Color(0xff6f5b3d)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xffd8bd7b)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _ContractSeal extends StatelessWidget {
  const _ContractSeal({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: .6, end: 1.15),
      duration: const Duration(milliseconds: 620),
      builder: (_, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: ((value - .6) / .55).clamp(0, 1), child: child),
      ),
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xaa30203e),
          border: Border.all(color: const Color(0xffffd27c), width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0xbb8e58b1), blurRadius: 55),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 62, color: Color(0xffffd27c)),
            SizedBox(height: 10),
            Text(
              '계약의 봉인이\n응답합니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, height: 1.4),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RecruitReveal extends StatelessWidget {
  const _RecruitReveal({
    super.key,
    required this.receipt,
    required this.onAgain,
    required this.onRoster,
  });
  final RecruitmentReceipt receipt;
  final VoidCallback onAgain;
  final VoidCallback onRoster;
  @override
  Widget build(BuildContext context) {
    final featured = gameContent.mercenaryById(receipt.mercenaryIds.last);
    final tokens = receipt.duplicateTokens.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xdd07080d),
        image: DecorationImage(
          image: AssetImage(featured.visual.portraitAsset),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          opacity: .13,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: GoldPanel(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        featured.visual.portraitAsset,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xf0080a10)],
                            stops: [.5, 1],
                          ),
                        ),
                      ),
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.6, end: .75),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, child) => Container(
                            width: 180 * value,
                            height: 180 * value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xffffd27c,
                                ).withValues(alpha: .45),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x998d59b2),
                                  blurRadius: 45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CONTRACT COMPLETE',
                              style: TextStyle(
                                color: Color(0xffffd27c),
                                letterSpacing: 2,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              featured.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '★★★★★ · ${featured.race} / ${featured.job}',
                              style: const TextStyle(
                                color: Color(0xffffcf67),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: GoldPanel(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '용병 계약 완료',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${receipt.mercenaryIds.length}명의 계약 결과',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const Divider(color: Color(0xff665536), height: 24),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: receipt.mercenaryIds.map((id) {
                        final mercenary = gameContent.mercenaryById(id);
                        return Container(
                          width: 68,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xff141720),
                            border: Border.all(color: mercenary.visual.accent),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: AssetImage(
                                  mercenary.visual.portraitAsset,
                                ),
                                radius: 22,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                mercenary.name.split(' ').first,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x663c2850),
                        border: Border.all(color: const Color(0xff8e67a5)),
                      ),
                      child: Text(
                        '중복 용병 변환 · 전용 증표 +$tokens',
                        style: const TextStyle(
                          color: Color(0xffd7b5eb),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FantasyButton(
                      label: '다시 모집',
                      icon: Icons.refresh,
                      onTap: onAgain,
                      prominent: true,
                    ),
                    const SizedBox(height: 8),
                    FantasyButton(
                      label: '용병 명부',
                      icon: Icons.groups_2_outlined,
                      onTap: onRoster,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityDialog extends StatelessWidget {
  const _ProbabilityDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xff15171d),
    title: const Text('계약 확률 안내'),
    content: const Text(
      '계약 풀의 8명은 정해진 균등 순환으로 등장합니다.\n40번째 계약은 루나 벨하르트로 보증됩니다.\n\n보유 용병 중복 획득 시 해당 용병 전용 증표 10개로 변환됩니다.',
      style: TextStyle(height: 1.7),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('확인'),
      ),
    ],
  );
}
