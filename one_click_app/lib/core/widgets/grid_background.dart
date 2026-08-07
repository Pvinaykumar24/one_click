import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeoGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSpacing;

  NeoGridPainter({
    this.gridColor = const Color(0x1F000000), // Subtle 12% opacity black grid lines
    this.gridSpacing = 24.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeoGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor || oldDelegate.gridSpacing != gridSpacing;
}

class NeoMotionBackground extends StatefulWidget {
  final Widget child;
  final bool showGrid;

  const NeoMotionBackground({
    super.key,
    required this.child,
    this.showGrid = true,
  });

  @override
  State<NeoMotionBackground> createState() => _NeoMotionBackgroundState();
}

class _NeoMotionBackgroundState extends State<NeoMotionBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Grid Pattern
          if (widget.showGrid)
            Positioned.fill(
              child: CustomPaint(
                painter: NeoGridPainter(),
              ),
            ),

          // Floating Animated Shapes
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final dy1 = math.sin(val * math.pi * 2) * 12.0;
              final dy2 = math.cos(val * math.pi * 2) * 16.0;

              return Stack(
                children: [
                  // Floating Shape 1: Top Right Pink Star/Badge
                  Positioned(
                    top: 60 + dy1,
                    right: -20,
                    child: Opacity(
                      opacity: 0.25,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.neoPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2.5),
                        ),
                      ),
                    ),
                  ),

                  // Floating Shape 2: Mid Left Cyan Square
                  Positioned(
                    top: 320 + dy2,
                    left: -25,
                    child: Transform.rotate(
                      angle: val * 0.4,
                      child: Opacity(
                        opacity: 0.25,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.neoCyan,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black, width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Shape 3: Bottom Right Yellow Diamond
                  Positioned(
                    bottom: 120 - dy1,
                    right: 30,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Opacity(
                        opacity: 0.3,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.neoYellow,
                            border: Border.all(color: Colors.black, width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Foreground Content
          widget.child,
        ],
      ),
    );
  }
}
