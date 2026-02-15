/*
  Edit Task screen.
  Lets the user update task fields and save changes.
*/
import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/services/tasks_service.dart';

class EditTaskPage extends StatefulWidget {
/*
  Stateful widget because it holds form state and API calls.
*/
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
/*
  State holder for edit form fields and selections.
*/
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  late TextEditingController _titleController;
  late TextEditingController _descController;
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
    _priority = widget.task.priority;
    _status = widget.task.status;
    _deadline = widget.task.dueDate;
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) return;

/*
    Save updated task details to backend.
*/
    setState(() => _saving = true);

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _deadline,
      assignee: "",
      tags: const [],
    );

    try {
      final saved = await _tasksService.updateTask(updatedTask);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update task: $err')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
/*
    Build the edit task UI layout.
*/
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Task",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _headerCard(
              title: "Update this task",
              subtitle: "Adjust assignments, deadlines, and progress.",
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _inputField(
                    "Task Title",
                    _titleController,
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    "Description",
                    _descController,
                    icon: Icons.edit_note_outlined,
                    maxLines: 4,
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
                onPressed: _saving ? null : _saveChanges,
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
                  _saving ? "Saving..." : "Save Changes",
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
          value: _status,
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
            setState(() => _status = value);
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
              _deadline == null
                  ? "Select date"
                  : "${_deadline!.day}/${_deadline!.month}/${_deadline!.year}",
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ),
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
        final selected = _priority == p;
        return ChoiceChip(
          label: Text(p.name),
          selected: selected,
          selectedColor: primaryBlue,
          onSelected: (_) => setState(() => _priority = p),
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            color: selected ? Colors.white : Colors.black,
          ),
        );
      }).toList(),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
