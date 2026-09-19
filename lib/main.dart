import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app.dart';
import 'core/boot.dart';
import 'core/notifications/clock_reminders.dart';
import 'core/notifications/push_inbox.dart';
import 'core/settings/app_settings.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  unawaited(AppBoot.startSupabase());
  unawaited(_bootNotifications());

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  final settings = AppSettings();
  runApp(VmoStaffApp(settings: settings));
  unawaited(settings.load());
}

Future<void> _bootNotifications() async {
  await ClockReminderNotifications.bootstrap();
  await PushInbox.sync();
}
