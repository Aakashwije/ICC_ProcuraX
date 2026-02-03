import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/services/tasks_service.dart';

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
  final assignee = TextEditingController();
  final tagsController = TextEditingController();
  DateTime deadline = DateTime.now();
  TaskPriority priority = TaskPriority.low;
  TaskStatus status = TaskStatus.todo;
  bool _saving = false;

  final TasksService _tasksService = TasksService();

  Future<void> _save() async {
    if (title.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final task = Task(
      id: "",
      title: title.text.trim(),
      description: desc.text.trim(),
      status: status,
      priority: priority,
      dueDate: deadline,
      assignee: assignee.text.trim(),
      tags: tagsController.text
          .split(",")
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      isArchived: false,
    );

    try {
      final created = await _tasksService.createTask(task);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save task: $err')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
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
            _field("Assignee", assignee),
            const SizedBox(height: 12),
            _field("Tags (comma separated)", tagsController),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.flag_outlined),
                const SizedBox(width: 8),
                DropdownButton<TaskStatus>(
                  value: status,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => status = value);
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
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Save Task"),
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
