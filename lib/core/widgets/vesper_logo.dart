import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VesperLogo extends StatelessWidget {
  const VesperLogo({
    super.key, 
    this.height = 44, 
    this.showText = true,
  });

  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/vesper-logo.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Text(
            'Vesper',
            style: TextStyle(
              color: AppColors.navy, 
              fontSize: height * 0.6, 
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'Vesper',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: height * 0.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
