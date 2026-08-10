import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/game_settings.dart';
import '../../domain/progression.dart';

enum SaveLoadSource { primary, backup, initial }

class AccountSave {
  const AccountSave({
    required this.schemaVersion,
    required this.gold,
    required this.crystals,
    required this.selectedMercenaryId,
    required this.equippedWeaponByMercenary,
    required this.equippedGearByMercenary,
    required this.factionReputation,
    required this.operationProgress,
    required this.mercenaryProgress,
    required this.weaponProgress,
    required this.inventory,
    required this.claimedMissionIds,
    required this.warSeals,
    required this.honor,
    required this.recruitmentCount,
    required this.mercenaryCopies,
    required this.shopPurchaseCounts,
    required this.shopRefreshCount,
    required this.settings,
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
    equippedGearByMercenary: {
      'luna:armor': 'moonweave_guard',
      'luna:accessory': 'nightfang_charm',
      'luna:tactical': 'moonstep_hook',
      'kael:armor': 'black_iron_coat',
      'kael:accessory': 'commander_medal',
      'kael:tactical': 'smoke_charge',
      'sera:armor': 'moonweave_guard',
      'sera:accessory': 'windrunner_ring',
      'sera:tactical': 'officer_map_case',
    },
    factionReputation: {
      'aurum_league': 18,
      'ember_principality': 8,
      'grey_banner': 4,
    },
    operationProgress: {
      'operation_northwall': 0,
      'operation_ashroad': 0,
      'operation_greyknife': 0,
    },
    mercenaryProgress: {
      'luna': MercenaryProgress(level: 45, xp: 0, ascension: 0),
      'kael': MercenaryProgress(level: 42, xp: 0, ascension: 0),
      'sera': MercenaryProgress(level: 40, xp: 0, ascension: 0),
    },
    weaponProgress: {
      'moon_blades': WeaponProgress(level: 1, xp: 0, stage: 1),
      'blood_fang': WeaponProgress(level: 1, xp: 0, stage: 1),
      'glass_flame': WeaponProgress(level: 1, xp: 0, stage: 1),
      'iron_sword': WeaponProgress(level: 1, xp: 0, stage: 1),
      'war_bow': WeaponProgress(level: 1, xp: 0, stage: 1),
      'ember_orb': WeaponProgress(level: 1, xp: 0, stage: 1),
      'guard_spear': WeaponProgress(level: 1, xp: 0, stage: 1),
      'shadow_knife': WeaponProgress(level: 1, xp: 0, stage: 1),
    },
    inventory: {},
    claimedMissionIds: {},
    warSeals: 120,
    honor: 80,
    recruitmentCount: 0,
    mercenaryCopies: {'luna': 1, 'kael': 1, 'sera': 1},
    shopPurchaseCounts: {},
    shopRefreshCount: 0,
    settings: GameSettings.defaults(),
  );

  static const currentSchemaVersion = 10;

  final int schemaVersion;
  final int gold;
  final int crystals;
  final String selectedMercenaryId;
  final Map<String, String> equippedWeaponByMercenary;
  final Map<String, String> equippedGearByMercenary;
  final Map<String, int> factionReputation;
  final Map<String, int> operationProgress;
  final Map<String, MercenaryProgress> mercenaryProgress;
  final Map<String, WeaponProgress> weaponProgress;
  final Map<String, int> inventory;
  final Set<String> claimedMissionIds;
  final int warSeals;
  final int honor;
  final int recruitmentCount;
  final Map<String, int> mercenaryCopies;
  final Map<String, int> shopPurchaseCounts;
  final int shopRefreshCount;
  final GameSettings settings;

  AccountSave copyWith({
    int? gold,
    int? crystals,
    String? selectedMercenaryId,
    Map<String, String>? equippedWeaponByMercenary,
    Map<String, String>? equippedGearByMercenary,
    Map<String, int>? factionReputation,
    Map<String, int>? operationProgress,
    Map<String, MercenaryProgress>? mercenaryProgress,
    Map<String, WeaponProgress>? weaponProgress,
    Map<String, int>? inventory,
    Set<String>? claimedMissionIds,
    int? warSeals,
    int? honor,
    int? recruitmentCount,
    Map<String, int>? mercenaryCopies,
    Map<String, int>? shopPurchaseCounts,
    int? shopRefreshCount,
    GameSettings? settings,
  }) => AccountSave(
    schemaVersion: currentSchemaVersion,
    gold: gold ?? this.gold,
    crystals: crystals ?? this.crystals,
    selectedMercenaryId: selectedMercenaryId ?? this.selectedMercenaryId,
    equippedWeaponByMercenary:
        equippedWeaponByMercenary ?? this.equippedWeaponByMercenary,
    equippedGearByMercenary:
        equippedGearByMercenary ?? this.equippedGearByMercenary,
    factionReputation: factionReputation ?? this.factionReputation,
    operationProgress: operationProgress ?? this.operationProgress,
    mercenaryProgress: mercenaryProgress ?? this.mercenaryProgress,
    weaponProgress: weaponProgress ?? this.weaponProgress,
    inventory: inventory ?? this.inventory,
    claimedMissionIds: claimedMissionIds ?? this.claimedMissionIds,
    warSeals: warSeals ?? this.warSeals,
    honor: honor ?? this.honor,
    recruitmentCount: recruitmentCount ?? this.recruitmentCount,
    mercenaryCopies: mercenaryCopies ?? this.mercenaryCopies,
    shopPurchaseCounts: shopPurchaseCounts ?? this.shopPurchaseCounts,
    shopRefreshCount: shopRefreshCount ?? this.shopRefreshCount,
    settings: settings ?? this.settings,
  );

  Map<String, Object> toJson() => {
    'schemaVersion': currentSchemaVersion,
    'gold': gold,
    'crystals': crystals,
    'selectedMercenaryId': selectedMercenaryId,
    'equippedWeaponByMercenary': equippedWeaponByMercenary,
    'equippedGearByMercenary': equippedGearByMercenary,
    'factionReputation': factionReputation,
    'operationProgress': operationProgress,
    'mercenaryProgress': {
      for (final entry in mercenaryProgress.entries)
        entry.key: entry.value.toJson(),
    },
    'weaponProgress': {
      for (final entry in weaponProgress.entries)
        entry.key: entry.value.toJson(),
    },
    'inventory': inventory,
    'claimedMissionIds': claimedMissionIds.toList(),
    'warSeals': warSeals,
    'honor': honor,
    'recruitmentCount': recruitmentCount,
    'mercenaryCopies': mercenaryCopies,
    'shopPurchaseCounts': shopPurchaseCounts,
    'shopRefreshCount': shopRefreshCount,
    'settings': settings.toJson(),
  };

  factory AccountSave.fromJson(Map<String, Object?> raw) {
    final migrated = SaveMigration.migrate(raw);
    final defaults = AccountSave.initial();
    return AccountSave(
      schemaVersion: currentSchemaVersion,
      gold: (migrated['gold'] as num?)?.toInt() ?? defaults.gold,
      crystals: (migrated['crystals'] as num?)?.toInt() ?? defaults.crystals,
      selectedMercenaryId:
          migrated['selectedMercenaryId'] as String? ??
          defaults.selectedMercenaryId,
      equippedWeaponByMercenary: _stringMap(
        migrated['equippedWeaponByMercenary'],
        defaults.equippedWeaponByMercenary,
      ),
      equippedGearByMercenary: _stringMap(
        migrated['equippedGearByMercenary'],
        defaults.equippedGearByMercenary,
      ),
      factionReputation: _intMap(
        migrated['factionReputation'],
        defaults.factionReputation,
      ),
      operationProgress: _intMap(
        migrated['operationProgress'],
        defaults.operationProgress,
      ),
      mercenaryProgress: _progressMap(
        migrated['mercenaryProgress'],
        defaults.mercenaryProgress,
        MercenaryProgress.fromJson,
      ),
      weaponProgress: _progressMap(
        migrated['weaponProgress'],
        defaults.weaponProgress,
        WeaponProgress.fromJson,
      ),
      inventory: _intMap(migrated['inventory']),
      claimedMissionIds: _stringSet(migrated['claimedMissionIds']),
      warSeals: (migrated['warSeals'] as num?)?.toInt() ?? defaults.warSeals,
      honor: (migrated['honor'] as num?)?.toInt() ?? defaults.honor,
      recruitmentCount: (migrated['recruitmentCount'] as num?)?.toInt() ?? 0,
      mercenaryCopies: _intMap(
        migrated['mercenaryCopies'],
        defaults.mercenaryCopies,
      ),
      shopPurchaseCounts: _intMap(migrated['shopPurchaseCounts']),
      shopRefreshCount: (migrated['shopRefreshCount'] as num?)?.toInt() ?? 0,
      settings: GameSettings.fromJson(migrated['settings']),
    );
  }

  static Set<String> _stringSet(Object? value) =>
      value is List ? value.whereType<String>().toSet() : <String>{};

  static Map<String, String> _stringMap(
    Object? value,
    Map<String, String> fallback,
  ) {
    if (value is! Map) return Map.of(fallback);
    return {
      ...fallback,
      for (final entry in value.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  static Map<String, int> _intMap(
    Object? value, [
    Map<String, int> fallback = const {},
  ]) {
    if (value is! Map) return Map.of(fallback);
    return {
      ...fallback,
      for (final entry in value.entries)
        if (entry.key is String && entry.value is num)
          entry.key as String: (entry.value as num).toInt(),
    };
  }

  static Map<String, T> _progressMap<T>(
    Object? value,
    Map<String, T> fallback,
    T Function(Map<String, Object?>) decode,
  ) {
    final result = Map<String, T>.of(fallback);
    if (value is! Map) return result;
    for (final entry in value.entries) {
      if (entry.key is String && entry.value is Map) {
        result[entry.key as String] = decode(
          Map<String, Object?>.from(entry.value as Map),
        );
      }
    }
    return result;
  }
}

abstract final class SaveMigration {
  static Map<String, Object?> migrate(Map<String, Object?> raw) {
    var current = Map<String, Object?>.from(raw);
    var version = (current['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version < 2) {
      final defaults = AccountSave.initial();
      current = {
        ...current,
        'schemaVersion': 2,
        'mercenaryProgress': {
          for (final entry in defaults.mercenaryProgress.entries)
            entry.key: entry.value.toJson(),
        },
        'weaponProgress': {
          for (final entry in defaults.weaponProgress.entries)
            entry.key: entry.value.toJson(),
        },
        'inventory': <String, int>{},
      };
      version = 2;
    }
    if (version < 3) {
      current = {
        ...current,
        'schemaVersion': 3,
        'claimedMissionIds': <String>[],
      };
      version = 3;
    }
    if (version < 4) {
      final defaults = AccountSave.initial();
      current = {
        ...current,
        'schemaVersion': 4,
        'warSeals': defaults.warSeals,
        'honor': defaults.honor,
        'recruitmentCount': 0,
        'mercenaryCopies': defaults.mercenaryCopies,
        'shopPurchaseCounts': <String, int>{},
        'shopRefreshCount': 0,
      };
      version = 4;
    }
    if (version < 5) {
      current = {
        ...current,
        'schemaVersion': 5,
        'settings': const GameSettings.defaults().toJson(),
      };
      version = 5;
    }
    if (version < 6) {
      final rawSettings = current['settings'];
      final settings = rawSettings is Map
          ? Map<String, Object?>.from(rawSettings)
          : const GameSettings.defaults().toJson();
      current = {
        ...current,
        'schemaVersion': 6,
        'settings': {...settings, 'performanceMode': false},
      };
      version = 6;
    }
    if (version < 7) {
      final rawSettings = current['settings'];
      final settings = rawSettings is Map
          ? Map<String, Object?>.from(rawSettings)
          : const GameSettings.defaults().toJson();
      current = {
        ...current,
        'schemaVersion': 7,
        'settings': {
          ...settings,
          'battleInputMode': BattleInputMode.hybrid.name,
          'autoTargetPriority': AutoTargetPriority.nearest.name,
        },
      };
      version = 7;
    }
    if (version < 8) {
      current = {
        ...current,
        'schemaVersion': 8,
        'equippedGearByMercenary':
            AccountSave.initial().equippedGearByMercenary,
      };
      version = 8;
    }
    if (version < 9) {
      current = {
        ...current,
        'schemaVersion': 9,
        'factionReputation': AccountSave.initial().factionReputation,
      };
      version = 9;
    }
    if (version < 10) {
      current = {
        ...current,
        'schemaVersion': 10,
        'operationProgress': AccountSave.initial().operationProgress,
      };
      version = 10;
    }
    if (version != AccountSave.currentSchemaVersion) {
      throw const FormatException('Unsupported save schema');
    }
    return current;
  }
}

abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}

abstract interface class SaveRepository {
  SaveLoadSource get lastLoadSource;
  Future<AccountSave> load();
  Future<void> save(AccountSave value);
  Future<AccountSave> reset();
}

class JsonSaveRepository implements SaveRepository {
  JsonSaveRepository(this._store);

  static const primaryKey = 'eclipse_mercenaries.save.v2';
  static const backupKey = 'eclipse_mercenaries.save.backup';

  final KeyValueStore _store;

  @override
  SaveLoadSource lastLoadSource = SaveLoadSource.initial;

  @override
  Future<AccountSave> load() async {
    final primary = await _decode(await _store.getString(primaryKey));
    if (primary != null) {
      lastLoadSource = SaveLoadSource.primary;
      return primary;
    }
    final backup = await _decode(await _store.getString(backupKey));
    if (backup != null) {
      lastLoadSource = SaveLoadSource.backup;
      await _store.setString(primaryKey, jsonEncode(backup.toJson()));
      return backup;
    }
    final initial = AccountSave.initial();
    lastLoadSource = SaveLoadSource.initial;
    await _store.setString(primaryKey, jsonEncode(initial.toJson()));
    return initial;
  }

  @override
  Future<void> save(AccountSave value) async {
    final current = await _store.getString(primaryKey);
    if (current != null) await _store.setString(backupKey, current);
    await _store.setString(primaryKey, jsonEncode(value.toJson()));
  }

  @override
  Future<AccountSave> reset() async {
    await _store.remove(primaryKey);
    await _store.remove(backupKey);
    return load();
  }

  Future<AccountSave?> _decode(String? encoded) async {
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      return AccountSave.fromJson(Map<String, Object?>.from(decoded));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? values])
    : values = values ?? <String, String>{};

  final Map<String, String> values;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class InMemorySaveRepository extends JsonSaveRepository {
  factory InMemorySaveRepository([AccountSave? initial]) {
    final store = MemoryKeyValueStore();
    if (initial != null) {
      store.values[JsonSaveRepository.primaryKey] = jsonEncode(
        initial.toJson(),
      );
    }
    return InMemorySaveRepository._(store);
  }

  InMemorySaveRepository._(this.store) : super(store);

  final MemoryKeyValueStore store;
}
