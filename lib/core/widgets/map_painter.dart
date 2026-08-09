part of '../../app/game_app.dart';

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xff25241f);
    canvas.drawRect(Offset.zero & size, bg);
    final road = Paint()
      ..color = const Color(0xff8a754e)
      ..strokeWidth = 3
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
          width: 190 + i * 13,
          height: 70 + i * 4,
        ),
        contour,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
