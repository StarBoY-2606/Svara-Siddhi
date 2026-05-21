import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlowingMandala extends StatefulWidget {
  final double size;

  const GlowingMandala({
    super.key,
    this.size = 200,
  });

  @override
  State<GlowingMandala> createState() => _GlowingMandalaState();
}

class _GlowingMandalaState extends State<GlowingMandala>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: MandalaPainter(
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class MandalaPainter extends CustomPainter {
  final double animationValue;

  MandalaPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final Offset center = Offset(centerX, centerY);
    final double maxRadius = math.min(size.width, size.height) / 2;

    final double rotationAngle1 = animationValue * 2 * math.pi;
    final double rotationAngle2 = -animationValue * 1.5 * math.pi;
    final double wavePhase = animationValue * 4 * math.pi;

    final double pulseValue =
        (math.sin(animationValue * 2 * math.pi * 3) + 1.0) / 2.0;
    final double scale = 0.95 + 0.08 * pulseValue;

    final Paint spaceGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E0F42).withOpacity(0.4),
          const Color(0xFF0F0726).withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 1.1));
    canvas.drawCircle(center, maxRadius * 1.1, spaceGlow);

    final math.Random random = math.Random(108);
    for (int i = 0; i < 20; i++) {
      double r = random.nextDouble() * maxRadius * 0.95;
      double theta = random.nextDouble() * 2 * math.pi;
      double starX = centerX + r * math.cos(theta);
      double starY = centerY + r * math.sin(theta);
      double starSize = random.nextDouble() * 1.6 + 0.4;
      double starOpacity =
          (math.sin(wavePhase + random.nextDouble() * 10) + 1) / 2;
      Paint starPaint = Paint()
        ..color = Colors.white.withOpacity(starOpacity * 0.7);
      canvas.drawCircle(Offset(starX, starY), starSize, starPaint);
    }

    final double rayPulse = 1.0 + 0.12 * pulseValue;
    final Paint rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.7 * rayPulse),
          const Color(0xFFF1C40F).withOpacity(0.25 * rayPulse),
          Colors.transparent
        ],
        stops: const [0.0, 0.25, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius * 1.1));

    for (int i = 0; i < 8; i++) {
      double angle = i * math.pi / 4;
      Path rayPath = Path();
      double rayLength = maxRadius * 1.15;
      double rayWidth = (i % 2 == 0 ? 6.5 : 4.0) * rayPulse;

      Offset pTip = Offset(centerX + rayLength * math.cos(angle),
          centerY + rayLength * math.sin(angle));
      Offset pLeft = Offset(centerX + rayWidth * math.cos(angle - math.pi / 2),
          centerY + rayWidth * math.sin(angle - math.pi / 2));
      Offset pRight = Offset(centerX + rayWidth * math.cos(angle + math.pi / 2),
          centerY + rayWidth * math.sin(angle + math.pi / 2));

      rayPath.moveTo(centerX, centerY);
      rayPath.lineTo(pLeft.dx, pLeft.dy);
      rayPath.lineTo(pTip.dx, pTip.dy);
      rayPath.lineTo(pRight.dx, pRight.dy);
      rayPath.close();

      canvas.drawPath(rayPath, rayPaint);
    }

    final double outerRadius = maxRadius * 0.82 * scale;
    final Paint outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF52C5A0), // Green (Sattva)
          Color(0xFFE8875C), // Orange (Rajas)
          Color(0xFF9B7FCC), // Purple (Tamas)
          Color(0xFF52C5A0), // Green (Sattva)
        ],
        transform: GradientRotation(rotationAngle1),
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, outerRingPaint);

    final Paint outerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
      ..shader = SweepGradient(
        colors: [
          const Color(0xFF52C5A0).withOpacity(0.4),
          const Color(0xFFE8875C).withOpacity(0.4),
          const Color(0xFF9B7FCC).withOpacity(0.4),
          const Color(0xFF52C5A0).withOpacity(0.4),
        ],
        transform: GradientRotation(rotationAngle1),
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, outerGlowPaint);

    const int outerTicks = 36;
    final Paint tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0;
    for (int i = 0; i < outerTicks; i++) {
      double angle = i * (2 * math.pi / outerTicks) + rotationAngle1;
      double r1 = outerRadius;
      double r2 = outerRadius + 4.0;
      canvas.drawLine(
        Offset(centerX + r1 * math.cos(angle), centerY + r1 * math.sin(angle)),
        Offset(centerX + r2 * math.cos(angle), centerY + r2 * math.sin(angle)),
        tickPaint,
      );
    }

    final double middleRadius = maxRadius * 0.65 * scale;
    final double innerRadius = maxRadius * 0.48 * scale;

    final Paint petalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF9B7FCC), // Purple (Tamas)
          Color(0xFF52C5A0), // Green (Sattva)
          Color(0xFFE8875C), // Orange (Rajas)
          Color(0xFF9B7FCC), // Purple (Tamas)
        ],
        transform: GradientRotation(rotationAngle2),
      ).createShader(Rect.fromCircle(center: center, radius: middleRadius));

    const int numPetals = 16;
    for (int i = 0; i < numPetals; i++) {
      double angle = i * (2 * math.pi / numPetals) + rotationAngle2;
      double startAngle = angle - (math.pi / numPetals) * 0.85;
      double endAngle = angle + (math.pi / numPetals) * 0.85;

      Offset pStart = Offset(centerX + innerRadius * math.cos(startAngle),
          centerY + innerRadius * math.sin(startAngle));
      Offset pEnd = Offset(centerX + innerRadius * math.cos(endAngle),
          centerY + innerRadius * math.sin(endAngle));
      Offset pTip = Offset(centerX + middleRadius * 1.15 * math.cos(angle),
          centerY + middleRadius * 1.15 * math.sin(angle));

      Path petalPath = Path()
        ..moveTo(pStart.dx, pStart.dy)
        ..quadraticBezierTo(
            centerX + middleRadius * 0.92 * math.cos(angle - 0.08),
            centerY + middleRadius * 0.92 * math.sin(angle - 0.08),
            pTip.dx,
            pTip.dy)
        ..quadraticBezierTo(
            centerX + middleRadius * 0.92 * math.cos(angle + 0.08),
            centerY + middleRadius * 0.92 * math.sin(angle + 0.08),
            pEnd.dx,
            pEnd.dy);

      canvas.drawPath(petalPath, petalPaint);
    }

    final Paint innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(center, innerRadius, innerRingPaint);

    const int innerPatternCount = 12;
    final Paint patternPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFF1C40F).withOpacity(0.5);

    for (int i = 0; i < innerPatternCount; i++) {
      double angle =
          i * (2 * math.pi / innerPatternCount) + rotationAngle1 * 1.2;
      double patternR = innerRadius * 0.72;
      Offset subCenter = Offset(centerX + patternR * math.cos(angle),
          centerY + patternR * math.sin(angle));

      canvas.drawCircle(subCenter, innerRadius * 0.22, patternPaint);
      canvas.drawCircle(
          subCenter, 1.5, Paint()..color = Colors.white.withOpacity(0.7));
    }

    final double maxAmplitude = maxRadius * 0.28;
    final Paint barPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint barGlowPaint = Paint()
      ..color = const Color(0xFFFBF1D5).withOpacity(0.25)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += 3.0) {
      double distanceToCenter = (x - centerX).abs();
      double envelope =
          math.exp(-math.pow(distanceToCenter / (size.width * 0.42), 2));

      double wave1 = math.sin(x * 0.15 + wavePhase * 1.8);
      double wave2 = math.cos(x * 0.08 - wavePhase * 1.0);
      double wave3 = math.sin(x * 0.35 + wavePhase * 2.8);
      double combinedNoise = (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2);

      double amplitudeFactor = 0.1 + 0.9 * combinedNoise.abs();
      double barHeight = maxAmplitude * envelope * amplitudeFactor;

      if (envelope < 0.03) {
        barHeight = 0.5;
      }

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        barGlowPaint,
      );

      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        barPaint,
      );
    }

    final double coreGlowRadius = innerRadius * 0.65;
    final Paint coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          const Color(0xFFE8C880).withOpacity(0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreGlowRadius));
    canvas.drawCircle(center, coreGlowRadius * scale, coreGlow);

    final double omSize = maxRadius * 0.52 * scale;
    final TextPainter omPainter = TextPainter(
      text: TextSpan(
        text: 'ॐ',
        style: TextStyle(
          fontSize: omSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFC8A35F), // Rich gold color matching theme
          shadows: [
            Shadow(
              color: const Color(0xFFF1C40F).withOpacity(0.85),
              blurRadius: 16 * rayPulse,
            ),
            Shadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 6 * rayPulse,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    omPainter.layout();

    final Offset textOffset = Offset(
      centerX - omPainter.width / 2,
      centerY - omPainter.height / 2,
    );

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.scale(scale);
    canvas.translate(-centerX, -centerY);
    omPainter.paint(canvas, textOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MandalaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
