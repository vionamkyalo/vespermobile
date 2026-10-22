import 'package:flutter/material.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/forms/catch_check_form_screen.dart';
import '../features/forms/inspection_form_screen.dart';
import '../features/forms/violation_form_screen.dart';
import '../features/home/home_shell.dart';
import '../features/auth/forgot_password_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const home = '/home';
  static const inspectionForm = '/forms/inspection';
  static const violationForm = '/forms/violation';
  static const catchCheckForm = '/forms/catch-check';
  static const forgotPassword = '/forgot-password';

  static final Map<String, WidgetBuilder> routes = {
    signIn: (_) => const SignInScreen(),
    home: (_) => const HomeShell(),
    inspectionForm: (_) => const InspectionFormScreen(),
    violationForm: (_) => const ViolationFormScreen(),
    catchCheckForm: (_) => const CatchCheckFormScreen(),
    forgotPassword: (_) => const ForgotPasswordScreen(),
  };
}
