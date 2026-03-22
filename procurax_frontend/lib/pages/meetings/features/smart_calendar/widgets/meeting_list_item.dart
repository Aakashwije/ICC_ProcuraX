import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meeting.dart';
import '../../../theme.dart';
import '../services/meeting_location_service.dart';

class MeetingListItem extends StatefulWidget {
  final Meeting meeting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkDone;

  const MeetingListItem({
    super.key,
    required this.meeting,
    this.onEdit,
    this.onDelete,
    this.onMarkDone,
  });

  @override
  State<MeetingListItem> createState() => _MeetingListItemState();
}

class _MeetingListItemState extends State<MeetingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  DistanceInfo? _distanceInfo;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDistance();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Loads distance from current user position to meeting location.
  Future<void> _loadDistance() async {
    final meeting = widget.meeting;
    if (!meeting.hasCoordinates || meeting.isDone) return;

    final info = await MeetingLocationService.getDistanceToLocation(
      meetingLat: meeting.latitude!,
      meetingLng: meeting.longitude!,
    );
    if (info != null && mounted) {
      setState(() => _distanceInfo = info);
    }
  }

  /// Opens Google Maps with navigation to the meeting location.
  /// Prefers GPS coordinates; falls back to address search.
  Future<void> _openInMaps() async {
    final meeting = widget.meeting;
    if (meeting.location.trim().isEmpty) return;

    Uri uri;
    if (meeting.hasCoordinates) {
      // Precise navigation using lat/lng
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${meeting.latitude},${meeting.longitude}'
        '&travelmode=driving',
      );
    } else {
      // Fallback: search by address text
      final encoded = Uri.encodeComponent(meeting.location);
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encoded',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.meeting.isDone;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isDone
              ? Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Done indicator badge
                if (isDone)
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    widget.meeting.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDone ? Colors.grey[600] : primaryBlue,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey[400],
                    ),
                  ),
                ),
                // Done/Undo button
                _buildDoneButton(isDone),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: isDone ? Colors.grey[400] : primaryBlue,
                  ),
                  tooltip: 'Edit meeting',
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete meeting',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isDone ? Colors.grey[400] : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.meeting.timeRange,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? Colors.grey[400] : Colors.grey,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            if (widget.meeting.location.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _openInMaps,
                child: Row(
                  children: [
                    Icon(
                      widget.meeting.hasCoordinates
                          ? Icons.place_rounded
                          : Icons.place_outlined,
                      size: 14,
                      color: isDone
                          ? Colors.grey[400]
                          : widget.meeting.hasCoordinates
                          ? primaryBlue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.meeting.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone
                              ? Colors.grey[400]
                              : widget.meeting.hasCoordinates
                              ? primaryBlue
                              : Colors.grey,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : widget.meeting.hasCoordinates
                              ? TextDecoration.underline
                              : null,
                          decorationColor: primaryBlue.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.meeting.hasCoordinates && !isDone)
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: primaryBlue,
                      ),
                  ],
                ),
              ),
            ],
            // Distance & travel time chips
            if (_distanceInfo != null && !isDone) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _infoChip(
                    icon: Icons.straighten_rounded,
                    label: _distanceInfo!.formattedDistance,
                    color: primaryBlue,
                  ),
                  _infoChip(
                    icon: Icons.directions_car_rounded,
                    label: _distanceInfo!.formattedTravelTime,
                    color: _distanceInfo!.travelTimeMinutes > 60
                        ? Colors.orange.shade700
                        : const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
            if (widget.meeting.description.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.meeting.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDone ? Colors.grey[500] : Colors.black87,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(bool isDone) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _animationController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _animationController.reverse();
      },
      onTap: widget.onMarkDone,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: isDone
              ? null
              : LinearGradient(
                  colors: _isPressed
                      ? [const Color(0xFF388E3C), const Color(0xFF43A047)]
                      : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDone ? Colors.grey[200] : null,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isDone
              ? null
              : [
                  BoxShadow(
                    color: Colors.green.withValues(
                      alpha: _isPressed ? 0.4 : 0.25,
                    ),
                    blurRadius: _isPressed ? 8 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isDone ? Icons.undo_rounded : Icons.check_rounded,
            key: ValueKey(isDone),
            color: isDone ? Colors.grey[600] : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
