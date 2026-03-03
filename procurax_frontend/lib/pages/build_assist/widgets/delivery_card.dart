import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Delivery Status Card
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// AI Avatar
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: const Text("AI", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),

        /// Card Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Concrete Delivery - Building A",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 16),

                infoRow(
                  Icons.access_time,
                  "Scheduled Delivery:",
                  "Nov 3, 2025 - 7:00 AM",
                ),

                const SizedBox(height: 10),

                infoRow(
                  Icons.check_circle,
                  "Quantity:",
                  "45 cubic meters",
                  Colors.green,
                ),

                const SizedBox(height: 10),

                infoRow(
                  Icons.check_circle,
                  "Supplier:",
                  "ABC Concrete Co.",
                  Colors.green,
                ),

                const SizedBox(height: 18),

                /// Warning Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Weather forecast shows rain on Nov 3. Consider rescheduling.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Reusable Info Row Widget
  static Widget infoRow(
    IconData icon,
    String title,
    String value, [
    Color iconColor = Colors.orange,
  ]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(
          "$title ",
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
