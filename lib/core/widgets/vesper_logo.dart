import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VesperLogo extends StatelessWidget {
  const VesperLogo({super.key, this.height = 32});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
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
    );
  }
}
