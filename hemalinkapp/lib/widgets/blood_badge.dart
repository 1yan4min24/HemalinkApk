import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BloodBadge extends StatelessWidget {
  final String label;
  final double size;
  final Color color;
  final bool online;

  const BloodBadge({
    super.key,
    required this.label,
    this.size = 32,
    this.color = AppColors.red,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.34,
        ),
      ),
    );
    if (!online) return circle;
    return Stack(
      children: [
        circle,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
