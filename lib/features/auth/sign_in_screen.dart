import 'package:flutter/material.dart';

import '../../app/routes.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.violationForm),
          child: const Text('Open violation form'),
        ),
      ),
    );
  }
}