import 'package:flutter/material.dart';

/// Lets code outside the widget tree (the API client) navigate.
/// Pass it to MaterialApp as `navigatorKey: appNavigatorKey`.
final appNavigatorKey = GlobalKey<NavigatorState>();