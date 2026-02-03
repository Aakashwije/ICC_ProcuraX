import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/services/tasks_service.dart';

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
  late TextEditingController _assigneeController;
  late TextEditingController _tagsController;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _deadline;
  bool _saving = false;

  final TasksService _tasksService = TasksService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _assigneeController = TextEditingController(text: widget.task.assignee);
    _tagsController = TextEditingController(text: widget.task.tags.join(", "));
    _priority = widget.task.priority;
    _status = widget.task.status;
    _deadline = widget.task.dueDate;
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _deadline,
      assignee: _assigneeController.text.trim(),
      tags: _tagsController.text
          .split(",")
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );

    try {
      final saved = await _tasksService.updateTask(updatedTask);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $err')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
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

            const SizedBox(height: 12),

            _inputField("Assignee", _assigneeController),

            const SizedBox(height: 12),

            _inputField("Tags (comma separated)", _tagsController),

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
                      initialDate: _deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                  child: Text(
                    _deadline == null
                        ? "Select date"
                        : "${_deadline!.day}/${_deadline!.month}/${_deadline!.year}",
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

            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.flag_outlined, color: primaryBlue),
                const SizedBox(width: 8),
                DropdownButton<TaskStatus>(
                  value: _status,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                  },
                  items: const [
                    DropdownMenuItem(
                      value: TaskStatus.todo,
                      child: Text("To do"),
                    ),
                    DropdownMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text("In progress"),
                    ),
                    DropdownMenuItem(
                      value: TaskStatus.blocked,
                      child: Text("Blocked"),
                    ),
                    DropdownMenuItem(
                      value: TaskStatus.done,
                      child: Text("Done"),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveChanges,
                icon: const Icon(Icons.save),
                label: _saving
                    ? const Text(
                        "Saving...",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                      )
                    : const Text(
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
