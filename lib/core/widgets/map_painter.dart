part of '../../app/game_app.dart';

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff202620), Color(0xff29231c), Color(0xff171b1c)],
        ).createShader(bounds),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * .47, size.height),
      Paint()..color = const Color(0x24336a76),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * .54, 0, size.width * .46, size.height),
      Paint()..color = const Color(0x245f2928),
    );
    final road = Paint()
      ..color = const Color(0xffa58a56)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .62)
      ..quadraticBezierTo(
        size.width * .35,
        size.height * .05,
        size.width * .55,
        size.height * .35,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .65,
        size.width * .94,
        size.height * .2,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .49, 0)
        ..cubicTo(
          size.width * .43,
          size.height * .23,
          size.width * .59,
          size.height * .5,
          size.width * .51,
          size.height,
        ),
      Paint()
        ..color = const Color(0x99d0b46e)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    final contour = Paint()
      ..color = const Color(0x225e7a63)
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 10; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * (.1 + i * .09),
            size.height * (.25 + (i % 3) * .15),
          ),
          width: 150 + i * 11,
          height: 54 + i * 4,
        ),
        contour,
      );
    }
    final strongholds = <Offset>[
      Offset(size.width * .08, size.height * .62),
      Offset(size.width * .48, size.height * .35),
      Offset(size.width * .94, size.height * .2),
    ];
    for (final point in strongholds) {
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xffd0b56e));
      canvas.drawCircle(
        point,
        9,
        Paint()
          ..color = const Color(0x99d0b56e)
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, Color(0x99000000)],
          stops: [.55, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
