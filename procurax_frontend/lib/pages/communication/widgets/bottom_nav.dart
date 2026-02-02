import 'package:flutter/material.dart';
import '../core/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int messageBadgeCount;
  final int alertBadgeCount;
  final ValueChanged<int>? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.messageBadgeCount = 0,
    this.alertBadgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Single thin line above the nav bar, no box
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 2,
          thickness: 1,
          color: const Color.fromARGB(255, 172, 169, 169),
        ),
        SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColours.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            elevation: 0, // remove shadow so it doesn't look like a card
            backgroundColor: Theme.of(context).scaffoldBackgroundColor, // blend with page
            items: [
              BottomNavigationBarItem(
                icon: _buildIconWithBadge(
                  icon: Icons.chat_bubble_outline,
                  badgeCount: messageBadgeCount,
                ),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.call_outlined),
                label: 'Calls',
              ),
              
              BottomNavigationBarItem(
                icon: _buildIconWithBadge(
                  icon: Icons.notifications_none,
                  badgeCount: alertBadgeCount,
                ),
                label: 'Alerts',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    required int badgeCount,
  }) {
    if (badgeCount == 0) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badgeCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}