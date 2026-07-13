import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:guptik/screens/profilepopup/api_settings_screen.dart';
import 'package:guptik/screens/profilepopup/integrations_screen.dart';
import 'package:guptik/screens/profilepopup/profile_screen.dart';
import 'package:guptik/screens/profilepopup/referral_screen.dart';
import 'package:guptik/screens/profilepopup/facebook&instagram_screen.dart';
import 'package:guptik/screens/profilepopup/support_screen.dart';
import 'package:guptik/screens/profilepopup/webhook_configuration_screen.dart';
import 'package:guptik/screens/profilepopup/whatsapp_numbers_screen.dart';
import 'package:guptik/services/profilepopup_service/deep_link_navigator.dart';
import 'package:guptik/services/profilepopup_service/deep_link_service.dart';
import 'package:guptik/services/profilepopup_service/web_deep_link_handler.dart';
import 'package:guptik/utils/theme/theme_manager.dart';
import 'package:guptik/widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeManager.instance.init();

  debugPrint('==== APP START ====');

  // Better error handling for debugging
  if (kDebugMode) {
    // In debug mode, show detailed error information
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Widget: ${details.context}');
      debugPrint('Stack trace: ${details.stack}');

      if (details.toString().contains('ParentDataWidget')) {
        debugPrint(
          'ParentDataWidget error detected - check for Expanded/Flexible widgets outside Row/Column',
        );
        debugPrint('Full error: ${details.toString()}');
      }
      FlutterError.presentError(details);
    };
  } else {
    // Only suppress overflow errors in production
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        const SizedBox.shrink();

    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.toString().contains('RenderFlex overflowed') ||
          details.toString().contains('overflow') ||
          details.toString().contains('js_allow_interop_patch')) {
        return;
      }
      FlutterError.presentError(details);
    };
  }

  try {
    debugPrint('Initializing Supabase...');
    // Add delay for web platform to ensure JS libraries are loaded
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    debugPrint('Supabase URL: ${AppConfig.supabaseUrl}');
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: kDebugMode,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
    debugPrint('Stack: ${StackTrace.current}');
    // Continue anyway - app can work without Supabase initially
  }

  debugPrint('Running app...');


  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
  }

  Future<void> _initializeDeepLinks() async {
    try {
      if (kIsWeb) {
        // Handle web-based URL routing
        WebDeepLinkHandler.initialize();
      } else {
        // Handle mobile deep links
        await _deepLinkService.initialize(
          onLinkReceived: (Uri uri) {
            _deepLinkService.handleDeepLink(uri);
          },
        );
      }
    } catch (e) {
      // Silently handle initialization errors (e.g., on unsupported platforms)
      if (kDebugMode) {
        print('Deep link initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GupTik',
      navigatorKey: DeepLinkNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return Container();

        // AGGRESSIVE error suppression in builder
        ErrorWidget.builder = (FlutterErrorDetails details) =>
            const SizedBox.shrink();

        // Wrap everything to catch and suppress all possible errors
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: Builder(
            builder: (context) {
              try {
                return child;
              } catch (e) {
                // If any error occurs, return empty container
                return Container();
              }
            },
          ),
        );
      },
      home: const AuthWrapper(),
      routes: {
        '/api-settings': (context) => const ApiSettingsScreen(),
        '/webhook-config': (context) => const WebhookConfigurationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/whatsapp-numbers': (context) => const WhatsAppNumbersScreen(),
        '/facebook-instagram': (context) => const FacebookAndInstagramScreen(),
        '/integrations': (context) => const IntegrationsScreen(),
        '/referral': (context) => const ReferralScreen(),
        '/support': (context) => const SupportScreen(),
      },
    );
  }
}
