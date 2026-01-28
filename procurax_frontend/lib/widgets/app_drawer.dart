import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // close drawer

    if (currentRoute == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1F4DF0),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          "assets/procurax.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ProcuuraX",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1F4DF0),
                          ),
                        ),

                        Text(
                          "Project Management Hub",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            _DrawerTile(
              title: "Dashboard",
              icon: Icons.grid_view_outlined,
              selected: currentRoute == AppRoutes.dashboard,
              onTap: () => _go(context, AppRoutes.dashboard),
            ),

            _DrawerTile(
              title: "Procurement Schedule",
              icon: Icons.shopping_cart_outlined,
              selected: currentRoute == AppRoutes.procurement,
              onTap: () => _go(context, AppRoutes.procurement),
            ),

            _DrawerTile(
              title: "Notes",
              icon: Icons.note_outlined,
              selected: currentRoute == AppRoutes.notes,
              onTap: () => _go(context, AppRoutes.notes),
            ),

            _DrawerTile(
              title: "Communication",
              icon: Icons.chat_bubble_outline,
              selected: currentRoute == AppRoutes.communication,
              onTap: () => _go(context, AppRoutes.communication),
            ),

            _DrawerTile(
              title: "Meetings",
              icon: Icons.event_outlined,
              selected: currentRoute == AppRoutes.meetings,
              onTap: () => _go(context, AppRoutes.meetings),
            ),

            _DrawerTile(
              title: "Tasks",
              icon: Icons.check_box_outlined,
              badge: "5",
              selected: currentRoute == AppRoutes.tasks,
              onTap: () => _go(context, AppRoutes.tasks),
            ),

            _DrawerTile(
              title: "Documents & Media",
              icon: Icons.folder_outlined,
              selected: currentRoute == AppRoutes.documents,
              onTap: () => _go(context, AppRoutes.documents),
            ),
            _DrawerTile(
              title: "BuildAssist",
              icon: Icons.support_agent_outlined,
              badge: "5",
              selected: currentRoute == AppRoutes.buildAssist,
              onTap: () => _go(context, AppRoutes.buildAssist),
            ),

            const Spacer(),
            const Divider(),

            _DrawerTile(
              title: "Settings",
              icon: Icons.settings,
              selected: false,
              onTap: () {},
            ),

            _DrawerTile(
              title: "Logout",
              icon: Icons.logout,
              color: Colors.red,
              selected: false,
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.getStarted,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  const _DrawerTile({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.selected,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey.shade700),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
