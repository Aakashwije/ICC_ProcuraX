import 'package:flutter/material.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/routes/app_routes.dart';

class ProcurementSchedulePage extends StatelessWidget {
  const ProcurementSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1F4CCF);
    const Color lightBlue = Color(0xFF8DB3E2);
    const Color cardBg = Color(0xFFEAF2FB);
    const Color iconBg = Color(0xFFF3F7FF);

    // Sample procurement items (goodsAtLocation is now a date string)
    final items = [
      const _ProcurementItem(
        materialDescription: "High-strength Steel Beam S355",
        tdsQty: "12 Nos",
        cmsRequiredDate: "2026-02-10",
        goodsAtLocationDate: "2026-02-14",
      ),
      const _ProcurementItem(
        materialDescription: "Ready-mix Concrete 30MPa",
        tdsQty: "8 m³",
        cmsRequiredDate: "2026-02-12",
        goodsAtLocationDate: "2026-02-13",
      ),
      const _ProcurementItem(
        materialDescription: "Galvanized Bolts M20",
        tdsQty: "200 Pcs",
        cmsRequiredDate: "2026-02-08",
        goodsAtLocationDate: "2026-02-09",
      ),
    ];

    // Upcoming deliveries: only materialDescription + goodsAtLocationDate
    final upcomingDeliveries = [
      const _DeliverySimple(
        materialDescription: "High-strength Steel Beam S355",
        goodsAtLocationDate: "2026-02-14",
      ),
      const _DeliverySimple(
        materialDescription: "Galvanized Bolts M20",
        goodsAtLocationDate: "2026-02-09",
      ),
    ];

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.procurement),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
                  const SizedBox(width: 48), // balance spacing
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Procurement Items",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 16),

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
      ),
    );
  }
}

/// Procurement item where goodsAtLocation is a date
class _ProcurementItem {
  final String materialDescription;
  final String tdsQty;
  final String cmsRequiredDate;
  final String goodsAtLocationDate;

  const _ProcurementItem({
    required this.materialDescription,
    required this.tdsQty,
    required this.cmsRequiredDate,
    required this.goodsAtLocationDate,
  });
}

/// Compact delivery model (only the two fields you asked for)
class _DeliverySimple {
  final String materialDescription;
  final String goodsAtLocationDate;

  const _DeliverySimple({
    required this.materialDescription,
    required this.goodsAtLocationDate,
  });
}

/// Full procurement card (shows all four fields; goodsAtLocation is shown as a date)
class _ProcurementCard extends StatelessWidget {
  final _ProcurementItem item;
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
            item.goodsAtLocationDate,
            valueColor: Colors.red,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                label: const Text("Details"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact card for upcoming deliveries (only description + date)
class _DeliverySimpleCard extends StatelessWidget {
  final _DeliverySimple delivery;
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
                      delivery.goodsAtLocationDate,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // optional chevron
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
