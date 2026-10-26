import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/navigator_key.dart';
import 'core/api/api_client.dart';
import 'core/api/token_store.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodel/sign_in_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(
    tokens: SecureTokenStore(),
    // Runs when the server rejects the refresh token: the session is over,
    // so send the officer back to sign in and clear the back stack.
    onSessionExpired: () {
      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    },
  );
  final authService = ApiAuthService(api);

  runApp(
    MultiProvider(
      providers: [
        // Shared by the alert screens later.
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider<SignInViewModel>(
          create: (_) => SignInViewModel(authService),
        ),
      ],
      child: const VesperApp(),
    ),
  );
}