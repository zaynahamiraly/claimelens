import 'package:flutter/material.dart';

class ClaimLensLogo extends StatelessWidget {
  const ClaimLensLogo({super.key, this.size = 64});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child:
          CustomPaint(size: Size.square(size), painter: const _LogoPainter()));
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & size, Radius.circular(side * .24)),
        Paint()..color = const Color(0xff006d77));
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * .073
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(side * .438, side * .438), side * .214, white);
    canvas.drawLine(Offset(side * .625, side * .625),
        Offset(side * .802, side * .802), white);
    final mint = Paint()..color = const Color(0xff8de2d7);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(side * .438, side * .438),
            width: side * .083,
            height: side * .23),
        mint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(side * .438, side * .438),
            width: side * .23,
            height: side * .083),
        mint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
