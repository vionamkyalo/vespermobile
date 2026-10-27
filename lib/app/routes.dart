import 'package:flutter/material.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/sign_in_screen.dart';
import '../features/forms/catch_check_form_screen.dart';
import '../features/forms/inspection_form_screen.dart';
import '../features/forms/violation_form_screen.dart';
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
  forgotPassword: (_) => const ForgotPasswordScreen(),
  home: (_) => const HomeShell(),
  inspectionForm: (_) => const InspectionFormScreen(),
  violationForm: (_) => const ViolationFormScreen(),
  catchCheckForm: (_) => const CatchCheckFormScreen(),
};
}