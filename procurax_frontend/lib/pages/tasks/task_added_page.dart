import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';

class TaskAddedPage extends StatelessWidget {
  final Task task;
  const TaskAddedPage({super.key, required this.task});

  static const Color primaryBlue = Color(0xFF1F4DF0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 90, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "Task Added Successfully",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your task has been created and added to your list.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text("View Task"),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Add Another Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
