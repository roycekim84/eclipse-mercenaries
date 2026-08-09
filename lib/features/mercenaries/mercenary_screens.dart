part of '../../app/game_app.dart';

class RosterScreen extends StatelessWidget {
  const RosterScreen({super.key, required this.onBack, required this.onSelect});
  final VoidCallback onBack;
  final VoidCallback onSelect;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(title: '용병 명부', subtitle: '보유 용병  8 / 100', onBack: onBack),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const ChipLabel('전체'),
                const ChipLabel('종족'),
                const ChipLabel('직업'),
                const Spacer(),
                SmallIconButton(icon: Icons.tune, onTap: () {}),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 190,
                childAspectRatio: .78,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 8,
              itemBuilder: (_, index) => MercenaryCard(
                index: index,
                onTap: index == 0 ? onSelect : () {},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class MercenaryDetailScreen extends StatelessWidget {
  const MercenaryDetailScreen({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => DarkBackdrop(
    child: SafeArea(
      child: Column(
        children: [
          TitleBar(title: '용병 상세', subtitle: '월영의 암살자', onBack: onBack),
          Expanded(
            child: LayoutBuilder(
              builder: (_, c) => c.maxWidth < 700
                  ? ListView(
                      padding: const EdgeInsets.all(14),
                      children: const [
                        LunaPortrait(),
                        SizedBox(height: 12),
                        LunaStats(),
                      ],
                    )
                  : const Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: LunaPortrait()),
                          SizedBox(width: 14),
                          Expanded(flex: 4, child: LunaStats()),
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

class LunaPortrait extends StatelessWidget {
  const LunaPortrait({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 3 / 4,
    child: GoldPanel(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/luna_belhardt.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xee080a10)],
                stops: [.56, 1],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUNA BELHARDT',
                  style: TextStyle(
                    color: Color(0xffd8bd7d),
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  '루나 벨하르트',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  '★★★★★  묘족 / 암살자',
                  style: TextStyle(color: Color(0xffffcf67)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class LunaStats extends StatelessWidget {
  const LunaStats({super.key});
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Lv.45 / 60', style: TextStyle(color: Color(0xff87b9d5))),
              Spacer(),
              Text(
                '전투력  28,450',
                style: TextStyle(
                  color: Color(0xffffcf67),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Meter(value: .62, color: Color(0xff4f97bd)),
          const SizedBox(height: 18),
          ...const [
            ('HP', '12,350'),
            ('공격력', '2,145'),
            ('방어력', '1,095'),
            ('치명타', '32.5%'),
            ('회피', '24.1%'),
            ('공격속도', '1.48'),
          ].map((e) => StatRow(e.$1, e.$2)),
          const Divider(color: Color(0xff5e5038)),
          const Text(
            '고유 특성 · 야행성',
            style: TextStyle(
              color: Color(0xffffd27c),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '밤 전장에서 공격속도 20% 증가, 치명타 확률 15% 증가',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff17121d),
              border: Border.all(color: const Color(0xff725684)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high, color: Color(0xffbda2d4)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '월광쌍검',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '고유 장비 · 궁극기 활성화',
                        style: TextStyle(
                          color: Color(0xffc9a9df),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
