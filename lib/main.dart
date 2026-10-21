import 'package:flutter/material.dart';
import 'package:insyte_mobile/core/database/app_database.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const VesperApp());
}
