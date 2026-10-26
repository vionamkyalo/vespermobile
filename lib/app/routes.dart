import 'package:flutter/material.dart';

import '../features/auth/forgot_password_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/home/home_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const home = '/home';
  static const forgotPassword = '/forgot-password';

  static const inspectionForm = '/forms/inspection';
  static const violationForm = '/forms/violation';
  static const catchCheckForm = '/forms/catch-check';

  static final Map<String, WidgetBuilder> routes = {
    signIn: (_) => const SignInScreen(),
    home: (_) => const HomeShell(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
  };
}
