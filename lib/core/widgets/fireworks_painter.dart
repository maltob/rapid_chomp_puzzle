import 'dart:math';
import 'package:flutter/material.dart';

class FireworksWidget extends StatefulWidget {
  final Offset? triggerPosition;
  final Color? color;
  final VoidCallback? onFinished;

  const FireworksWidget({
    super.key,
    this.triggerPosition,
    this.color,
    this.onFinished,
  });

  @override
  State<FireworksWidget> createState() => _FireworksWidgetState();
}

class _FireworksWidgetState extends State<FireworksWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();
  double _lastValue = 0.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..addListener(() {
          final double currentValue = _controller.value;
          final double delta = currentValue - _lastValue;
          _lastValue = currentValue;

          if (delta > 0) {
            setState(() {
              for (var i = _particles.length - 1; i >= 0; i--) {
                _particles[i].update(delta);
                if (_particles[i].life <= 0) {
                  _particles.removeAt(i);
                }
              }
            });
          }

          if (_controller.isCompleted) {
            // Force cleanup of any remaining particles at the end
            if (_particles.isNotEmpty) {
              setState(() => _particles.clear());
            }
            widget.onFinished?.call();
          }
        });

    if (widget.triggerPosition != null) {
      _burst(widget.triggerPosition!);
    }
  }

  @override
  void didUpdateWidget(FireworksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerPosition != null &&
        widget.triggerPosition != oldWidget.triggerPosition) {
      _burst(widget.triggerPosition!);
    }
  }

  void _burst(Offset position) {
    _particles.clear();
    _lastValue = 0.0;
    final List<Color> allowedColors = [
      Colors.yellow,
      Colors.orange,
      Colors.amber,
      Colors.orangeAccent,
      Colors.yellowAccent,
    ];
    final color =
        widget.color ?? allowedColors[_random.nextInt(allowedColors.length)];
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(position, color, _random));
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _FireworksPainter(_particles),
        size: const Size(150, 150),
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  double life = 1.0;
  final Color color;
  final double size;

  _Particle(Offset origin, this.color, Random random)
    : position = origin,
      size = random.nextDouble() * 4 + 2,
      velocity = Offset(
        (random.nextDouble() - 0.5) * 8,
        (random.nextDouble() - 0.5) * 8 - 2,
      );

  void update(double deltaProgress) {
    // scale deltaProgress (which goes 0->1 over 1.5s) to "frame" equivalents (approx 60fps)
    // 1.5s / (1/60s) = 90 frames equivalent over the full duration.
    final double scale = deltaProgress * 90;

    position += velocity * scale;
    velocity = Offset(velocity.dx, velocity.dy + 0.15 * scale); // Gravity
    // Fade out slightly faster than the duration to ensure cleanup (1.2x speed)
    life -= deltaProgress * 1.2;
  }
}

class _FireworksPainter extends CustomPainter {
  final List<_Particle> particles;

  _FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => true;
}
