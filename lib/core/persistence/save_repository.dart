class AccountSave {
  const AccountSave({
    required this.schemaVersion,
    required this.gold,
    required this.crystals,
    required this.selectedMercenaryId,
    required this.equippedWeaponByMercenary,
  });

  factory AccountSave.initial() => const AccountSave(
    schemaVersion: currentSchemaVersion,
    gold: 45678,
    crystals: 3250,
    selectedMercenaryId: 'luna',
    equippedWeaponByMercenary: {
      'luna': 'moon_blades',
      'kael': 'blood_fang',
      'sera': 'glass_flame',
    },
  );

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int gold;
  final int crystals;
  final String selectedMercenaryId;
  final Map<String, String> equippedWeaponByMercenary;

  AccountSave copyWith({
    int? gold,
    int? crystals,
    String? selectedMercenaryId,
    Map<String, String>? equippedWeaponByMercenary,
  }) => AccountSave(
    schemaVersion: schemaVersion,
    gold: gold ?? this.gold,
    crystals: crystals ?? this.crystals,
    selectedMercenaryId: selectedMercenaryId ?? this.selectedMercenaryId,
    equippedWeaponByMercenary:
        equippedWeaponByMercenary ?? this.equippedWeaponByMercenary,
  );
}

abstract interface class SaveRepository {
  AccountSave load();
  void save(AccountSave value);
}

class InMemorySaveRepository implements SaveRepository {
  InMemorySaveRepository([AccountSave? initial])
    : _value = initial ?? AccountSave.initial();

  AccountSave _value;

  @override
  AccountSave load() => _value;

  @override
  void save(AccountSave value) => _value = value;
}
