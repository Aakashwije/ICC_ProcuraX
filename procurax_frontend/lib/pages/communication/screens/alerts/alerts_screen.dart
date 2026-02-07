import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/chat_service.dart';

class AlertsScreen extends StatefulWidget {
  final String userId;

  const AlertsScreen({super.key, required this.userId});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ChatService _chatService = ChatService();
  List<dynamic> alerts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchAlerts();
    }
  }

  Future<void> _fetchAlerts() async {
    try {
      final data = await _chatService.getUserAlerts(widget.userId);
      setState(() {
        alerts = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load alerts: $e');
      setState(() => loading = false);
    }
  }

  String _formatAlertTime(dynamic createdAt) {
    if (createdAt == null) return '';

    if (createdAt is DateTime) {
      return TimeOfDay.fromDateTime(createdAt.toLocal()).format(context);
    }

    if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal();
        return TimeOfDay.fromDateTime(dt).format(context);
      }
    }

    if (createdAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(createdAt);
      final normalized = hasTz ? createdAt : '${createdAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return TimeOfDay.fromDateTime(parsed.toLocal()).format(context);
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
          ? const Center(
              child: Text(
                'No alerts at the moment',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];

                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 221, 217, 217),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: alert['isRead'] == true
                          ? Colors.grey.shade300
                          : Colors.red.shade100,
                      child: Icon(
                        Icons.notifications,
                        color: alert['isRead'] == true
                            ? Colors.grey
                            : Colors.red,
                      ),
                    ),
                    title: Text(
                      alert['title'] ?? 'New message',
                      style: TextStyle(
                        fontWeight: alert['isRead'] == true
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _formatAlertTime(alert['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
