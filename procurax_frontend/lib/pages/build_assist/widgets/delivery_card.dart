import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;

class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final String? type;

  const DeliveryCard({super.key, this.data, this.type});

  String _detectDataType() {
    if (data == null) return 'unknown';

    // Debug print
    print('DeliveryCard data: $data');

    // Prefer explicit type hints from the backend
    final typeField = data!['type'];
    if (typeField is String) {
      print('Type field: $typeField');
      switch (typeField.toLowerCase()) {
        case 'meeting':
          return 'meeting';
        case 'task':
          return 'task';
        case 'note':
          return 'note';
        case 'procurement':
          return 'procurement';
      }
    }

    // Fallback heuristic detection
    if (data!.containsKey('startTime') && data!.containsKey('endTime')) {
      return 'meeting';
    }
    if (data!.containsKey('dueDate') && data!.containsKey('status')) {
      return 'task';
    }
    if (data!.containsKey('content') && data!.containsKey('tag')) {
      return 'note';
    }
    // Accept procurement if material OR category exists
    if (data!.containsKey('material') || data!.containsKey('category')) {
      return 'procurement';
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    // Check if data is null or empty
    if (data == null || data!.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Procurement data unavailable',
                    style: theme.AppTextStyles.bodySmall.copyWith(
                      color: theme.AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There was an error fetching or displaying procurement details. Please try again or contact support.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dataType = _detectDataType();

    switch (dataType) {
      case 'meeting':
        return _buildMeetingCard();
      case 'task':
        return _buildTaskCard();
      case 'note':
        return _buildNoteCard();
      case 'procurement':
        return _buildProcurementCard();
      default:
        return _buildGenericCard();
    }
  }

  Widget _buildMeetingCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: const Icon(Icons.event, color: Colors.orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MEETING',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Attachment
                if (data!['attachment'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:
                        data!['attachment'].toString().endsWith('.jpg') ||
                            data!['attachment'].toString().endsWith('.png') ||
                            data!['attachment'].toString().endsWith('.jpeg')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data!['attachment'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Colors.orange.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data!['attachment'],
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                // Title
                Text(
                  data!['title'] ?? 'Meeting',
                  style: theme.AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                if (data!['location'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: theme.AppColors.neutral700,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          data!['location'],
                          style: theme.AppTextStyles.caption.copyWith(
                            color: theme.AppColors.neutral700,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Date/Time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDateTime(data!['startTime']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (data!['endTime'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              "Ends: ${_formatDateTime(data!['endTime'])}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (data!['description'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data!['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.check_circle, color: Colors.blue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachment
                if (data!['attachment'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:
                        data!['attachment'].toString().endsWith('.jpg') ||
                            data!['attachment'].toString().endsWith('.png') ||
                            data!['attachment'].toString().endsWith('.jpeg')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data!['attachment'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data!['attachment'],
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TASK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data!['title'] ?? 'Task',
                        style: theme.AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.AppColors.neutral900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          data!['status'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (data!['status'] ?? 'pending')
                            .toString()
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(data!['status']),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Priority
                if (data!['priority'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.flag,
                        size: 14,
                        color: _getPriorityColor(data!['priority']),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        (data!['priority']).toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getPriorityColor(data!['priority']),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                // Due Date
                if (data!['dueDate'] != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateTime(data!['dueDate']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                if (data!['description'] != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data!['description'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: const Icon(Icons.note, color: Colors.purple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachment
                if (data!['attachment'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:
                        data!['attachment'].toString().endsWith('.jpg') ||
                            data!['attachment'].toString().endsWith('.png') ||
                            data!['attachment'].toString().endsWith('.jpeg')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data!['attachment'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                color: Colors.purple.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data!['attachment'],
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                  ),
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title + Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data!['title'] ?? 'Note',
                        style: theme.AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.AppColors.neutral900,
                        ),
                      ),
                    ),
                    if (data!['tag'] != null &&
                        data!['tag'].toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data!['tag'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Content
                if (data!['content'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data!['content'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                // Date
                if (data!['createdAt'] != null)
                  Text(
                    'Created: ${_formatDateTime(data!['createdAt'])}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcurementCard() {
    // Light blue theme colors
    const Color cardBg = Color(0xFFF0F7FF); // Very light blue background
    const Color headerBg = Color(
      0xFFE0EEFF,
    ); // Slightly deeper light blue header
    const Color iconBg = Color(0xFFDBEAFE); // Light blue icon circles
    const Color accentBlue = Color(0xFF2563EB); // Blue accent for icons
    const Color textPrimary = Color(0xFF1E293B); // Dark slate text
    const Color textSecondary = Color(0xFF64748B); // Muted slate text
    const Color borderColor = Color(0xFFBFDBFE); // Soft blue border

    // If both material and category are missing, show error card
    if (!(data!['material']?.toString().isNotEmpty ?? false) &&
        !(data!['category']?.toString().isNotEmpty ?? false)) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No material details found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Material information is missing. Please try again.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final material = data!['material']?.toString() ?? '';
    final category = data!['category']?.toString() ?? '';
    final source = data!['source']?.toString() ?? '';
    final responsibility = data!['responsibility']?.toString() ?? '';
    final revisedDelivery = data!['revisedDelivery']?.toString() ?? '';
    final parentCategory = data!['parentCategory']?.toString() ?? '';
    final quantity = data!['quantity']?.toString() ?? '';
    final etd = data!['etd']?.toString() ?? '';
    final eta = data!['eta']?.toString() ?? '';
    final status = data!['status']?.toString() ?? '';

    // Build title: material name, fallback to category
    final title = material.isNotEmpty ? material : category;
    final subtitle = (category.isNotEmpty && material.isNotEmpty)
        ? category
        : parentCategory;

    Color _statusColor(String s) {
      final lower = s.toLowerCase();
      if (lower.contains('completed') || lower.contains('done'))
        return const Color(0xFF10B981);
      if (lower.contains('pending')) return const Color(0xFFF59E0B);
      if (lower.contains('drawing')) return const Color(0xFF6366F1);
      if (lower.contains('not confirmed')) return const Color(0xFFEF4444);
      return accentBlue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(color: headerBg),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _statusColor(status),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Detail rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                if (quantity.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.straighten_rounded,
                    'Quantity',
                    quantity,
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (revisedDelivery.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.local_shipping_rounded,
                    'Scheduled Delivery',
                    _formatDate(revisedDelivery),
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (etd.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.flight_takeoff_rounded,
                    'ETD (Order Date)',
                    _formatDate(etd),
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (eta.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.flight_land_rounded,
                    'ETA (Delivery Date)',
                    _formatDate(eta),
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (source.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.store_rounded,
                    'Source',
                    source,
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (responsibility.isNotEmpty)
                  _buildProcurementDetailRow(
                    Icons.person_rounded,
                    'Responsibility',
                    responsibility,
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
                if (parentCategory.isNotEmpty && subtitle != parentCategory)
                  _buildProcurementDetailRow(
                    Icons.category_rounded,
                    'Parent Category',
                    parentCategory,
                    iconBg,
                    accentBlue,
                    textPrimary,
                    textSecondary,
                  ),
              ],
            ),
          ),

          // Related items section
          if (_hasRelatedItems())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                border: const Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data!['relatedMeetings'] != null &&
                      (data!['relatedMeetings'] as List).isNotEmpty)
                    _buildRelatedSection(
                      'Related Meetings',
                      data!['relatedMeetings'],
                      Icons.event_rounded,
                      const Color(0xFFF97316),
                    ),
                  if (data!['relatedTasks'] != null &&
                      (data!['relatedTasks'] as List).isNotEmpty)
                    _buildRelatedSection(
                      'Related Tasks',
                      data!['relatedTasks'],
                      Icons.task_alt_rounded,
                      accentBlue,
                    ),
                  if (data!['relatedNotes'] != null &&
                      (data!['relatedNotes'] as List).isNotEmpty)
                    _buildRelatedSection(
                      'Related Notes',
                      data!['relatedNotes'],
                      Icons.sticky_note_2_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _hasRelatedItems() {
    return (data!['relatedMeetings'] != null &&
            (data!['relatedMeetings'] as List).isNotEmpty) ||
        (data!['relatedTasks'] != null &&
            (data!['relatedTasks'] as List).isNotEmpty) ||
        (data!['relatedNotes'] != null &&
            (data!['relatedNotes'] as List).isNotEmpty);
  }

  Widget _buildProcurementDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconBg,
    Color iconColor,
    Color labelColor,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCard() {
    final title = (data!['title']?.toString().isNotEmpty ?? false)
        ? data!['title']
        : (data!['material']?.toString().isNotEmpty ?? false)
        ? data!['material']
        : (data!['name']?.toString().isNotEmpty ?? false)
        ? data!['name']
        : 'Item';
    final description = (data!['description']?.toString().isNotEmpty ?? false)
        ? data!['description']
        : (data!['content']?.toString().isNotEmpty ?? false)
        ? data!['content']
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: const Text("BA", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'INFO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.AppColors.primary,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed' || 'done':
        return Colors.green;
      case 'in_progress' || 'in progress':
        return Colors.orange;
      case 'pending' || 'todo':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(dynamic dateValue) {
    if (dateValue == null) return '';
    try {
      DateTime date;
      if (dateValue is String) {
        // Try multiple formats
        final formats = [
          'yyyy-MM-ddTHH:mm:ss',
          'yyyy-MM-dd HH:mm:ss',
          'yyyy-MM-ddTHH:mm',
          'yyyy-MM-dd HH:mm',
          'MM/dd/yyyy hh:mm a',
          'MM/dd/yyyy',
          'yyyy-MM-dd',
        ];
        for (final fmt in formats) {
          try {
            date = DateFormat(fmt).parse(dateValue);
            return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
          } catch (_) {}
        }
        // Fallback to DateTime.parse
        try {
          date = DateTime.parse(dateValue);
          return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
        } catch (_) {}
        // If all parsing fails, show error
        return 'Invalid date/time';
      } else if (dateValue is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
        return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
      } else {
        return dateValue.toString();
      }
    } catch (e) {
      return 'Invalid date/time';
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildRelatedSection(
    String title,
    List items,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item['title'] ??
                        item['content']?.substring(0, 50) ??
                        'Item',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
