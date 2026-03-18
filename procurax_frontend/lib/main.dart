import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

import 'pages/get_started/get_started_page.dart';
import 'pages/procurement/procurement_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/tasks/tasks_page.dart';
import 'pages/notes/notes_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/build_assist/screens/build_assist_page.dart';
import 'pages/communication/communication_page.dart';
import 'pages/meetings/features/smart_calendar/screens/meetings_page.dart';
import 'pages/sign_in/create_account_page.dart';
import 'pages/log_in/login_page.dart';
import 'pages/log_in/forgot_password_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/theme_notifier.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/notifications/providers/alert_provider.dart';
import 'widgets/auth_gate.dart';

// Global navigator key for notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await FirebaseService.initialize();

  // Then initialize API service
  await ApiService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => AlertProvider()..initialize()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            themeMode: themeNotifier.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            // ✅ Correct initial route
            initialRoute: ApiService.hasToken
                ? AppRoutes.dashboard
                : AppRoutes.getStarted,

            onGenerateRoute: (settings) {
              final routes = <String, Widget Function()>{
                AppRoutes.getStarted: () => const GetStartedPage(),
                AppRoutes.login: () => const LoginPage(),
                AppRoutes.createAccount: () => const CreateAccountPage(),
                AppRoutes.forgotPassword: () => const ForgotPasswordPage(),
                AppRoutes.procurement: () =>
                    const AuthGate(child: ProcurementSchedulePage()),
                AppRoutes.dashboard: () =>
                    const AuthGate(child: DashboardPage()),
                AppRoutes.settings: () => const AuthGate(child: SettingsPage()),
                AppRoutes.notifications: () =>
                    const AuthGate(child: NotificationsPage()),
                AppRoutes.tasks: () => const AuthGate(child: TasksPage()),
                AppRoutes.buildAssist: () =>
                    const AuthGate(child: BuildAssistPage()),
                AppRoutes.notes: () => const AuthGate(child: NotesPage()),
                AppRoutes.communication: () =>
                    const AuthGate(child: CommunicationPage()),
                AppRoutes.meetings: () => const AuthGate(child: MeetingsPage()),
                AppRoutes.documents: () =>
                    const AuthGate(child: DocumentsPage()),
              };

              final builder = routes[settings.name];
              if (builder == null) return null;

              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    builder(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const curve = Curves.easeInOutCubic;
                      final fadeAnim = CurvedAnimation(
                        parent: animation,
                        curve: curve,
                      );
                      final slideAnim = Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(fadeAnim);
                      return FadeTransition(
                        opacity: fadeAnim,
                        child: SlideTransition(
                          position: slideAnim,
                          child: child,
                        ),
                      );
                    },
                transitionDuration: AppAnimations.normal,
                reverseTransitionDuration: AppAnimations.fast,
              );
            },
          );
        },
      ),
    );
  }
}
