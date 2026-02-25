import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/ai_message.dart';
import '../widgets/user_message.dart';
import '../widgets/delivery_card.dart';
import '../widgets/bottom_input.dart';

/// ===============================================================
/// Main Chat Screen
/// ===============================================================
class BuildAssistPage extends StatelessWidget {
  const BuildAssistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            /// ===================================================
            /// CUSTOM HEADER (App Bar)
            /// ===================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// Left Menu Icon
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.menu, color: Colors.grey.shade700),
                  ),

                  /// Centered Title + AI Badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// AI Badge (Rounded Box)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "AI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// App Title
                      const Text(
                        "BuildAssist",
                        style: TextStyle(
                          color: Color(0xFF2563EB), // Blue title
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// ===================================================
            /// CHAT AREA
            /// Displays conversation messages
            /// ===================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  SizedBox(height: 10),
                  AIMessage(),
                  SizedBox(height: 20),
                  UserMessage(),
                  SizedBox(height: 20),
                  DeliveryCard(),
                  SizedBox(height: 20),
                ],
              ),
            ),

            /// ===================================================
            /// QUICK ACTION BUTTONS
            /// Horizontal scrollable shortcuts
            /// ===================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    bottomAction("Schedule Update"),
                    bottomAction("Material Status"),
                    bottomAction("Progress Report"),
                    bottomAction("Team"),
                  ],
                ),
              ),
            ),

            /// ===================================================
            ///  BOTTOM MESSAGE INPUT
            /// ===================================================
            const BottomInput(),
          ],
        ),
      ),
    );
  }

  /// ===============================================================
  /// Quick Action Button Widget
  /// ===============================================================

  static Widget bottomAction(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
