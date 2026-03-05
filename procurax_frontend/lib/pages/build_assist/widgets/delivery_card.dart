import 'package:flutter/material.dart';
import '../constants/colors.dart';

class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? type;

  const DeliveryCard({super.key, this.data, this.type});

  @override
  Widget build(BuildContext context) {
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
    return _buildProcurementItem(data);
  }

  Widget _buildProcurementItem(Map<String, dynamic>? item) {
    if (item == null) {
      return _buildDefaultCard();
    }

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
                // Category and Material
                if (item['category'] != null)
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
                Text(
                  item['material'] ?? "Concrete Delivery - Building A",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                // Source and Responsibility
                _buildInfoRow("Source:", item['source'] ?? "N/A"),
                _buildInfoRow(
                  "Responsibility:",
                  item['responsibility'] ?? "N/A",
                ),

                const SizedBox(height: 12),

                // Delivery Dates
                if (item['revisedDelivery'] != null &&
                    item['revisedDelivery'] != '')
                  _buildDateRow(
                    Icons.access_time,
                    "Delivery:",
                    _formatDate(item['revisedDelivery']),
                  ),

                if (item['requiredDate'] != null && item['requiredDate'] != '')
                  _buildDateRow(
                    Icons.event,
                    "Required:",
                    _formatDate(item['requiredDate']),
                  ),

                const SizedBox(height: 12),

                // Status Badge
                if (item['status'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(item['status']),
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

  Widget _buildDefaultCard() {
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
                const Text(
                  "Concrete Delivery - Building A",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildDateRow(
                  Icons.access_time,
                  "Scheduled Delivery:",
                  "Nov 3, 2025 - 7:00 AM",
                ),
                const SizedBox(height: 10),
                _buildDateRow(
                  Icons.check_circle,
                  "Quantity:",
                  "45 cubic meters",
                ),
                const SizedBox(height: 10),
                _buildDateRow(
                  Icons.check_circle,
                  "Supplier:",
                  "ABC Concrete Co.",
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Weather forecast shows rain on Nov 3. Consider rescheduling.",
                          style: TextStyle(fontSize: 13),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
      case 'Drawing Pending':
        return Colors.orange;
      case 'Not Confirmed':
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
