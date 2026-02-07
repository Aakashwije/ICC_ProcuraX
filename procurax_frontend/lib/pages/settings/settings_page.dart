import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedTheme = "Light";
  String selectedTimezone = "Pacific Time (PST)";
  String role = "Project Manager";
  String department = "Construction";
  String defaultProject = "Tower A - Downtown";

  String firstName = "John";
  String lastName = "Doe";
  String email = "john.doe@company.com";
  String phone = "+1 (555) 123-4567";

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);

    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.themeMode == ThemeMode.dark;

    final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final cardBg = isDark ? Colors.grey[900]! : Colors.white;
    final fieldBg = isDark ? Colors.grey[800]! : const Color(0xFFDCE7F1);
    final blue = isDark ? Colors.white : primaryBlue;
    final lightBlue = isDark ? Colors.grey[400]! : const Color(0xFF769BC5);

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.settings),
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              // ---------- HEADER (kept from your original code) ----------
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu_rounded, size: 30, color: blue),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: blue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              // ---------- SETTINGS CONTENT ----------
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _card(
                        cardBg,
                        blue,
                        lightBlue,
                        Icons.person_outline,
                        "Profile",
                        "Update your personal info",
                        Column(
                          children: [
                            _input("First Name", firstName, fieldBg),
                            _input("Last Name", lastName, fieldBg),
                            _input("Email", email, fieldBg),
                            _input("Phone Number", phone, fieldBg),
                          ],
                        ),
                      ),

                      _card(
                        cardBg,
                        blue,
                        lightBlue,
                        Icons.badge_outlined,
                        "Role & Department",
                        "Configure your role",
                        Column(
                          children: [
                            _dropdown(
                              "Role",
                              role,
                              ["Project Manager", "Engineer", "Site Worker"],
                              fieldBg,
                              (v) => setState(() => role = v),
                            ),
                            _dropdown(
                              "Department",
                              department,
                              ["Construction", "IT"],
                              fieldBg,
                              (v) => setState(() => department = v),
                            ),
                            _dropdown(
                              "Default Project",
                              defaultProject,
                              ["Tower A - Downtown", "Tower B"],
                              fieldBg,
                              (v) => setState(() => defaultProject = v),
                            ),
                          ],
                        ),
                      ),

                      _card(
                        cardBg,
                        blue,
                        lightBlue,
                        Icons.palette_outlined,
                        "Display Preferences",
                        "Customize appearance",
                        Column(
                          children: [
                            _dropdown(
                              "Theme",
                              selectedTheme,
                              ["Light", "Dark"],
                              fieldBg,
                              (v) {
                                setState(() => selectedTheme = v);
                                themeNotifier.setTheme(v);
                              },
                            ),
                            _dropdown(
                              "Timezone",
                              selectedTimezone,
                              ["Pacific Time (PST)", "Eastern Time (EST)"],
                              fieldBg,
                              (v) => setState(() => selectedTimezone = v),
                            ),
                          ],
                        ),
                      ),

                      _card(
                        cardBg,
                        blue,
                        lightBlue,
                        Icons.info_outline,
                        "About",
                        "Application info",
                        Column(
                          children: [
                            _aboutRow("Version", "2.4.1", lightBlue),
                            const Divider(),
                            _aboutRow("Last Updated", "Nov 2, 2025", lightBlue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- REUSABLE WIDGETS ----------
  Widget _card(
    Color bg,
    Color blue,
    Color lightBlue,
    IconData icon,
    String title,
    String subtitle,
    Widget child,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: lightBlue)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _input(String label, String value, Color bg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    Color bg,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(String l, String r, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: c)),
        Text(r, style: TextStyle(color: c)),
      ],
    );
  }
}
