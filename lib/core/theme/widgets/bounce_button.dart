import 'package:flutter/material.dart';

class BounceButton extends StatefulWidget {
  const BounceButton({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final Duration duration;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}

