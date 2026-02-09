import 'package:flutter/material.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../widgets/app_drawer.dart';

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.meetings),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 30,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Meetings",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 30),
              const Expanded(
                child: Center(
                  child: Text("Meetings", style: TextStyle(fontSize: 20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
