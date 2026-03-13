import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/permission_service.dart';
import 'package:procurax_frontend/theme/app_theme.dart';

class PermissionRequestDialog extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionRequestDialog({Key? key, required this.onPermissionsGranted})
    : super(key: key);

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _isRequesting = false;

  Future<void> _requestAllPermissions() async {
    setState(() => _isRequesting = true);

    try {
      final results = await PermissionService.requestAllPermissions();

      if (!mounted) return;

      // Show summary of granted permissions
      _showPermissionSummary(results);

      // Close dialog and continue
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPermissionsGranted();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting permissions: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _showPermissionSummary(Map<String, bool> results) {
    final granted = results.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final denied = results.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (granted.isNotEmpty) ...[
              const Text(
                'Granted:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(granted.join(', ')),
              const SizedBox(height: 12),
            ],
            if (denied.isNotEmpty) ...[
              const Text(
                'Denied:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(denied.join(', ')),
              const SizedBox(height: 12),
            ],
            if (denied.isNotEmpty)
              const Text(
                'You can change these permissions later in your device settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'App Permissions Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ProcuraX needs the following permissions to work properly:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildPermissionItem(
              icon: Icons.image,
              label: 'Photos & Media',
              description: 'To upload images for documents and notes',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.camera_alt,
              label: 'Camera',
              description: 'To capture images for procurement updates',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.mic,
              label: 'Microphone',
              description: 'To record audio notes and meetings',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.storage,
              label: 'Files & Storage',
              description: 'To upload and manage documents',
            ),
            const SizedBox(height: 12),
            _buildPermissionItem(
              icon: Icons.notifications_active,
              label: 'Notifications',
              description: 'To receive project and task updates',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestAllPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Allow Permissions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isRequesting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Skip for Now',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
