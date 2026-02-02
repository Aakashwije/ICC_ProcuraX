import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  final title = TextEditingController();
  final desc = TextEditingController();
  DateTime deadline = DateTime.now();
  TaskPriority priority = TaskPriority.low;

  void _save() {
    final task = Task(
      id: DateTime.now().toString(),
      title: title.text,
      description: desc.text,
      location: "Downtown Plaza",
      city: "Colombo, SL",
      deadline: deadline,
      priority: priority,
      assignedTo: "Aakash Wijesekara",
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Task"),
        foregroundColor: primaryBlue,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _field("Task Title", title),
            const SizedBox(height: 12),
            _field("Description", desc, lines: 4),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                      initialDate: deadline,
                    );
                    if (d != null) setState(() => deadline = d);
                  },
                  child: Text(
                    "${deadline.day}/${deadline.month}/${deadline.year}",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: TaskPriority.values.map((p) {
                final selected = priority == p;
                return Expanded(
                  child: ChoiceChip(
                    label: Text(p.name),
                    selected: selected,
                    selectedColor: primaryBlue,
                    onSelected: (_) => setState(() => priority = p),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("Save Task"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController c, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: lightBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
