import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Text-based PataStay logo: a roofline "pin" mark plus the wordmark.
class PataWordmark extends StatelessWidget {
  const PataWordmark({super.key, this.size = 24, this.showMark = true, this.inverted = false});

  final double size;
  final bool showMark;

  /// Use on dark/brand-coloured backgrounds.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = inverted ? Colors.white : scheme.primary;
    final ink = inverted ? Colors.white : scheme.onSurface;
    final style = TextStyle(
      fontFamily: 'packages/patastay_core/PlusJakartaSans',
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -size * 0.03,
      height: 1,
    );

    return Semantics(
      label: 'PataStay',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMark) ...[
            _Mark(size: size * 1.15, color: primary, accent: inverted ? Colors.white : scheme.secondary),
            SizedBox(width: size * 0.3),
          ],
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Pata', style: style.copyWith(color: ink)),
              TextSpan(text: 'Stay', style: style.copyWith(color: primary)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.size, required this.color, required this.accent});

  final double size;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter(color, accent)),
    );
  }
}

/// A rounded square "home tile" with a roof cut-out and a sun dot.
class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.accent);

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * 0.28));
    canvas.drawRRect(tile, Paint()..color = color);

    final roof = Path()
      ..moveTo(s * 0.22, s * 0.55)
      ..lineTo(s * 0.5, s * 0.3)
      ..lineTo(s * 0.78, s * 0.55)
      ..lineTo(s * 0.78, s * 0.76)
      ..lineTo(s * 0.22, s * 0.76)
      ..close();
    canvas.drawPath(roof, Paint()..color = Colors.white);

    final door = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.44, s * 0.58, s * 0.12, s * 0.18),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(door, Paint()..color = color);
    canvas.drawCircle(Offset(s * 0.76, s * 0.24), s * 0.08, Paint()..color = accent == Colors.white ? Colors.white : const Color(0xFFF0A07E));
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color || oldDelegate.accent != accent;
}

/// Convenience gap widgets keep layouts on the spacing scale.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  static const xs = Gap(Space.xs);
  static const sm = Gap(Space.sm);
  static const md = Gap(Space.md);
  static const lg = Gap(Space.lg);
  static const xl = Gap(Space.xl);
  static const xxl = Gap(Space.xxl);

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}
