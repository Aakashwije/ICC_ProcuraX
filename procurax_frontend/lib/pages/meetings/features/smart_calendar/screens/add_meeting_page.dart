import 'package:flutter/material.dart';
import '../../../theme.dart';

class AddMeetingPage extends StatelessWidget {
  const AddMeetingPage({super.key});

  Widget input(String label, String hint, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryBlue)),
        const SizedBox(height: 6),
        TextField(
          maxLines: large ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: lightBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Add New Meeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            input('Meeting Title', 'Enter meeting title'),
            input(
              'Description (Optional)',
              'Add meeting details...',
              large: true,
            ),
            input('Select Date', ''),
            Row(
              children: [
                Expanded(child: input('Start Time', '')),
                const SizedBox(width: 12),
                Expanded(child: input('End Time', '')),
              ],
            ),
            input(
              'Meeting Type or Location (Optional)',
              'Enter location or meeting type',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}