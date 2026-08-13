part of '../../app/game_app.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.gold,
    required this.crystals,
    required this.warSeals,
    required this.honor,
    required this.inventory,
    required this.purchaseCounts,
    required this.refreshCount,
    required this.notice,
    required this.onPurchase,
    required this.onRefresh,
    required this.onBack,
  });
  final int gold;
  final int crystals;
  final int warSeals;
  final int honor;
  final Map<String, int> inventory;
  final Map<String, int> purchaseCounts;
  final int refreshCount;
  final String? notice;
  final ValueChanged<ShopProductSpec> onPurchase;
  final VoidCallback onRefresh;
  final VoidCallback onBack;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ShopCategory category = ShopCategory.general;
  late DateTime _clock = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _clock = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _rotationCountdown {
    final nextBlockHour = ((_clock.hour ~/ 6) + 1) * 6;
    final next = nextBlockHour >= 24
        ? DateTime(_clock.year, _clock.month, _clock.day + 1)
        : DateTime(_clock.year, _clock.month, _clock.day, nextBlockHour);
    final remaining = next.difference(_clock);
    final hours = remaining.inHours.toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final products = alphaShopProducts
        .where((item) => item.category == category)
        .toList();
    return DarkBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            TitleBar(
              title: '용병단 상점',
              subtitle: '보급 · 전쟁 · 명예 교환소',
              onBack: widget.onBack,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 5),
              child: Row(
                children: [
                  _ShopBalance(
                    icon: Icons.monetization_on_outlined,
                    label: '골드',
                    value: widget.gold,
                  ),
                  _ShopBalance(
                    icon: Icons.approval_outlined,
                    label: '전쟁 인장',
                    value: widget.warSeals,
                  ),
                  _ShopBalance(
                    icon: Icons.workspace_premium_outlined,
                    label: '명예',
                    value: widget.honor,
                  ),
                  _ShopBalance(
                    icon: Icons.diamond_outlined,
                    label: '크리스탈',
                    value: widget.crystals,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmRefresh(context),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      '갱신 ${widget.refreshCount}회 · ◆ ${ShopRules.refreshCrystalCost}',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: ShopCategory.values
                    .map(
                      (value) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _ShopCategoryTab(
                            label: _categoryName(value),
                            icon: _categoryIcon(value),
                            selected: category == value,
                            onTap: () => setState(() => category = value),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (widget.notice != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                padding: const EdgeInsets.all(8),
                color: const Color(0x553b2d18),
                child: Text(
                  widget.notice!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xffffd27c),
                    fontSize: 11,
                  ),
                ),
              ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 5, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x66211910),
                border: Border.all(color: const Color(0x996f5936)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 13,
                    color: Color(0xffd8bd7b),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '보급 교대까지 $_rotationCountdown',
                    style: const TextStyle(fontSize: 9, color: Colors.white60),
                  ),
                  const Spacer(),
                  const Text(
                    '오늘의 추천 · 계약/강화 재료 입고',
                    style: TextStyle(fontSize: 9, color: Color(0xffffd27c)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: GameStatePanel(
                          icon: Icons.storefront_outlined,
                          title: '입고 대기 중',
                          message: '이 교환소에는 현재 구매 가능한 보급품이 없습니다.',
                          actionLabel: '목록 갱신',
                          onAction: widget.onRefresh,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 360,
                        mainAxisExtent: MediaQuery.sizeOf(context).height < 500
                            ? 140
                            : 190,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        final purchased =
                            widget.purchaseCounts[product.id] ?? 0;
                        final soldOut = purchased >= product.purchaseLimit;
                        return _ShopProductCard(
                          product: product,
                          purchased: purchased,
                          soldOut: soldOut,
                          owned: widget.inventory[product.itemId] ?? 0,
                          onTap: () => _confirmPurchase(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    ShopProductSpec product,
  ) async {
    final balance = ShopRules.balanceFor(
      product.currency,
      gold: widget.gold,
      warSeals: widget.warSeals,
      honor: widget.honor,
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff15171d),
        title: Text('${product.name} 구매'),
        content: Text(
          '${product.name} ×${product.quantity}\n가격: ${shopCurrencyName(product.currency)} ${product.price}\n구매 후 잔액: ${balance - product.price}',
          style: const TextStyle(height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onPurchase(product);
            },
            child: const Text('구매 확정'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRefresh(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xff15171d),
        title: const Text('상점 목록 갱신'),
        content: const Text('크리스탈 50개를 사용해 모든 상점의 구매 한도를 초기화합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onRefresh();
            },
            child: const Text('갱신'),
          ),
        ],
      ),
    );
  }
}

class _ShopBalance extends StatelessWidget {
  const _ShopBalance({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 7),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xcc11141a),
      border: Border.all(color: const Color(0xff584b35)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xffd8bd7b)),
        const SizedBox(width: 5),
        Text('$label $value', style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}

class _ShopCategoryTab extends StatelessWidget {
  const _ShopCategoryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      decoration: BoxDecoration(
        color: selected ? const Color(0xff233f60) : const Color(0xff211a15),
        border: Border.all(
          color: selected ? const Color(0xff8bb0d2) : const Color(0xff725a35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xffd8bd7b)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ShopProductCard extends StatelessWidget {
  const _ShopProductCard({
    required this.product,
    required this.purchased,
    required this.soldOut,
    required this.owned,
    required this.onTap,
  });
  final ShopProductSpec product;
  final int purchased;
  final bool soldOut;
  final int owned;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GoldPanel(
    child: Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).height < 500 ? 8 : 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xff24202a),
                  border: Border.all(color: const Color(0xff80634a)),
                ),
                child: ClipRect(
                  child: Image.asset(
                    _shopItemArt(product.itemId),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      _itemIcon(product.itemId),
                      size: 28,
                      color: const Color(0xffc7a6df),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '×${product.quantity} · 보유 $owned',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            product.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '남은 구매 ${product.purchaseLimit - purchased}/${product.purchaseLimit}',
                style: TextStyle(
                  color: soldOut ? Colors.redAccent : Colors.white54,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 130,
                child: FantasyButton(
                  label: soldOut
                      ? '품절'
                      : '${shopCurrencyName(product.currency)} ${product.price}',
                  icon: soldOut ? Icons.block : Icons.shopping_cart_outlined,
                  onTap: soldOut ? () {} : onTap,
                  prominent: !soldOut,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _categoryName(ShopCategory category) => switch (category) {
  ShopCategory.general => '일반 상점',
  ShopCategory.war => '전쟁 상점',
  ShopCategory.honor => '명예 상점',
};
IconData _categoryIcon(ShopCategory category) => switch (category) {
  ShopCategory.general => Icons.storefront_outlined,
  ShopCategory.war => Icons.shield_outlined,
  ShopCategory.honor => Icons.workspace_premium_outlined,
};
IconData _itemIcon(String id) => switch (id) {
  'field_ration' => Icons.restaurant,
  'war_scrap' => Icons.build_outlined,
  'contract_ticket' => Icons.description_outlined,
  'tempered_iron' => Icons.hexagon_outlined,
  'officer_map' => Icons.map_outlined,
  'veteran_badge' => Icons.military_tech_outlined,
  'contract_seal' => Icons.approval_outlined,
  'mooncloth' => Icons.nights_stay_outlined,
  'field_medicine' => Icons.medical_services_outlined,
  'siege_core' => Icons.settings_suggest_outlined,
  'royal_writ' => Icons.history_edu_outlined,
  _ => Icons.inventory_2_outlined,
};

String _shopItemArt(String id) => switch (id) {
  'field_ration' => 'assets/images/shop/final/field_ration.png',
  'war_scrap' => 'assets/images/shop/final/war_scrap.png',
  'contract_ticket' => 'assets/images/shop/final/contract_ticket.png',
  'field_medicine' => 'assets/images/shop/final/field_medicine.png',
  'tempered_iron' => 'assets/images/shop/final/tempered_iron.png',
  'officer_map' => 'assets/images/shop/final/officer_map.png',
  'war_hero_contract' => 'assets/images/shop/final/war_hero_contract.png',
  'siege_core' => 'assets/images/shop/final/siege_core.png',
  'veteran_badge' => 'assets/images/shop/final/veteran_badge.png',
  'contract_seal' => 'assets/images/shop/final/contract_seal.png',
  'mooncloth' => 'assets/images/shop/final/mooncloth.png',
  'royal_writ' => 'assets/images/shop/final/royal_writ.png',
  _ => 'assets/images/shop/final/war_scrap.png',
};
