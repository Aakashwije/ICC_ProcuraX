import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/procurement_view.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/services/procurement_service.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';

class ProcurementSchedulePage extends StatefulWidget {
  const ProcurementSchedulePage({super.key});

  @override
  State<ProcurementSchedulePage> createState() =>
      _ProcurementSchedulePageState();
}

class _ProcurementSchedulePageState extends State<ProcurementSchedulePage> {
  late Future<ProcurementView> _future;
  bool _isRefreshing = false;
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    _future = ProcurementService.fetchView();
  }

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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);
    const Color lightBlue = Color(0xFF8DB3E2);
    const Color cardBg = Color(0xFFEAF2FB);
    const Color iconBg = Color(0xFFF3F7FF);

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.procurement),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<ProcurementView>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryBlue),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _reload,
              );
            }

            final view =
                snapshot.data ??
                const ProcurementView(
                  procurementItems: [],
                  upcomingDeliveries: [],
                );

            final items = view.procurementItems;
            final upcomingDeliveries = view.upcomingDeliveries;

            final lastLoadedLabel = _lastLoadedAt == null
                ? "Not loaded yet"
                : "Updated ${_lastLoadedAt!.hour.toString().padLeft(2, '0')}:${_lastLoadedAt!.minute.toString().padLeft(2, '0')}";

            return RefreshIndicator(
              color: primaryBlue,
              onRefresh: () async => _reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar (menu icon + center title)
                    Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
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

                    const Text(
                      "Procurement Items",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No procurement items yet.",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),

                    // Full procurement cards (showing the 4 fields; goodsAtLocation is a date)
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

                    const Text(
                      "Upcoming Deliveries",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (upcomingDeliveries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "No upcoming deliveries.",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),

                    // Compact list for upcoming deliveries (materialDescription + goodsAtLocationDate only)
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

/// Full procurement card (shows all four fields; goodsAtLocation is shown as a date)
class _ProcurementCard extends StatelessWidget {
  final ProcurementItemView item;
  final Color cardColor;
  final Color primaryBlue;
  final Color lightBlue;
  final Color iconBg;

  const _ProcurementCard({
    required this.item,
    required this.cardColor,
    required this.primaryBlue,
    required this.lightBlue,
    required this.iconBg,
  });

  Widget _fieldRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // circular icon
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: lightBlue),
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
                  fontSize: 12,
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _fieldRow(
            Icons.inventory_2_outlined,
            "Material Description",
            item.materialDescription,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _fieldRow(
                  Icons.production_quantity_limits_outlined,
                  "TDS Qty",
                  item.tdsQty,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fieldRow(
                  Icons.calendar_today_outlined,
                  "CMS Required Date",
                  item.cmsRequiredDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // goodsAtLocationDate shown as a date
          _fieldRow(
            Icons.event_available_outlined,
            "Goods at Location Date",
            item.goodsAtLocationDate.isEmpty ? "—" : item.goodsAtLocationDate,
            valueColor: Colors.red,
          ),
          if ((item.status ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Text(
                  item.status!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(item.status),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Compact card for upcoming deliveries (only description + date)
class _DeliverySimpleCard extends StatelessWidget {
  final DeliverySimpleView delivery;
  final Color cardColor;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final Color primaryBlue;

  const _DeliverySimpleCard({
    required this.delivery,
    required this.cardColor,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
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
                  delivery.materialDescription,
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
                      delivery.goodsAtLocationDate.isEmpty
                          ? "—"
                          : delivery.goodsAtLocationDate,
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

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
