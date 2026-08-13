import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eclipse_mercenaries/game/survivor_game.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

int _visiblePixels(ByteDataView pixels, ui.Rect source, int imageWidth) {
  var visible = 0;
  for (var y = source.top.toInt(); y < source.bottom.toInt(); y++) {
    for (var x = source.left.toInt(); x < source.right.toInt(); x++) {
      if (pixels.data.getUint8((y * imageWidth + x) * 4 + 3) > 16) visible++;
    }
  }
  return visible;
}

int _visibleBorderPixels(
  ByteDataView pixels,
  ui.Rect source,
  int imageWidth,
  int border,
) {
  var visible = 0;
  for (var y = source.top.toInt(); y < source.bottom.toInt(); y++) {
    for (var x = source.left.toInt(); x < source.right.toInt(); x++) {
      final edge =
          x < source.left + border ||
          x >= source.right - border ||
          y < source.top + border ||
          y >= source.bottom - border;
      if (edge && pixels.data.getUint8((y * imageWidth + x) * 4 + 3) > 4) {
        visible++;
      }
    }
  }
  return visible;
}

final class ByteDataView {
  const ByteDataView(this.data);
  final ByteData data;
}

void main() {
  test(
    'all ally and enemy role cells are inside the atlas and non-empty',
    () async {
      final image = await _decode(
        'assets/images/battlefield/unit_role_batch.png',
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      final pixels = ByteDataView(data!);
      for (final source in [
        ...alliedUnitAtlasSources,
        ...enemyUnitAtlasSources,
      ]) {
        expect(source.left, greaterThanOrEqualTo(0));
        expect(source.top, greaterThanOrEqualTo(0));
        expect(source.right, lessThanOrEqualTo(image.width));
        expect(source.bottom, lessThanOrEqualTo(image.height));
        final visible = _visiblePixels(pixels, source, image.width);
        expect(
          visible / (source.width * source.height),
          greaterThan(.03),
          reason: 'role cell $source must contain a rendered unit',
        );
      }
    },
  );

  test(
    'ultimate cells keep transparent gutters without cross-cell bleeding',
    () async {
      final image = await _decode(
        'assets/images/battlefield/ultimate_vfx_atlas_v2.png',
      );
      expect(image.width, 2048);
      expect(image.height, 768);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = ByteDataView(data!);
      const cellWidth = 512.0;
      const cellHeight = 384.0;
      for (var row = 0; row < 2; row++) {
        for (var column = 0; column < 4; column++) {
          final cell = ui.Rect.fromLTWH(
            column * cellWidth,
            row * cellHeight,
            cellWidth,
            cellHeight,
          );
          expect(
            _visibleBorderPixels(pixels, cell, image.width, 12),
            0,
            reason: 'ultimate cell $column,$row must keep a clear gutter',
          );
          expect(
            _visiblePixels(pixels, cell, image.width),
            greaterThan(8000),
            reason: 'ultimate cell $column,$row must contain real VFX art',
          );
        }
      }
    },
  );
}
