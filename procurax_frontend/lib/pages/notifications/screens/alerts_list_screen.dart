import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_card.dart';
import '../widgets/alert_filter_chip.dart';
import '../models/alert_model.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  AlertType? selectedType;
  AlertPriority? selectedPriority;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: Column(
        children: [
          AlertTypeFilter(
            selectedType: selectedType,
            onTypeSelected: (type) => setState(() => selectedType = type),
          ),
          AlertPriorityFilter(
            selectedPriority: selectedPriority,
            onPrioritySelected: (priority) =>
                setState(() => selectedPriority = priority),
          ),
          Expanded(
            child: Consumer<AlertProvider>(
              builder: (context, provider, _) {
                final alerts = provider.alerts
                    .where(
                      (a) =>
                          (selectedType == null || a.type == selectedType) &&
                          (selectedPriority == null ||
                              a.priority == selectedPriority),
                    )
                    .toList();

                if (alerts.isEmpty) {
                  return const Center(child: Text("No alerts"));
                }

                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (_, index) {
                    final alert = alerts[index];
                    return AlertCard(
                      alert: alert,
                      onMarkRead: () => provider.markAsRead(alert),
                      onDelete: () => provider.deleteAlert(alert),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
