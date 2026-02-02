import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';

import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/pages/tasks/add_task_page.dart';
import 'package:procurax_frontend/pages/tasks/edit_task_page.dart';
import 'package:procurax_frontend/pages/tasks/task_added_page.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  final List<Task> tasks = [];

  String filter = "Active";
  String _query = '';

  Future<void> _addTask() async {
    final task = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );

    if (!mounted) return;

    if (task != null) {
      setState(() => tasks.add(task));

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskAddedPage(task: task)),
      );
    }
  }

  void _toggleComplete(Task task) {
    setState(() {
      final index = tasks.indexWhere((t) => t.id == task.id);
      if (index == -1) return;
      tasks[index] = task.copyWith(completed: !task.completed);
    });
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text(
          "Are you sure you want to delete this task? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => tasks.removeWhere((t) => t.id == task.id));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<Task> get _visibleTasks {
    final filtered = tasks.where((t) {
      if (filter == "Completed") return t.completed;
      if (filter == "Active") return !t.completed;
      return true;
    });

    if (_query.trim().isEmpty) return filtered.toList();

    final q = _query.toLowerCase();
    return filtered.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.assignedTo.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _visibleTasks;

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.tasks),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              // ================= TOP ROW (Menu + Center Title) =================
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 30,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Tasks",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance spacing
                ],
              ),

              const SizedBox(height: 30),

              // ================= BODY =================
              Expanded(
                child: visibleTasks.isEmpty
                    ? Center(child: _emptyStateBox())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _searchBar(),

                            const SizedBox(height: 12),

                            _filters(),

                            const SizedBox(height: 16),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: visibleTasks.length,
                              itemBuilder: (_, i) => _taskCard(visibleTasks[i]),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(
          hintText: "Search",
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.mic),
        ),
      ),
    );
  }

  Widget _emptyStateBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt_outlined, color: primaryBlue, size: 36),
          SizedBox(height: 10),
          Text(
            "No tasks available",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Tap + to create your first task",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Row(
      children: ["Active", "All", "Completed"].map((f) {
        final active = filter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f),
            selected: active,
            onSelected: (_) => setState(() => filter = f),
            selectedColor: primaryBlue,
            labelStyle: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _taskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // checkbox to mark complete
              Checkbox(
                value: task.completed,
                onChanged: (_) => _toggleComplete(task),
                activeColor: primaryBlue,
              ),
              const SizedBox(width: 4),

              const Icon(Icons.assignment_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),

              // menu: edit / delete
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == "edit") {
                    final updated = await Navigator.push<Task>(
                      context,
                      MaterialPageRoute(
                        builder: (_) {
                          return EditTaskPage(task: task);
                        },
                      ),
                    );
                    if (updated != null) {
                      setState(() {
                        final idx = tasks.indexWhere((t) => t.id == updated.id);
                        if (idx >= 0) tasks[idx] = updated;
                      });
                    } else {
                      // if edit page modified the passed object in-place, just refresh
                      setState(() {});
                    }
                  }
                  if (value == "delete") _confirmDelete(task);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "edit", child: Text("Edit")),
                  PopupMenuItem(
                    value: "delete",
                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(task.description, style: const TextStyle(fontSize: 13)),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "${task.location} • ${task.city}",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16),
              const SizedBox(width: 4),
              Text(
                "Today, ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _PriorityBadge(priority: task.priority),
              const SizedBox(width: 8),
              Chip(label: Text(task.assignedTo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color bg;
    String text;

    switch (priority) {
      case TaskPriority.high:
        bg = Colors.red;
        text = "high";
        break;
      case TaskPriority.medium:
        bg = Colors.orange;
        text = "medium";
        break;
      case TaskPriority.low:
        bg = Colors.blue;
        text = "low";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
