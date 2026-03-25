import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'bounce_button.dart';

class FavoriteHeartButton extends StatefulWidget {
  const FavoriteHeartButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.size = 34,
  });

  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animate() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.isFavorite ? Icons.favorite : Icons.favorite_border;
    final color = widget.isFavorite ? AppColors.accentOrange : AppColors.textBase;

    return SizedBox(
      width: 48,
      height: 48,
      child: BounceButton(
        onTap: () {
          _animate();
          widget.onToggle();
        },
        child: AnimatedBuilder(
          animation: _scale,
          builder: (context, child) {
            return Transform.scale(
              scale: _scale.value,
              child: Icon(icon, size: widget.size, color: color),
            );
          },
        ),
      ),
    );
  }
}

