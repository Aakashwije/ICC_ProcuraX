/*
  Procurement schedule UI.

  This file renders a full-page procurement schedule that:
  - fetches procurement data from the backend
  - shows a list of procurement items
  - shows a compact list of upcoming deliveries
  - provides refresh and error states
*/
import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/services/procurement_service.dart';
import 'package:procurax_frontend/theme/app_theme.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';

/*
  Public page widget mounted from the app routes. We keep it stateful to
  manage the async fetch, refresh indicator, and last-updated timestamp.
*/
class ProcurementSchedulePage extends StatefulWidget {
  const ProcurementSchedulePage({super.key});

  @override
  State<ProcurementSchedulePage> createState() =>
      _ProcurementSchedulePageState();
}

/*
  State holder for procurement schedule:
  - _future is the async request for procurement data.
  - _isRefreshing toggles the refresh button and indicator.
  - _lastLoadedAt is used to show when data was last fetched.
*/
class _ProcurementSchedulePageState extends State<ProcurementSchedulePage> {
  late Future<ProcurementView> _future;
  bool _isRefreshing = false;
  DateTime? _lastLoadedAt;

  /*
    Initial fetch kicks off when the widget is inserted into the tree.
  */
  @override
  void initState() {
    super.initState();
    _future = ProcurementService.fetchView();
  }

  /*
    Manual refresh handler that re-fetches the procurement data and tracks
    the last successful load timestamp.
  */
  Future<void> _reload() async {
    setState(() {
      _isRefreshing = true;
      _future = ProcurementService.fetchView();
    });

    try {
      await _future;
      _lastLoadedAt = DateTime.now();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /*
    Builds the overall page layout, including:
    - app drawer
    - loading / error / success states
    - procurement items and upcoming deliveries lists
  */
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = AppColors.primary;
    const Color lightBlue = Color(0xFF8DB3E2);
    const Color cardBg = Color(0xFFEAF2FB);
    const Color iconBg = Color(0xFFF3F7FF);

    /*
      Scaffold provides the screen structure with drawer support.
    */
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.procurement),
      backgroundColor: Colors.white,
      /*
        SafeArea avoids notches/status bars and keeps the content visible.
      */
      body: SafeArea(
        child: FutureBuilder<ProcurementView>(
          future: _future,
          builder: (context, snapshot) {
            /*
              Loading state: show a centered progress spinner.
            */
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            /*
              Error state: show retry UI with the backend error message.
              Wrapped in a scrollable column with the top bar so the user
              can still open the drawer and navigate to other modules.
            */
            if (snapshot.hasError) {
              return SingleChildScrollView(
                padding: AppResponsive.pagePadding(context),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            tooltip: 'Menu',
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                            icon: const Icon(
                              Icons.menu_rounded,
                              size: 30,
                              color: primaryBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: const [
                            Text(
                              "Procurement",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Schedule",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _reload,
                          icon: const Icon(
                            Icons.refresh,
                            size: 26,
                            color: primaryBlue,
                          ),
                          tooltip: "Refresh",
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                    _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    ),
                  ],
                ),
              );
            }

            /*
              Success state: either use the fetched data or a safe default
              with empty collections to avoid null checks in the UI.
            */
            final view =
                snapshot.data ??
                const ProcurementView(
                  procurementItems: [],
                  upcomingDeliveries: [],
                );

            final items = view.procurementItems;
            final upcomingDeliveries = view.upcomingDeliveries;

            /*
              Label shown in the header for last load time.
            */
            final lastLoadedLabel = _lastLoadedAt == null
                ? "Not loaded yet"
                : "Updated ${_lastLoadedAt!.hour.toString().padLeft(2, '0')}:${_lastLoadedAt!.minute.toString().padLeft(2, '0')}";

            /*
              Pull-to-refresh wrapper for the scrollable content.
            */
            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: () async => _reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppResponsive.pagePadding(context),
                /*
                  Main vertical layout for the page sections.
                */
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /*
                      Top bar: drawer menu button, centered title, refresh.
                    */
                    Row(
                      children: [
                        Builder(
                          builder: (context) => Semantics(
                            label: 'Open navigation menu',
                            button: true,
                            child: IconButton(
                              tooltip: 'Menu',
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                              icon: const Icon(
                                Icons.menu_rounded,
                                size: 30,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Column(
                          children: const [
                            Text(
                              "Procurement",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Schedule",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _isRefreshing ? null : _reload,
                          icon: _isRefreshing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryBlue,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  size: 26,
                                  color: primaryBlue,
                                ),
                          tooltip: "Refresh",
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /*
                      Info row: loaded counts on the left, last updated on the right.
                    */
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_done_outlined,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Loaded ${items.length} items, ${upcomingDeliveries.length} deliveries",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          lastLoadedLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    /*
                      Section heading for procurement items list.
                    */
                    const Text(
                      "Procurement Items",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 16),

                    /*
                      Empty state for items list.
                    */
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No procurement items yet.",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),

                    /*
                      Full procurement cards (4 fields; goodsAtLocation is a date).
                    */
                    Column(
                      children: items
                          .map(
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ProcurementCard(
                                item: i,
                                cardColor: cardBg,
                                primaryBlue: primaryBlue,
                                lightBlue: lightBlue,
                                iconBg: iconBg,
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 30),

                    /*
                      Section heading for upcoming deliveries list.
                    */
                    const Text(
                      "Upcoming Deliveries",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /*
                      Empty state for upcoming deliveries.
                    */
                    if (upcomingDeliveries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No upcoming deliveries.",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),

                    /*
                      Compact list for upcoming deliveries (description + date only).
                    */
                    Column(
                      children: upcomingDeliveries
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DeliverySimpleCard(
                                delivery: d,
                                cardColor: Colors.white,
                                borderColor: cardBg,
                                iconBg: iconBg,
                                iconColor: lightBlue,
                                primaryBlue: primaryBlue,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/*
  Full procurement card showing enterprise logistics fields.
  Displays: Material, Responsibility, LC Opening, ETD, ETA, BOI Approval,
  Delivery to Site, Required Date, and Status.
*/
class _ProcurementCard extends StatelessWidget {
  final ProcurementItemView item;
  final Color cardColor;
  final Color primaryBlue;
  final Color lightBlue;
  final Color iconBg;

  /*
    Required properties for rendering the card content and theme colors.
  */
  const _ProcurementCard({
    required this.item,
    required this.cardColor,
    required this.primaryBlue,
    required this.lightBlue,
    required this.iconBg,
  });

  /*
    Helper to render a single labeled row with an icon, label, and value.
  */
  Widget _fieldRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // circular icon
        Container(
          height: compact ? 28 : 36,
          width: compact ? 28 : 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: compact ? 14 : 18, color: lightBlue),
        ),
        const SizedBox(width: 10),
        // label + value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? "—" : value,
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /*
    Maps backend status to a semantic color used for badges.
  */
  Color _statusColor(String? status) {
    final normalized = (status ?? '').toLowerCase();
    if (normalized == 'delayed') {
      return Colors.red;
    }
    if (normalized == 'early' ||
        normalized == 'on time' ||
        normalized == 'ontime') {
      return Colors.green;
    }
    return Colors.grey;
  }

  /*
    Builds a rounded badge using the computed status color.
  */
  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  /*
    Enterprise procurement card layout with full logistics tracking fields.
  */
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Material + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fieldRow(
                  Icons.inventory_2_outlined,
                  "Material",
                  item.materialList,
                ),
              ),
              if ((item.status ?? '').isNotEmpty) ...[
                const SizedBox(width: 10),
                _statusBadge(item.status!),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Responsibility row
          _fieldRow(
            Icons.business_outlined,
            "Responsibility",
            item.responsibility,
          ),
          const SizedBox(height: 16),

          // Divider with section label
          Row(
            children: [
              Icon(Icons.timeline_outlined, size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Text(
                "Logistics Timeline",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                height: 1,
                width: 100,
                color: primaryBlue.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Timeline row 1: LC Opening + ETD
          Row(
            children: [
              Expanded(
                child: _fieldRow(
                  Icons.account_balance_outlined,
                  "LC Opening",
                  item.openingLC,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fieldRow(
                  Icons.flight_takeoff_outlined,
                  "ETD",
                  item.etd,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Timeline row 2: ETA + BOI Approval
          Row(
            children: [
              Expanded(
                child: _fieldRow(
                  Icons.flight_land_outlined,
                  "ETA",
                  item.eta,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fieldRow(
                  Icons.verified_outlined,
                  "BOI Approval",
                  item.boiApproval,
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider with section label
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, size: 16, color: primaryBlue),
              const SizedBox(width: 6),
              Text(
                "Delivery Schedule",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                height: 1,
                width: 100,
                color: primaryBlue.withValues(alpha: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Delivery row: Delivery to Site + Required Date
          Row(
            children: [
              Expanded(
                child: _fieldRow(
                  Icons.event_available_outlined,
                  "Delivery to Site",
                  item.revisedDeliveryToSite,
                  valueColor: Colors.orange.shade700,
                  compact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fieldRow(
                  Icons.calendar_today_outlined,
                  "Required Date",
                  item.requiredDateCMS,
                  valueColor: Colors.red.shade700,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/*
  Compact card for upcoming deliveries (only description + date).
  Used in the upcoming deliveries section for a denser list.
*/
class _DeliverySimpleCard extends StatelessWidget {
  final DeliverySimpleView delivery;
  final Color cardColor;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final Color primaryBlue;

  /*
    Required properties for the delivery item and card styling.
  */
  const _DeliverySimpleCard({
    required this.delivery,
    required this.cardColor,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.primaryBlue,
  });

  /*
    Renders a compact row with an icon, description, date, and optional status.
  */
  @override
  Widget build(BuildContext context) {
    /*
      Normalize status text to drive a simple color mapping for the UI.
    */
    final status = delivery.status ?? '';
    final normalized = status.toLowerCase();
    final statusColor = normalized == 'delayed'
        ? Colors.red
        : (normalized == 'early' ||
              normalized == 'on time' ||
              normalized == 'ontime')
        ? Colors.green
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // icon
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // material + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.materialList,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      delivery.revisedDeliveryToSite.isEmpty
                          ? "—"
                          : delivery.revisedDeliveryToSite,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
  Error UI shown when the fetch fails. Provides a retry action.
*/
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /*
    message: error details to show.
    onRetry: callback triggered by the retry button.
  */
  const _ErrorState({required this.message, required this.onRetry});

  /*
    Centered error panel with icon, title, details, and retry button.
  */
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              "Failed to load procurement data",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}
