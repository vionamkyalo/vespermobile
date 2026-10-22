import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes.dart';
import '../features/forms/inspection_form_screen.dart';
import '../features/home/home_shell.dart';


class VesperApp extends StatelessWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
      // initialRoute: AppRoutes.signIn,
      routes: AppRoutes.routes,
    );
  }
}