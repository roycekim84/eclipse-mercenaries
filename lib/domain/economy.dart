enum ShopCategory { general, war, honor }

enum ShopCurrency { gold, warSeal, honor }

String shopCurrencyName(ShopCurrency currency) => switch (currency) {
  ShopCurrency.gold => '골드',
  ShopCurrency.warSeal => '전쟁 인장',
  ShopCurrency.honor => '명예',
};

class ShopProductSpec {
  const ShopProductSpec({
    required this.id,
    required this.category,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.currency,
    required this.purchaseLimit,
    required this.description,
  });

  final String id;
  final ShopCategory category;
  final String itemId;
  final String name;
  final int quantity;
  final int price;
  final ShopCurrency currency;
  final int purchaseLimit;
  final String description;
}

const alphaShopProducts = <ShopProductSpec>[
  ShopProductSpec(
    id: 'ration_pack',
    category: ShopCategory.general,
    itemId: 'field_ration',
    name: '야전 식량 꾸러미',
    quantity: 2,
    price: 800,
    currency: ShopCurrency.gold,
    purchaseLimit: 3,
    description: '용병 전술 훈련에 사용하는 보급품',
  ),
  ShopProductSpec(
    id: 'scrap_crate',
    category: ShopCategory.general,
    itemId: 'war_scrap',
    name: '전장 고철 상자',
    quantity: 3,
    price: 600,
    currency: ShopCurrency.gold,
    purchaseLimit: 5,
    description: '대장간 담금질과 제작용 재료',
  ),
  ShopProductSpec(
    id: 'guild_contract',
    category: ShopCategory.general,
    itemId: 'contract_ticket',
    name: '고급 용병 계약서',
    quantity: 1,
    price: 2500,
    currency: ShopCurrency.gold,
    purchaseLimit: 1,
    description: '특별 모집 1회에 사용하는 계약서',
  ),
  ShopProductSpec(
    id: 'black_iron',
    category: ShopCategory.war,
    itemId: 'tempered_iron',
    name: '단련된 흑철',
    quantity: 1,
    price: 20,
    currency: ShopCurrency.warSeal,
    purchaseLimit: 3,
    description: '전쟁터에서 회수한 고급 강화 금속',
  ),
  ShopProductSpec(
    id: 'officer_maps',
    category: ShopCategory.war,
    itemId: 'officer_map',
    name: '장교 전술지도',
    quantity: 1,
    price: 35,
    currency: ShopCurrency.warSeal,
    purchaseLimit: 2,
    description: '고급 계약 해금에 필요한 전술 자료',
  ),
  ShopProductSpec(
    id: 'war_contract',
    category: ShopCategory.war,
    itemId: 'contract_ticket',
    name: '전쟁 영웅 계약서',
    quantity: 1,
    price: 50,
    currency: ShopCurrency.warSeal,
    purchaseLimit: 1,
    description: '전쟁 영웅 모집에 사용하는 특별 계약서',
  ),
  ShopProductSpec(
    id: 'veteran_mark',
    category: ShopCategory.honor,
    itemId: 'veteran_badge',
    name: '노병의 휘장',
    quantity: 1,
    price: 30,
    currency: ShopCurrency.honor,
    purchaseLimit: 2,
    description: '정예 용병 성장용 희귀 증표',
  ),
  ShopProductSpec(
    id: 'bloody_seal',
    category: ShopCategory.honor,
    itemId: 'contract_seal',
    name: '피 묻은 계약 인장',
    quantity: 2,
    price: 20,
    currency: ShopCurrency.honor,
    purchaseLimit: 3,
    description: '용병 승급에 사용하는 계약 증표',
  ),
  ShopProductSpec(
    id: 'mooncloth_roll',
    category: ShopCategory.honor,
    itemId: 'mooncloth',
    name: '월광천 두루마리',
    quantity: 2,
    price: 25,
    currency: ShopCurrency.honor,
    purchaseLimit: 2,
    description: '마력 장비를 보강하는 희귀 직물',
  ),
];

class RecruitmentReceipt {
  const RecruitmentReceipt({
    required this.mercenaryIds,
    required this.duplicateTokens,
    required this.crystalsSpent,
    required this.ticketsSpent,
  });
  final List<String> mercenaryIds;
  final Map<String, int> duplicateTokens;
  final int crystalsSpent;
  final int ticketsSpent;
}

abstract final class RecruitmentRules {
  static const singleCrystalCost = 300;
  static const tenCrystalCost = 2700;
  static const duplicateTokenReward = 10;
  static const _pool = ['luna', 'kael', 'sera'];

  static List<String> roll({required int startIndex, required int count}) => [
    for (var i = 0; i < count; i++)
      _pool[((startIndex + i) * 7 + 2) % _pool.length],
  ];

  static bool canRecruit({
    required int count,
    required int crystals,
    required int tickets,
  }) => count == 1
      ? tickets > 0 || crystals >= singleCrystalCost
      : count == 10 && crystals >= tenCrystalCost;
}

abstract final class ShopRules {
  static const refreshCrystalCost = 50;

  static int balanceFor(
    ShopCurrency currency, {
    required int gold,
    required int warSeals,
    required int honor,
  }) => switch (currency) {
    ShopCurrency.gold => gold,
    ShopCurrency.warSeal => warSeals,
    ShopCurrency.honor => honor,
  };

  static bool canPurchase({
    required ShopProductSpec product,
    required int balance,
    required int purchased,
  }) => balance >= product.price && purchased < product.purchaseLimit;
}

class EconomySnapshot {
  const EconomySnapshot({
    required this.day,
    required this.gold,
    required this.crystals,
    required this.warSeals,
    required this.honor,
  });

  final int day;
  final int gold;
  final int crystals;
  final int warSeals;
  final int honor;
}

class EconomySimulationResult {
  const EconomySimulationResult({required this.days});

  final List<EconomySnapshot> days;

  EconomySnapshot get finalState => days.last;
  bool get hasProgressBlock => days.any(
    (day) =>
        day.gold < 0 || day.crystals < 0 || day.warSeals < 0 || day.honor < 0,
  );
}

abstract final class BetaEconomySimulator {
  static EconomySimulationResult simulateSevenDays({
    int startingGold = 8000,
    int startingCrystals = 3250,
    int startingWarSeals = 40,
    int startingHonor = 30,
  }) {
    var gold = startingGold;
    var crystals = startingCrystals;
    var warSeals = startingWarSeals;
    var honor = startingHonor;
    final days = <EconomySnapshot>[];
    for (var day = 1; day <= 7; day++) {
      // Two ordinary contracts, one training, one forge, and planned shopping.
      gold += 6000 - 2000 - 1400 - 1200;
      warSeals += 12 - 8;
      honor += 8 - 5;
      if (day.isEven) crystals -= RecruitmentRules.singleCrystalCost;
      if (day == 7) {
        // Weekly contract bundle rewards participation without daily lock-in.
        gold += 2500;
        warSeals += 20;
        honor += 15;
      }
      days.add(
        EconomySnapshot(
          day: day,
          gold: gold,
          crystals: crystals,
          warSeals: warSeals,
          honor: honor,
        ),
      );
    }
    return EconomySimulationResult(days: List.unmodifiable(days));
  }
}
