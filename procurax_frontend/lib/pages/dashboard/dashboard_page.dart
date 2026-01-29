import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/services/procurement_service.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';

enum ProjectStatus { active, pending, completed }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryBlue = Color(0xFF1F4CCF);
  static const Color lightBlue = Color(0xFFE6EEF8);
  static const Color neutralText = Color(0xFF6B7280);

  // 🔴 Simulated real-time status
  final ProjectStatus projectStatus = ProjectStatus.active;
  late Future<ProcurementView> _procurementFuture;

  @override
  void initState() {
    super.initState();
    _procurementFuture = ProcurementService.fetchView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.dashboard),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(
                            Icons.menu_rounded,
                            size: 30,
                            color: primaryBlue,
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

              // ================= CONTENT =================
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _searchBar(),
                      const SizedBox(height: 24),
                      _animatedCard(
                        _sectionCard(
                          title: "Project",
                          child: _projectCard(projectStatus),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _animatedCard(
                        _sectionCard(
                          title: "Upcoming Meetings",
                          child: Column(
                            children: [
                              _infoRow(
                                icon: Icons.calendar_today_outlined,
                                title: "Project Alpha Team Meeting",
                                subtitle: "10:00 A.M – 11:00 A.M",
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.calendar_today_outlined,
                                title: "Vendor Sync – Phase 2",
                                subtitle: "02:00 P.M – 02:30 P.M",
                              ),
                            ],
                          ),
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
                          title: "Urgent Tasks",
                          child: Column(
                            children: [
                              _infoRow(
                                icon: Icons.warning_amber_outlined,
                                title: "Review & Approve Alpha Budget",
                                subtitle: "Due: July 05, 2025",
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.warning_amber_outlined,
                                title: "Finalize Site Safety Checklist",
                                subtitle: "Due: July 06, 2025",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
        children: const [
          Icon(Icons.search_outlined, color: neutralText),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search",
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.mic_none_outlined, color: neutralText),
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

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
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
          return _emptyState("Unable to load procurement updates.");
        }

        final items =
            snapshot.data?.procurementItems ?? <ProcurementItemView>[];

        if (items.isEmpty) {
          return _emptyState("No procurement updates yet.");
        }

        final updates = items.take(2).toList();
        return Column(
          children: [
            for (var i = 0; i < updates.length; i++) ...[
              _infoRow(
                icon: Icons.local_shipping_outlined,
                title: updates[i].materialDescription.isEmpty
                    ? "Procurement Update"
                    : updates[i].materialDescription,
                subtitle: _procurementSubtitle(updates[i]),
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
    final date = item.goodsAtLocationDate.isNotEmpty
        ? item.goodsAtLocationDate
        : item.cmsRequiredDate;
    final statusLabel = (status != null && status.isNotEmpty)
        ? "Status: $status"
        : "Status: —";
    final dateLabel = date.isNotEmpty ? "Goods at: $date" : "Date TBD";
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
