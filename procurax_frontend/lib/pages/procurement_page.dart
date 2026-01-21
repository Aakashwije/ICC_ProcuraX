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

    final updates = [
      const _TimelineItem(
        title: "Material Request Submitted",
        subtitle: "Submitted by J.P.Peris",
        icon: Icons.send_rounded,
      ),
      const _TimelineItem(
        title: "Purchase Order Approved",
        subtitle: "Submitted by J.P.Peris",
        icon: Icons.description_rounded,
      ),
      const _TimelineItem(
        title: "Material Request Submitted",
        subtitle: "Submitted by J.P.Peris",
        icon: Icons.message_rounded,
      ),
      const _TimelineItem(
        title: "Delivery in Transit",
        subtitle: "Submitted by J.P.Peris",
        icon: Icons.local_shipping_rounded,
      ),
      const _TimelineItem(
        title: "Material Received & Inspected",
        subtitle: "Submitted by J.P.Peris",
        icon: Icons.credit_card_rounded,
      ),
    ];

    final deliveries = [
      const _DeliveryItem(
        title: "Steel Beams",
        subtitle: "Supplier Y",
      ),
      const _DeliveryItem(
        title: "Concrete Mix",
        subtitle: "Supplier Z",
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
                  // ✅ Drawer Open Button (Builder added)
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
                "Upcoming Updates",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 20),

              // Timeline Section
              _TimelineList(
                items: updates,
                lineColor: lightBlue,
                iconBg: const Color(0xFFEAEAEA),
                iconColor: lightBlue,
              ),

              const SizedBox(height: 35),

              const Text(
                "Upcoming Deliveries",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: primaryBlue,
                ),
              ),

              const SizedBox(height: 18),

              // Delivery Cards
              Column(
                children: deliveries
                    .map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DeliveryCard(
                          title: d.title,
                          subtitle: d.subtitle,
                          cardColor: cardBg,
                          iconColor: lightBlue,
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

class _TimelineList extends StatelessWidget {
  final List<_TimelineItem> items;
  final Color lineColor;
  final Color iconBg;
  final Color iconColor;

  const _TimelineList({
    required this.items,
    required this.lineColor,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final bool isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side (icon + line)
            Column(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: iconColor,
                    size: 26,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 65,
                    color: lineColor,
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Right side (text)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7FA5D1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color iconColor;

  const _DeliveryCard({
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7FA5D1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DeliveryItem {
  final String title;
  final String subtitle;

  const _DeliveryItem({
    required this.title,
    required this.subtitle,
  });
}
