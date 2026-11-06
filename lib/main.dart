import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'core/sync/services/connection_monitor.dart';
import 'core/sync/services/sync_service.dart';
import 'core/sync/sync_notifications.dart';
import 'features/auth/screens/sign_in_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/viewmodel/sign_in_view_model.dart';
import 'features/forms/inspection_form_repository.dart';
import 'features/forms/view_models/inspection_form_view_model.dart';
import 'features/reports/reports_repository.dart';
import 'features/reports/view_models/reports_view_model.dart';
import 'firebase_options.dart';

Future<void> setUpCrashReporting() async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Crash reporting unavailable: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  await setUpCrashReporting();

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
    baseUrl: '${api.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/api',
    asyncHeaders: api.authHeaders,
    refreshSession: api.refreshSession,
  );
  listenForSyncNotifications(sync, queue);
  unawaited(
    sync.start().catchError((Object e) => debugPrint('Sync start failed: $e')),
  );
  final connectionMonitor = ConnectionMonitor(syncNow: sync.syncNow);
  unawaited(connectionMonitor.start());

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<SyncService>.value(value: sync),
        Provider<ConnectionMonitor>.value(value: connectionMonitor),
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
        ChangeNotifierProvider<ReportsViewModel>(
          create: (context) => ReportsViewModel(
            ReportsRepository(context.read<ApiClient>()),
            queue: queue,
            syncEvents: sync.events,
          ),
        ),
      ],
      child: const VesperApp(),
    ),
  );
}