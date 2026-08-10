import 'package:eclipse_mercenaries/core/platform/mobile_orientation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native mobile orientation policy allows both landscapes only', () {
    expect(MobileOrientation.landscapeOrientations, const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    expect(
      MobileOrientation.landscapeOrientations,
      isNot(contains(DeviceOrientation.portraitUp)),
    );
    expect(
      MobileOrientation.landscapeOrientations,
      isNot(contains(DeviceOrientation.portraitDown)),
    );
  });
}
