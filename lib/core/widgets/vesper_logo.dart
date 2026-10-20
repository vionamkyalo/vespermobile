import 'package:flutter/material.dart';

class VesperLogo extends StatelessWidget {
  const VesperLogo({super.key, this.height = 44, this.showText = true});

  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/vesper-logo.png', height: height),
        if (showText) ...[
          const SizedBox(width: 8),
       
        ],
      ],
    );
  }
}