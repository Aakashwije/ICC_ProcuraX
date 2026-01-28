import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

import 'pages/get_started/get_started_page.dart';
import 'pages/procurement/procurement_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/tasks/tasks_page.dart';
import 'pages/notes/notes_page.dart';
import 'pages/documents/documents_page.dart';
import 'pages/build_assist/build_assist_page.dart';
import 'pages/communication/communication_page.dart';
import 'pages/meetings/meetings_page.dart';

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
        AppRoutes.communication: (context) => const CommunicationPage(),
        AppRoutes.meetings: (context) => const MeetingsPage(),
        AppRoutes.documents: (context) => const DocumentsPage(),
      },
    );
  }
}
