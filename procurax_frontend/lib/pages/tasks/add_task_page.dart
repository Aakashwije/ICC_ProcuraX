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
      assignee: "",
      tags: const [],
      isArchived: false,
    );

    try {
      final created = await _tasksService.createTask(task);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save task: $err')));
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
        title: const Text(
          "New Task",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        foregroundColor: primaryBlue,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _headerCard(
              title: "Plan a new task",
              subtitle: "Assign owners, priorities, and deadlines quickly.",
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _field("Task Title", title, icon: Icons.title_rounded),
                  const SizedBox(height: 12),
                  _field(
                    "Description",
                    desc,
                    icon: Icons.edit_note_outlined,
                    lines: 4,
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel("Status"),
                  const SizedBox(height: 8),
                  _statusSelector(),
                  const SizedBox(height: 12),
                  _sectionLabel("Due date"),
                  const SizedBox(height: 8),
                  _dateSelector(),
                  const SizedBox(height: 12),
                  _sectionLabel("Priority"),
                  const SizedBox(height: 8),
                  _priorityChips(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving ? "Saving..." : "Save Task",
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt_rounded, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _statusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: status,
          icon: const Icon(Icons.expand_more_rounded),
          items: const [
            DropdownMenuItem(value: TaskStatus.todo, child: Text("To do")),
            DropdownMenuItem(
              value: TaskStatus.inProgress,
              child: Text("In progress"),
            ),
            DropdownMenuItem(value: TaskStatus.blocked, child: Text("Blocked")),
            DropdownMenuItem(value: TaskStatus.done, child: Text("Done")),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => status = value);
          },
        ),
      ),
    );
  }

  Widget _dateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: primaryBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${deadline.day}/${deadline.month}/${deadline.year}",
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
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
            child: const Text("Pick"),
          ),
        ],
      ),
    );
  }

  Widget _priorityChips() {
    return Wrap(
      spacing: 8,
      children: TaskPriority.values.map((p) {
        final selected = priority == p;
        return ChoiceChip(
          label: Text(p.name),
          selected: selected,
          selectedColor: primaryBlue,
          onSelected: (_) => setState(() => priority = p),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontFamily: 'Poppins',
          ),
        );
      }).toList(),
    );
  }

  Widget _field(
    String hint,
    TextEditingController c, {
    int lines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}
