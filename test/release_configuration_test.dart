import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('beta product identifiers version and deep links are fixed', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final xcode = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(pubspec, contains('version: 0.13.0+21'));
    expect(gradle, contains('com.roycekim.eclipsemercenaries'));
    expect(xcode, contains('com.roycekim.eclipsemercenaries'));
    expect(manifest, contains('android:label="월식 용병단"'));
    expect(manifest, contains('android:scheme="eclipsemercenaries"'));
    expect(plist, contains('<string>월식 용병단</string>'));
    expect(plist, contains('<string>eclipsemercenaries</string>'));
  });

  test('native icon splash and store draft assets are present', () {
    final assets = <String>[
      'assets/images/app_icon_master.png',
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
      'android/app/src/main/res/drawable-nodpi/launch_image.png',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
      'assets/store/screenshots/camp_2208x1242.png',
      'assets/store/screenshots/contracts_2208x1242.png',
      'assets/store/screenshots/result_2208x1242.png',
      'PRIVACY.md',
      'TERMS.md',
      'STORE_LISTING.md',
      'RELEASE_CHECKLIST.md',
    ];
    for (final path in assets) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(File(path).lengthSync(), greaterThan(0), reason: path);
    }
  });

  test('Android release is locked to immersive landscape presentation', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final lightStyle = File(
      'android/app/src/main/res/values/styles.xml',
    ).readAsStringSync();
    final darkStyle = File(
      'android/app/src/main/res/values-night/styles.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:screenOrientation="sensorLandscape"'));
    expect(
      lightStyle,
      contains('<item name="android:windowFullscreen">true</item>'),
    );
    expect(
      darkStyle,
      contains('<item name="android:windowFullscreen">true</item>'),
    );
  });

  test('generated beta item and enemy art sets are complete', () {
    final itemTiles = Directory(
      'assets/images/items',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.png'));
    final enemyTiles = Directory(
      'assets/images/enemies',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.png'));

    expect(itemTiles, hasLength(16));
    expect(enemyTiles, hasLength(18));
    expect(
      File('assets/source/generated/weapon_atlas_source.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/source/generated/enemy_atlas_source.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/source/generated/enemy_codex_variants.png').existsSync(),
      isTrue,
    );
  });

  test(
    'battle projectile atlas and recruitment hall art are production-ready',
    () {
      final projectile = File('assets/images/battlefield/projectile_atlas.png');
      final recruitment = File(
        'assets/images/recruitment/contract_hall_v2.png',
      );
      expect(projectile.existsSync(), isTrue);
      expect(recruitment.existsSync(), isTrue);

      final projectileHeader = ByteData.sublistView(
        projectile.readAsBytesSync(),
      );
      expect(projectileHeader.getUint32(16), projectileHeader.getUint32(20));
      expect(projectileHeader.getUint32(16), greaterThanOrEqualTo(1024));
      expect(
        projectileHeader.getUint8(25),
        6,
        reason: 'atlas must retain alpha',
      );

      final recruitmentHeader = ByteData.sublistView(
        recruitment.readAsBytesSync(),
      );
      final width = recruitmentHeader.getUint32(16);
      final height = recruitmentHeader.getUint32(20);
      expect(width / height, closeTo(16 / 9, .02));
    },
  );

  test(
    'release ultimate atlas is a high-resolution 4 by 2 presentation set',
    () {
      final atlas = File('assets/images/battlefield/ultimate_vfx_atlas_v2.png');
      expect(atlas.existsSync(), isTrue);
      final header = ByteData.sublistView(atlas.readAsBytesSync());
      final width = header.getUint32(16);
      final height = header.getUint32(20);
      expect(width, 2048);
      expect(height, 768);
      expect(width % 4, 0);
      expect(height % 2, 0);
      expect(width / 4 / (height / 2), closeTo(4 / 3, .001));
      expect(header.getUint8(25), 6, reason: 'VFX atlas must retain alpha');
      expect(File('tool/normalize_ultimate_vfx.py').existsSync(), isTrue);
    },
  );

  test('all mercenary battle sheets satisfy the padded frame contract', () {
    const mercenaryColumns = <String, int>{
      'luna': 8,
      'kael': 8,
      'sera': 8,
      'nyra': 7,
      'aurel': 7,
      'vesta': 7,
      'rask': 7,
      'iris': 7,
    };
    for (final entry in mercenaryColumns.entries) {
      final id = entry.key;
      final file = File('assets/images/characters/${id}_battle_sheet.png');
      expect(file.existsSync(), isTrue, reason: id);
      final bytes = file.readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 288 * entry.value, reason: '$id width');
      expect(header.getUint32(20), 1280, reason: '$id height');
      expect(bytes[25], 6, reason: '$id must be RGBA PNG');
    }
    expect(File('tool/align_battle_sheets.swift').existsSync(), isTrue);
    expect(
      File('tool/prepare_generated_battle_sheet.swift').existsSync(),
      isTrue,
    );
    expect(File('tool/normalize_battle_sheet.swift').existsSync(), isTrue);
  });

  test('all mercenary portraits use a consistent full-body 3 by 4 canvas', () {
    const portraitPaths = [
      'assets/images/luna_belhardt.png',
      'assets/images/kael_rozenfang.png',
      'assets/images/sera_inarion.png',
      'assets/images/nyra_vale_fullbody.png',
      'assets/images/aurel_hart_fullbody.png',
      'assets/images/vesta_corven_fullbody.png',
      'assets/images/rask_draven_fullbody.png',
      'assets/images/iris_noctis_fullbody.png',
      'assets/images/mercenaries/mira.png',
      'assets/images/mercenaries/garr.png',
      'assets/images/mercenaries/talia.png',
      'assets/images/mercenaries/fenn.png',
      'assets/images/mercenaries/elka.png',
      'assets/images/mercenaries/soren.png',
      'assets/images/mercenaries/corva.png',
      'assets/images/mercenaries/silas.png',
    ];
    for (final path in portraitPaths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final bytes = file.readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      final width = header.getUint32(16);
      final height = header.getUint32(20);
      expect(width * 4, height * 3, reason: '$path must be 3:4');
      expect(width, greaterThanOrEqualTo(1050), reason: path);
      expect(bytes[25], anyOf(2, 6), reason: '$path must be RGB/RGBA PNG');
    }
  });

  test('release UI, event, shop, battle VFX and audio sets are complete', () {
    const glyphs = <String>[
      'roster',
      'equipment',
      'shop',
      'missions',
      'codex',
      'map',
      'forge',
      'guild',
      'infirmary',
      'gold',
      'crystal',
      'contract',
      'assassination',
      'fortress',
      'reputation',
      'dash',
      'rally',
      'ultimate',
      'omen',
    ];
    const events = <String>[
      'reinforcements',
      'supply_wagon',
      'elite_knight',
      'wounded_commander',
      'mercenary_intervention',
      'monster_incursion',
      'red_moon',
      'royal_presence',
    ];
    const shopItems = <String>[
      'field_ration',
      'war_scrap',
      'contract_ticket',
      'field_medicine',
      'tempered_iron',
      'officer_map',
      'war_hero_contract',
      'siege_core',
      'veteran_badge',
      'contract_seal',
      'mooncloth',
      'royal_writ',
    ];
    const audio = <String>[
      'ui_click',
      'ui_back',
      'ui_error',
      'confirm',
      'purchase',
      'equip',
      'forge',
      'reward_claim',
      'choice_select',
      'battle_hit',
      'ultimate',
      'camp_loop',
      'battle_loop',
      'recruitment_loop',
      'battle_gate_loop',
      'battle_ash_loop',
      'battle_forest_loop',
      'battle_siege_loop',
      'battle_fortress_loop',
      'hit_slash_1',
      'hit_slash_2',
      'hit_slash_3',
      'hit_blunt',
      'hit_pierce',
      'hit_magic',
      'critical_hit',
      'shield_block',
      'player_hurt',
      'boss_impact',
      'enemy_defeat',
      'victory',
      'defeat',
      'retreat',
      'level_up',
      'event_common',
      'event_special',
      'event_rare',
      'event_legendary',
      'boss_phase',
      'loot_rare',
      'recruit_contract',
      'recruit_seal',
      'recruit_rarity',
      'recruit_reveal',
      'recruit_featured',
      'duplicate_convert',
      'ultimate_luna_charge',
      'ultimate_luna_impact',
      'ultimate_kael_charge',
      'ultimate_kael_impact',
      'ultimate_sera_charge',
      'ultimate_sera_impact',
      'ultimate_nyra_charge',
      'ultimate_nyra_impact',
      'ultimate_aurel_charge',
      'ultimate_aurel_impact',
      'ultimate_vesta_charge',
      'ultimate_vesta_impact',
      'ultimate_rask_charge',
      'ultimate_rask_impact',
      'ultimate_iris_charge',
      'ultimate_iris_impact',
    ];

    for (final id in glyphs) {
      final path = 'assets/images/ui/glyphs/$id.png';
      _expectProductionAsset(path, minBytes: 500);
      final bytes = File(path).readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 313, reason: '$id width');
      expect(header.getUint32(20), 313, reason: '$id height');
      expect(
        header.getUint8(25),
        6,
        reason: '$id must be RGBA; opaque square mattes are forbidden',
      );
    }
    for (final id in events) {
      _expectProductionAsset('assets/images/events/$id.png', minBytes: 10000);
    }
    for (final id in shopItems) {
      _expectProductionAsset(
        'assets/images/shop/final/$id.png',
        minBytes: 1000,
      );
    }
    _expectProductionAsset(
      'assets/images/battlefield/final_vfx_atlas.png',
      minBytes: 10000,
    );
    expect(File('tool/normalize_ui_glyphs.py').existsSync(), isTrue);
    for (final id in audio) {
      final file = File('assets/audio/$id.wav');
      expect(file.existsSync(), isTrue, reason: file.path);
      expect(file.lengthSync(), greaterThan(4096), reason: file.path);
      final header = file.readAsBytesSync().take(4).toList();
      expect(header, <int>[82, 73, 70, 70], reason: '${file.path} RIFF');
      final waveHeader = ByteData.sublistView(file.readAsBytesSync());
      expect(waveHeader.getUint16(20, Endian.little), 1, reason: file.path);
      expect(waveHeader.getUint16(22, Endian.little), 2, reason: file.path);
      expect(waveHeader.getUint32(24, Endian.little), 22050, reason: file.path);
    }
  });
}

void _expectProductionAsset(String path, {required int minBytes}) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: path);
  expect(file.lengthSync(), greaterThan(minBytes), reason: path);
}
