import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

import 'pages/get_started_page.dart';
import 'pages/procurement_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/tasks_page.dart';
import 'pages/notes_page.dart';
import 'pages/documents_page.dart';
import 'pages/build_assist_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Correct initial route
      initialRoute: AppRoutes.getStarted,

      routes: {
        AppRoutes.getStarted: (context) => const GetStartedPage(),
        AppRoutes.procurement: (context) => const ProcurementSchedulePage(),
        AppRoutes.dashboard: (context) => const DashboardPage(),
        AppRoutes.tasks: (context) => const TasksPage(),
        AppRoutes.buildAssist: (context) => const BuildAssistPage(),
        AppRoutes.notes: (context) => const NotesPage(),
        AppRoutes.documents: (context) => const DocumentsPage(),
      },
    );
  }
}
