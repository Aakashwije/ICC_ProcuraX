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
    // If both material and category are missing, show error card
    if (!(data!['material']?.toString().isNotEmpty ?? false) &&
        !(data!['category']?.toString().isNotEmpty ?? false)) {
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
                    'No material details found',
                    style: theme.AppTextStyles.bodySmall.copyWith(
                      color: theme.AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Material information is missing or could not be displayed. Please try again or contact support.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ...existing code...
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
          child: const Icon(Icons.shopping_cart, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                if (data!['category'] != null &&
                    data!['category'].toString().isNotEmpty)
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
                      (data!['category']?.toString().isNotEmpty ?? false)
                          ? data!['category']
                          : "Category info unavailable",
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
                  (data!['material']?.toString().isNotEmpty ?? false)
                      ? data!['material']
                      : "Material info unavailable",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 10),

                // Source and Responsibility
                if (data!['source'] != null &&
                    data!['source'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Source: ' +
                          ((data!['source']?.toString().isNotEmpty ?? false)
                              ? data!['source']
                              : "N/A"),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                if (data!['responsibility'] != null &&
                    data!['responsibility'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Responsibility: ' +
                          ((data!['responsibility']?.toString().isNotEmpty ??
                                  false)
                              ? data!['responsibility']
                              : "N/A"),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                // Delivery Dates
                if (data!['revisedDelivery'] != null &&
                    data!['revisedDelivery'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 14,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(data!['revisedDelivery'].toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Related Meetings
                if (data!['relatedMeetings'] != null &&
                    (data!['relatedMeetings'] as List).isNotEmpty)
                  _buildRelatedSection(
                    'Related Meetings',
                    data!['relatedMeetings'],
                    Icons.event,
                    Colors.orange,
                  ),

                // Related Tasks
                if (data!['relatedTasks'] != null &&
                    (data!['relatedTasks'] as List).isNotEmpty)
                  _buildRelatedSection(
                    'Related Tasks',
                    data!['relatedTasks'],
                    Icons.task,
                    Colors.blue,
                  ),

                // Related Notes
                if (data!['relatedNotes'] != null &&
                    (data!['relatedNotes'] as List).isNotEmpty)
                  _buildRelatedSection(
                    'Related Notes',
                    data!['relatedNotes'],
                    Icons.note,
                    Colors.purple,
                  ),
              ],
            ),
          ),
        ),
      ],
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
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
