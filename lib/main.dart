import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_provider.dart';
import 'core/services/fcm_service.dart';
import 'features/notifications/notifications_provider.dart';
import 'router.dart';
import 'shared/theme/app_colors.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Hive.initFlutter();
  await Hive.openBox('app_prefs');

  await Firebase.initializeApp();
  // Only register the background handler here — permission request is deferred
  // to after the first frame to prevent a crash on Android 13+ OEM devices
  // (OnePlus/OPPO ColorOS) where the process manager kills the app when the
  // permission dialog is dismissed while Flutter's engine hasn't finished booting.
  FcmService.registerBackgroundHandler();

  runApp(const ProviderScope(child: GulfwalkinApp()));
}

class GulfwalkinApp extends ConsumerStatefulWidget {
  const GulfwalkinApp({super.key});

  @override
  ConsumerState<GulfwalkinApp> createState() => _GulfwalkinAppState();
}

class _GulfwalkinAppState extends ConsumerState<GulfwalkinApp> {
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Defer FCM init to after the first frame so the Flutter engine is fully
    // running before the notification permission dialog appears.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FcmService.init();
      if (!mounted) return;
      _initFcmListeners();
      // Re-register the FCM token on every launch for already-logged-in users.
      // Ensures tokens that failed to register (e.g. before the fcm_token→token
      // field-name fix) are corrected without requiring a re-login.
      final auth = ref.read(authProvider).valueOrNull;
      if (auth?.isAuthenticated == true) {
        FcmService.registerToken(ref.read(dioProvider));
      }
    });
  }

  void _initFcmListeners() {
    // App opened by tapping a notification from terminated state.
    // We must wait for auth to fully resolve before navigating — otherwise
    // GoRouter's in-flight redirect (/splash → /home) fires AFTER our push
    // and lands on /home, discarding the notification destination.
    final launch = FcmService.consumeLaunchMessage();
    if (launch != null) {
      ref.read(authProvider.future).then((_) {
        if (!mounted) return;
        // Small buffer so GoRouter completes its redirect animation to /home
        // before we push /jobs/:id on top of it.
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _navigateForMessage(launch);
        });
      });
    }

    // App brought to foreground by tapping a background notification.
    // Auth is already resolved here so no delay needed.
    FcmService.onNotificationTap.listen(_navigateForMessage);

    // Foreground message — show in-app banner and refresh unread count.
    FcmService.onForegroundMessage.listen((message) {
      ref.invalidate(unreadCountProvider);
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'New notification',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (message.notification?.body != null)
                Text(message.notification!.body!,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.primary,
            onPressed: () => _navigateForMessage(message),
          ),
        ),
      );
    });
  }

  /// Routes to the job detail screen for job_alert notifications,
  /// or the notifications list for everything else.
  /// Uses push() so the back button returns to the previous screen
  /// instead of exiting the app.
  void _navigateForMessage(RemoteMessage message) {
    final jobId = message.data['job_id'] as String?;
    final router = ref.read(routerProvider);

    if (jobId != null && jobId.isNotEmpty) {
      router.push('/jobs/$jobId');
    } else {
      router.push('/notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Gulfwalkin',
      theme: AppTheme.light,
      routerConfig: router,
      scaffoldMessengerKey: _scaffoldKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
