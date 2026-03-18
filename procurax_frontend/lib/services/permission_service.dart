import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionService {
  /// Request storage permissions (for file picker, document uploads)
  static Future<bool> requestStoragePermission() async {
    final status = await ph.Permission.storage.request();
    return status.isGranted;
  }

  /// Request photo library permission (for image picker)
  static Future<bool> requestPhotoLibraryPermission() async {
    final status = await ph.Permission.photos.request();
    return status.isGranted;
  }

  /// Request camera permission (for image capture)
  static Future<bool> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return status.isGranted;
  }

  /// Request microphone permission (for audio notes and meetings)
  static Future<bool> requestMicrophonePermission() async {
    final status = await ph.Permission.microphone.request();
    return status.isGranted;
  }

  /// Request notification permission (for push notifications)
  static Future<bool> requestNotificationPermission() async {
    final status = await ph.Permission.notification.request();
    return status.isGranted;
  }

  /// Request all necessary permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    final permissions = {
      'storage': await requestStoragePermission(),
      'photos': await requestPhotoLibraryPermission(),
      'camera': await requestCameraPermission(),
      'microphone': await requestMicrophonePermission(),
      'notifications': await requestNotificationPermission(),
    };
    return permissions;
  }

  /// Check if a specific permission is granted
  static Future<bool> isPermissionGranted(ph.Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
