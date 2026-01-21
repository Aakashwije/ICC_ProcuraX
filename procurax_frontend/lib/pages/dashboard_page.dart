import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.dashboard),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              // ✅ Top row (Menu + Center Title)
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
                    "Dashboard",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance spacing
                ],
              ),

              const SizedBox(height: 30),

              const Expanded(
                child: Center(
                  child: Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
