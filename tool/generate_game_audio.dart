import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;

void main() {
  final directory = Directory('assets/audio')..createSync(recursive: true);
  _write('${directory.path}/ui_click.wav', .12, (t) {
    final envelope = math.exp(-t * 28);
    return envelope *
        (.55 * math.sin(t * 2 * math.pi * 920) +
            .25 * math.sin(t * 2 * math.pi * 1380));
  });
  _write('${directory.path}/confirm.wav', .45, (t) {
    final envelope = math.exp(-t * 5.5);
    return envelope *
        (.38 * math.sin(t * 2 * math.pi * 440) +
            .32 * math.sin(t * 2 * math.pi * 660) +
            .2 * math.sin(t * 2 * math.pi * 880));
  });
  _write('${directory.path}/battle_hit.wav', .24, (t) {
    final noise = math.sin(t * 2 * math.pi * 5100 + math.sin(t * 1700) * 4);
    return math.exp(-t * 19) *
        (.48 * math.sin(t * 2 * math.pi * (175 - 260 * t)) + .32 * noise);
  });
  _write('${directory.path}/ultimate.wav', 1.55, (t) {
    final rise = (t / .32).clamp(0.0, 1.0);
    final fall = math.exp(-math.max(0, t - .45) * 2.1);
    final sweep = 120 + 520 * t * t;
    return rise *
        fall *
        (.32 * math.sin(t * 2 * math.pi * sweep) +
            .26 * math.sin(t * 2 * math.pi * 55) +
            .18 * math.sin(t * 2 * math.pi * 880));
  });
  _write('${directory.path}/camp_loop.wav', 16, (t) {
    const notes = [110.0, 130.81, 146.83, 164.81, 146.83, 130.81, 98.0, 110.0];
    final beat = (t * .5).floor();
    final note = notes[beat % notes.length];
    final phase = (t * .5) % 1;
    final pluck = math.exp(-phase * 4.2);
    final drone =
        .12 * math.sin(t * 2 * math.pi * 55) +
        .08 * math.sin(t * 2 * math.pi * 82.41);
    final melody =
        pluck *
        (.16 * math.sin(t * 2 * math.pi * note) +
            .07 * math.sin(t * 2 * math.pi * note * 2));
    return drone + melody + .025 * math.sin(t * 2 * math.pi * .19);
  });
  _write('${directory.path}/battle_loop.wav', 12, (t) {
    const notes = [73.42, 73.42, 87.31, 98.0, 73.42, 65.41];
    final step = (t * 2).floor();
    final note = notes[step % notes.length];
    final phase = (t * 2) % 1;
    final pulse = math.exp(-phase * 7);
    final drumPhase = (t * 4) % 1;
    final drum =
        math.exp(-drumPhase * 18) *
        math.sin(t * 2 * math.pi * (72 - drumPhase * 30));
    return .22 * pulse * math.sin(t * 2 * math.pi * note) +
        .12 * math.sin(t * 2 * math.pi * note * 2) +
        .23 * drum;
  });
}

void _write(String path, double seconds, double Function(double) sample) {
  final length = (seconds * _rate).round();
  final dataBytes = length * 2;
  final bytes = ByteData(44 + dataBytes);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  text(8, 'WAVEfmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _rate, Endian.little);
  bytes.setUint32(28, _rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < length; i++) {
    final value = (sample(i / _rate).clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(44 + i * 2, value, Endian.little);
  }
  File(path).writeAsBytesSync(bytes.buffer.asUint8List(), flush: true);
}
