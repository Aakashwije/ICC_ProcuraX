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
  static const Map<TaskStatus, Color> _statusColors = {
    TaskStatus.todo: Color(0xFF9CA3AF),
    TaskStatus.inProgress: Color(0xFF2563EB),
    TaskStatus.blocked: Color(0xFFE11D48),
    TaskStatus.done: Color(0xFF16A34A),
  };
  static const Map<TaskPriority, Color> _priorityColors = {
    TaskPriority.critical: Color(0xFF7C3AED),
    TaskPriority.high: Color(0xFFE11D48),
    TaskPriority.medium: Color(0xFFF59E0B),
    TaskPriority.low: Color(0xFF2563EB),
  };

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
      if (mounted) {
        setState(() => _saving = false);
      }
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
                  const SizedBox(height: 8),
                  _selectedStatusChip(),
                  const SizedBox(height: 12),
                  _sectionLabel("Due date"),
                  const SizedBox(height: 8),
                  _dateSelector(),
                  const SizedBox(height: 12),
                  _sectionLabel("Priority"),
                  const SizedBox(height: 8),
                  _priorityChips(),
                  const SizedBox(height: 8),
                  _selectedPriorityChip(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_rounded, color: primaryBlue, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Select status",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<TaskStatus>(
              value: status,
              icon: const Icon(Icons.expand_more_rounded),
              items:
                  [
                        TaskStatus.todo,
                        TaskStatus.inProgress,
                        TaskStatus.blocked,
                        TaskStatus.done,
                      ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColors[value] ?? primaryBlue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _statusLabel(value),
                                style: const TextStyle(fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => status = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(TaskStatus value) {
    switch (value) {
      case TaskStatus.todo:
        return "To do";
      case TaskStatus.inProgress:
        return "In progress";
      case TaskStatus.blocked:
        return "Blocked";
      case TaskStatus.done:
        return "Done";
    }
  }

  Widget _selectedStatusChip() {
    final color = _statusColors[status] ?? primaryBlue;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              _statusLabel(status),
              style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      alignment: WrapAlignment.center,
      spacing: 8,
      children: TaskPriority.values.map((p) {
        final selected = priority == p;
        final color = _priorityColors[p] ?? primaryBlue;
        return ChoiceChip(
          label: Text(_priorityLabel(p)),
          selected: selected,
          selectedColor: color,
          onSelected: (_) => setState(() => priority = p),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontFamily: 'Poppins',
          ),
        );
      }).toList(),
    );
  }

  Widget _selectedPriorityChip() {
    final color = _priorityColors[priority] ?? primaryBlue;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.priority_high_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              _priorityLabel(priority),
              style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(TaskPriority value) {
    switch (value) {
      case TaskPriority.critical:
        return "Critical";
      case TaskPriority.high:
        return "High";
      case TaskPriority.medium:
        return "Medium";
      case TaskPriority.low:
        return "Low";
    }
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
