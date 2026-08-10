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

    expect(pubspec, contains('version: 0.9.0+9'));
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
    expect(enemyTiles, hasLength(9));
    expect(
      File('assets/source/generated/weapon_atlas_source.png').existsSync(),
      isTrue,
    );
    expect(
      File('assets/source/generated/enemy_atlas_source.png').existsSync(),
      isTrue,
    );
  });

  test('all mercenary battle sheets satisfy the Flame 8 by 5 contract', () {
    const mercenaryIds = [
      'luna',
      'kael',
      'sera',
      'nyra',
      'aurel',
      'vesta',
      'rask',
      'iris',
    ];
    for (final id in mercenaryIds) {
      final file = File('assets/images/characters/${id}_battle_sheet.png');
      expect(file.existsSync(), isTrue, reason: id);
      final bytes = file.readAsBytesSync();
      final header = ByteData.sublistView(bytes);
      expect(header.getUint32(16), 1584, reason: '$id width');
      expect(header.getUint32(20), 990, reason: '$id height');
      expect(bytes[25], 6, reason: '$id must be RGBA PNG');
    }
  });
}
