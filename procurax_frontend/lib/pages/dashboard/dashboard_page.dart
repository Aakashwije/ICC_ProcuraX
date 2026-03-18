import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/pages/meetings/features/smart_calendar/models/meeting.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/services/meetings_service.dart';
import 'package:procurax_frontend/services/procurement_service.dart';
import 'package:procurax_frontend/services/tasks_service.dart';
import 'package:procurax_frontend/theme/app_theme.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/widgets/custom_toast.dart';
import 'package:procurax_frontend/widgets/permission_request_dialog.dart';
import 'package:procurax_frontend/components/loading_state.dart';
import 'package:procurax_frontend/components/empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProjectStatus { active, pending, completed }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryBlue = AppColors.primary;
  static const Color lightBlue = AppColors.primaryLight;
  static const Color neutralText = AppColors.neutral500;

  // Simulated real-time status
  final ProjectStatus projectStatus = ProjectStatus.active;
  late Future<ProcurementView> _procurementFuture;
  late Future<List<Task>> _recentTasksFuture;
  late Future<List<Meeting>> _recentMeetingsFuture;
  final TasksService _tasksService = TasksService();
  bool _isRefreshing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Meeting> _recentMeetings = [];

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  bool _matchesQuery(String text) {
    if (!_isSearching) return true;
    return text.toLowerCase().contains(_searchQuery.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownPermissionDialog =
        prefs.getBool('permissions_requested') ?? false;

    if (!hasShownPermissionDialog && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => PermissionRequestDialog(
              onPermissionsGranted: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('permissions_requested', true);
              },
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshDashboard() {
    _procurementFuture = ProcurementService.fetchView();
    _recentTasksFuture = _tasksService.fetchTasks().then(
      (tasks) => tasks.take(2).toList(),
    );
    _recentMeetingsFuture = MeetingsService.getMeetings().then((meetings) {
      meetings.sort((a, b) => b.startTime.compareTo(a.startTime));
      final recent = meetings.take(2).toList();
      if (mounted) {
        setState(() => _recentMeetings = recent);
      }
      return recent;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
      _refreshDashboard();
    });
    try {
      await Future.wait([
        _procurementFuture,
        _recentTasksFuture,
        _recentMeetingsFuture,
      ]);
      if (!mounted) return;
      CustomToast.success(
        context,
        'All data has been updated successfully',
        title: 'Dashboard Refreshed',
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.dashboard),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: Column(
            children: [
              // ================= TOP HEADER =================
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Builder(
                        builder: (context) => Semantics(
                          label: 'Open navigation menu',
                          button: true,
                          child: IconButton(
                            tooltip: 'Menu',
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(
                              Icons.menu_rounded,
                              size: 30,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.notifications,
                            ),
                            icon: const Icon(
                              Icons.notifications_none,
                              size: 26,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.settings,
                            ),
                            icon: const Icon(
                              Icons.settings,
                              size: 26,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isRefreshing)
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: primaryBlue,
                  backgroundColor: lightBlue,
                ),

              if (_isRefreshing) const SizedBox(height: 16),

              // ================= CONTENT =================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _searchBar(),
                        if (_isSearching) ...[
                          const SizedBox(height: 12),
                          _globalSearchBanner(),
                          const SizedBox(height: 12),
                        ] else
                          const SizedBox(height: 24),
                        _animatedCard(
                          _sectionCard(
                            title: "Project",
                            child: _matchesQuery("project iit rathmalana")
                                ? _projectCard(projectStatus)
                                : _emptyState(
                                    "No project matches your search.",
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _animatedCard(
                          _sectionCard(
                            title: "Upcoming Meetings",
                            child: _meetingsSection(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _animatedCard(
                          _sectionCard(
                            title: "Procurement Updates",
                            child: _procurementUpdates(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _animatedCard(
                          _sectionCard(
                            title: "Recent Tasks",
                            child: _recentTasksCard(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_outlined, color: neutralText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: "Search",
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchQuery.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.close_rounded, color: neutralText),
              tooltip: "Clear search",
            ),
          if (_searchQuery.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.clear_all_rounded, color: neutralText),
              tooltip: "Clear all",
            ),
          const Icon(Icons.mic_none_outlined, color: neutralText),
        ],
      ),
    );
  }

  Widget _animatedCard(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _recentTasksCard() {
    return FutureBuilder<List<Task>>(
      future: _recentTasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState(
            message: 'Loading tasks...',
            fullScreen: false,
          );
        }
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load tasks',
            subtitle: 'Pull down to refresh',
          );
        }
        final tasks = snapshot.data ?? [];
        final filteredTasks = _filterTasks(tasks);
        if (filteredTasks.isEmpty) {
          return EmptyState(
            icon: _isSearching
                ? Icons.search_off_rounded
                : Icons.task_alt_outlined,
            title: _isSearching ? 'No tasks match your search' : 'No tasks yet',
          );
        }
        return Column(
          children: [
            for (var i = 0; i < filteredTasks.length; i++) ...[
              _recentTaskRow(filteredTasks[i]),
              if (i < filteredTasks.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _globalSearchBanner() {
    if (!_isSearching) return const SizedBox.shrink();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _procurementFuture,
        _recentTasksFuture,
        _recentMeetingsFuture,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final procurement = snapshot.data?.first as ProcurementView?;
        final tasks = snapshot.data?[1] as List<Task>? ?? [];
        final meetings = snapshot.data?[2] as List<Meeting>? ?? [];
        final hasProject = _matchesQuery("project iit rathmalana");
        final hasMeetings = meetings.any(
          (meeting) =>
              _matchesQuery("${meeting.title} ${_meetingSubtitle(meeting)}"),
        );
        final hasProcurement = _filterProcurementItems(
          procurement?.procurementItems ?? <ProcurementItemView>[],
        ).isNotEmpty;
        final hasTasks = _filterTasks(tasks).isNotEmpty;

        if (hasProject || hasMeetings || hasProcurement || hasTasks) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: lightBlue.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_off_rounded, color: primaryBlue),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "No dashboard results match your search.",
                  style: TextStyle(
                    fontSize: 12,
                    color: neutralText,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Text("Clear search"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _recentTaskRow(Task task) {
    final icon = _statusIcon(task.status);
    final dueDate = task.dueDate;
    final subtitle = dueDate == null
        ? "No due date"
        : "Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}";

    return _infoRowWithColoredText(
      icon: icon,
      title: task.title.isEmpty ? "Untitled task" : task.title,
      subtitle: subtitle,
      coloredPart: null,
      highlightColor: Colors.transparent,
    );
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return Icons.timelapse_outlined;
      case TaskStatus.blocked:
        return Icons.block_outlined;
      case TaskStatus.done:
        return Icons.check_circle_outline;
      case TaskStatus.todo:
        return Icons.assignment_outlined;
    }
  }

  Widget _projectCard(ProjectStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          "IIT RATHMALANA",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _infoRowWithColoredText({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? coloredPart,
    required Color highlightColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              if (coloredPart != null && subtitle.contains(coloredPart))
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: subtitle.replaceFirst(coloredPart, ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: neutralText,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextSpan(
                        text: coloredPart,
                        style: TextStyle(
                          fontSize: 12,
                          color: highlightColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: neutralText,
                    fontFamily: 'Poppins',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _procurementUpdates() {
    return FutureBuilder<ProcurementView>(
      future: _procurementFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState("Loading updates...");
        }

        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load procurement',
            subtitle: 'Pull down to refresh',
          );
        }

        final items =
            snapshot.data?.procurementItems ?? <ProcurementItemView>[];
        final filtered = _filterProcurementItems(items);

        if (filtered.isEmpty) {
          return _emptyState(
            _isSearching
                ? "No procurement updates match your search."
                : "No procurement updates yet.",
          );
        }

        final updates = filtered.take(2).toList();
        return Column(
          children: [
            for (var i = 0; i < updates.length; i++) ...[
              _infoRowWithColoredText(
                icon: Icons.local_shipping_outlined,
                title: updates[i].materialList.isEmpty
                    ? "Procurement Update"
                    : updates[i].materialList,
                subtitle: _procurementSubtitle(updates[i]),
                coloredPart: null,
                highlightColor: Colors.transparent,
              ),
              if (i != updates.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  String _procurementSubtitle(ProcurementItemView item) {
    final status = item.status?.trim();
    final date = item.revisedDeliveryToSite.isNotEmpty
        ? item.revisedDeliveryToSite
        : item.requiredDateCMS;
    final statusLabel = (status != null && status.isNotEmpty)
        ? "Status: $status"
        : "Status: —";
    final dateLabel = date.isNotEmpty ? "Delivery: $date" : "Date TBD";
    return "$statusLabel • $dateLabel";
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightBlue.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: neutralText,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _meetingsSection() {
    return FutureBuilder<List<Meeting>>(
      future: _recentMeetingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingState("Loading meetings...");
        }

        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Failed to load meetings',
            subtitle: 'Pull down to refresh',
          );
        }

        final meetings = snapshot.data ?? _recentMeetings;
        final visible = meetings
            .where(
              (meeting) => _matchesQuery(
                "${meeting.title} ${_meetingSubtitle(meeting)}",
              ),
            )
            .toList();

        if (visible.isEmpty) {
          return _emptyState(
            _isSearching
                ? "No meetings match your search."
                : "No meetings yet.",
          );
        }
        return Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              _infoRowWithColoredText(
                icon: Icons.calendar_today_outlined,
                title: visible[i].title.isEmpty
                    ? "Untitled meeting"
                    : visible[i].title,
                subtitle: _meetingSubtitle(visible[i]),
                coloredPart: null,
                highlightColor: Colors.transparent,
              ),
              if (i < visible.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  String _meetingSubtitle(Meeting meeting) {
    final date = meeting.startTime;
    final dateLabel = "${date.day}/${date.month}/${date.year}";
    final timeLabel = meeting.timeRange;
    final locationLabel = meeting.location.trim().isEmpty
        ? "Location TBD"
        : meeting.location.trim();
    return "$dateLabel • $timeLabel • $locationLabel";
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (!_isSearching) return tasks;
    final q = _searchQuery.toLowerCase();
    return tasks.where((task) {
      final due = task.dueDate == null
          ? ""
          : "${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}";
      final haystack = "${task.title} ${task.description} $due";
      return haystack.toLowerCase().contains(q);
    }).toList();
  }

  List<ProcurementItemView> _filterProcurementItems(
    List<ProcurementItemView> items,
  ) {
    if (!_isSearching) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      final haystack =
          "${item.materialList} ${item.status ?? ''} ${item.revisedDeliveryToSite} ${item.requiredDateCMS}";
      return haystack.toLowerCase().contains(q);
    }).toList();
  }

  Widget _loadingState(String message) {
    return Row(
      children: [
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue),
        ),
        const SizedBox(width: 8),
        Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: neutralText,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
