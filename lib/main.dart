import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app/app.dart';
import 'app/navigator_key.dart';
import 'core/api/api_client.dart';
import 'core/api/token_store.dart';
import 'core/sync/repositories/offline_queue_repository.dart';
import 'core/sync/services/sync_service.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodel/sign_in_view_model.dart';
import 'features/forms/inspection_form_repository.dart';
import 'features/forms/view_models/inspection_form_view_model.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;

  final api = ApiClient(
    tokens: SecureTokenStore(),
    onSessionExpired: () {
      appNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    },
  );
  final authService = ApiAuthService(api);

  final queue = OfflineQueueRepository();
  final sync = SyncService(
    repository: queue,
    baseUrl: api.baseUrl.replaceFirst(RegExp(r'/+$'), ''),
    asyncHeaders: api.authHeaders,
    refreshSession: api.refreshSession,
  );
  unawaited(
    sync.start().catchError((Object e) => debugPrint('Sync start failed: $e')),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<SyncService>.value(value: sync),
        ChangeNotifierProvider<SignInViewModel>(
          create: (_) => SignInViewModel(authService),
        ),
        
        ChangeNotifierProvider<InspectionFormViewModel>(
          create: (_) => InspectionFormViewModel(
            repository: InspectionFormRepository(api),
            queue: queue,
            sync: sync,
          ),
        ),
      ],
      child: const VesperApp(),
    ),
  );
}