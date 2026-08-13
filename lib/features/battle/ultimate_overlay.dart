part of '../../app/game_app.dart';

class UltimateOrb extends StatelessWidget {
  const UltimateOrb({
    super.key,
    required this.charge,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final double charge;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ready = enabled && charge >= 1;
    final label = !enabled
        ? 'LOCK'
        : ready
        ? '발동 가능'
        : '${(charge * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Semantics(
        button: true,
        enabled: ready,
        label: ready ? '궁극기 발동' : '궁극기 충전 $label',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: ready ? onTap : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: ready
                      ? [color.withValues(alpha: .9), const Color(0xff181022)]
                      : const [Color(0xff342640), Color(0xff111019)],
                ),
                border: Border.all(
                  color: ready ? const Color(0xffffdf86) : color,
                  width: ready ? 2.5 : 1.2,
                ),
                boxShadow: ready
                    ? [BoxShadow(color: color, blurRadius: 18, spreadRadius: 2)]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 50,
                    child: CircularProgressIndicator(
                      value: enabled ? charge.clamp(0, 1) : 0,
                      strokeWidth: 3,
                      color: const Color(0xffffdd80),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 19,
                        color: enabled ? Colors.white : Colors.white30,
                      ),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: enabled ? Colors.white : Colors.white30,
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
    );
  }
}

class UltimateCutIn extends StatelessWidget {
  const UltimateCutIn({
    super.key,
    required this.sequence,
    required this.mercenary,
    required this.onComplete,
  });

  final UltimateSequence sequence;
  final MercenarySpec mercenary;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1050),
        curve: Curves.easeOutCubic,
        onEnd: onComplete,
        builder: (context, value, _) => Stack(
          children: [
            ColoredBox(
              color: Color.lerp(
                Colors.transparent,
                const Color(0xe6080910),
                value,
              )!,
            ),
            Transform.translate(
              offset: Offset(220 * (1 - value), 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width * .62,
                  height: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.white, Colors.white],
                      stops: [0, .32, 1],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      mercenary.visual.portraitAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(-120 * (1 - value), 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 64),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIGNATURE ULTIMATE',
                          style: TextStyle(
                            color: mercenary.visual.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sequence.title,
                          style: const TextStyle(
                            color: Color(0xffffe0a0),
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 310 * value,
                          height: 2,
                          color: mercenary.visual.accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${mercenary.epithet} · ${mercenary.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
