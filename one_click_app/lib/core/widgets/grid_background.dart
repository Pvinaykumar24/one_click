import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeoGridPainter extends CustomPainter {
  final Color gridColor;
  final double gridSpacing;
  final double offsetAnimation;

  NeoGridPainter({
    this.gridColor = const Color(0x2B000000), // Vibrant 17% black grid lines
    this.gridSpacing = 24.0,
    this.offsetAnimation = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final offsetX = (offsetAnimation * gridSpacing) % gridSpacing;
    final offsetY = (offsetAnimation * gridSpacing) % gridSpacing;

    for (double x = -gridSpacing + offsetX; x < size.width + gridSpacing; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -gridSpacing + offsetY; y < size.height + gridSpacing; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeoGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridSpacing != gridSpacing ||
      oldDelegate.offsetAnimation != offsetAnimation;
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
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Animated Grid & Motion Shapes
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _controller.value;
              final dy1 = math.sin(val * math.pi * 2) * 16.0;
              final dy2 = math.cos(val * math.pi * 2) * 20.0;

              return Stack(
                children: [
                  // Animated Moving Grid Pattern
                  if (widget.showGrid)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: NeoGridPainter(
                          offsetAnimation: val,
                        ),
                      ),
                    ),

                  // Floating Motion Shape 1: Top Right Pink Badge
                  Positioned(
                    top: 50 + dy1,
                    right: -15,
                    child: Opacity(
                      opacity: 0.35,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.neoPink,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Motion Shape 2: Mid Left Rotating Cyan Card
                  Positioned(
                    top: 300 + dy2,
                    left: -20,
                    child: Transform.rotate(
                      angle: val * math.pi * 2,
                      child: Opacity(
                        opacity: 0.35,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AppColors.neoCyan,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Motion Shape 3: Bottom Right Yellow Diamond
                  Positioned(
                    bottom: 110 - dy1,
                    right: 25,
                    child: Transform.rotate(
                      angle: math.pi / 4 + (val * 0.5),
                      child: Opacity(
                        opacity: 0.4,
                        child: Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: AppColors.neoYellow,
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                            ],
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
