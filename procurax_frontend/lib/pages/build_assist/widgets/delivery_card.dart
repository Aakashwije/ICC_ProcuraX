import 'package:flutter/material.dart';
import '../constants/colors.dart';

class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? type;

  const DeliveryCard({super.key, this.data, this.type});

  @override
  Widget build(BuildContext context) {
    // Check if data is null or empty
    if (data == null || data!.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: const Text("AI", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                "No procurement data found.",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    // If it's a list of items (for category queries)
    if (type == 'procurement_list' ||
        type == 'search_results' ||
        type == 'delivery_schedule') {
      if (data is List) {
        return Column(
          children: (data as List)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProcurementItem(item),
                ),
              )
              .toList(),
        );
      }
    }

    // Single item view
    return _buildProcurementItem(data!);
  }

  Widget _buildProcurementItem(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: const Text("AI", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                if (item['category'] != null &&
                    item['category'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['category'],
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Material
                Text(
                  item['material'] ?? "Unknown Material",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                // Source and Responsibility
                if (item['source'] != null &&
                    item['source'].toString().isNotEmpty)
                  _buildInfoRow("Source:", item['source']),
                if (item['responsibility'] != null &&
                    item['responsibility'].toString().isNotEmpty)
                  _buildInfoRow("Responsibility:", item['responsibility']),

                const SizedBox(height: 12),

                // Delivery Dates
                if (item['revisedDelivery'] != null &&
                    item['revisedDelivery'].toString().isNotEmpty)
                  _buildDateRow(
                    Icons.access_time,
                    "Delivery:",
                    _formatDate(item['revisedDelivery'].toString()),
                  ),

                if (item['requiredDate'] != null &&
                    item['requiredDate'].toString().isNotEmpty)
                  _buildDateRow(
                    Icons.event,
                    "Required:",
                    _formatDate(item['requiredDate'].toString()),
                  ),

                const SizedBox(height: 12),

                // Status Badge
                if (item['status'] != null &&
                    item['status'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        item['status'].toString(),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(item['status'].toString()),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Remarks/Warning
                if (item['remarks'] != null &&
                    item['remarks'].toString().isNotEmpty &&
                    !item['remarks'].toString().contains('C Drawing'))
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['remarks'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildDateRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'drawing pending':
        return Colors.orange;
      case 'not confirmed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.contains('00:00:00')) {
      return dateStr.split(' ')[0];
    }
    return dateStr;
  }
}
