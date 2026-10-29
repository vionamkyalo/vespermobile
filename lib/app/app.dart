import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/screens/session_gate.dart';
import 'navigator_key.dart';
import 'routes.dart';

class VesperApp extends StatelessWidget {
  const VesperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vesper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      home: const SessionGate(),
      routes: AppRoutes.routes,
    );
  }
}