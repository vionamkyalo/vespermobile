import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'features/auth/auth_repository.dart';
import 'features/forms/view_models/sign_in_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider<SignInViewModel>(
      create: (_) => SignInViewModel(DemoAuthRepository()),
      child: const VesperApp(),
    ),
  );
}
