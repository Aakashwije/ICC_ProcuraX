import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';

import 'pages/get_started/get_started_page.dart';
import 'pages/procurement/procurement_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/tasks/tasks_page.dart';
import 'pages/notes/notes_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/build_assist/build_assist_page.dart';
import 'pages/communication/communication_page.dart';
import 'pages/meetings/features/smart_calendar/screens/meetings_page.dart';
import 'pages/sign_in/create_account_page.dart';
import 'pages/log_in/login_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/settings/theme_notifier.dart';
import 'pages/notifications/notifications_page.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),

            // ✅ Correct initial route
            initialRoute: ApiService.hasToken
                ? AppRoutes.dashboard
                : AppRoutes.getStarted,

            routes: {
              AppRoutes.getStarted: (context) => const GetStartedPage(),
              AppRoutes.login: (context) => const LoginPage(),
              AppRoutes.createAccount: (context) => const CreateAccountPage(),
              AppRoutes.procurement: (context) =>
                  const AuthGate(child: ProcurementSchedulePage()),
              AppRoutes.dashboard: (context) =>
                  const AuthGate(child: DashboardPage()),
              AppRoutes.settings: (context) =>
                  const AuthGate(child: SettingsPage()),
              AppRoutes.notifications: (context) =>
                  const AuthGate(child: NotificationsPage()),
              AppRoutes.tasks: (context) => const AuthGate(child: TasksPage()),
              AppRoutes.buildAssist: (context) =>
                  const AuthGate(child: BuildAssistPage()),
              AppRoutes.notes: (context) => const AuthGate(child: NotesPage()),
              AppRoutes.communication: (context) =>
                  const AuthGate(child: CommunicationPage()),
              AppRoutes.meetings: (context) =>
                  const AuthGate(child: MeetingsPage()),
              AppRoutes.documents: (context) =>
                  const AuthGate(child: DocumentsPage()),
            },
          );
        },
      ),
    );
  }
}
