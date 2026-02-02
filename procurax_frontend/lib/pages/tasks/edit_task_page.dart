import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TaskPriority _priority;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _priority = widget.task.priority;
    _deadline = widget.task.deadline;
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) return;

    final updatedTask = Task(
      id: widget.task.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      location: widget.task.location,
      city: widget.task.city,
      deadline: _deadline,
      priority: _priority,
      assignedTo: widget.task.assignedTo,
      completed: widget.task.completed,
    );

    Navigator.pop(context, updatedTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Task", style: TextStyle(fontFamily: 'Poppins')),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _inputField("Task Title", _titleController),
            const SizedBox(height: 12),

            _inputField("Description", _descController, maxLines: 4),

            const SizedBox(height: 16),

            // Deadline
            Row(
              children: [
                const Icon(Icons.calendar_today, color: primaryBlue),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _deadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                  child: Text(
                    "${_deadline.day}/${_deadline.month}/${_deadline.year}",
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Priority
            Row(
              children: TaskPriority.values.map((p) {
                final selected = _priority == p;
                return Expanded(
                  child: ChoiceChip(
                    label: Text(p.name),
                    selected: selected,
                    selectedColor: primaryBlue,
                    onSelected: (_) => setState(() => _priority = p),
                    labelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text(
                  "Save Changes",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
