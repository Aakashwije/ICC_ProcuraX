import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/theme/app_theme.dart';
import 'services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedTimezone = "UTC";
  String role = "Project Manager";
  String department = "Construction";
  String defaultProject = "Tower A - Downtown";

  String firstName = "Dhasun";
  String lastName = "Jayarathna";
  String email = "dhasun.jayarathna@company.com";
  String phone = "+94 77 123 4567";
  String? profileImageUrl;

  bool isLoading = false;
  bool _isSaving = false;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // Text controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    firstNameController = TextEditingController(text: firstName);
    lastNameController = TextEditingController(text: lastName);
    emailController = TextEditingController(text: email);
    phoneController = TextEditingController(text: phone);

    // Load token into ApiService first
    _initializeSettings();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ===== HELPER METHODS =====
  int min(int a, int b) => a < b ? a : b;

  // Check if user is logged in by looking for token
  Future<bool> _isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenFromPrefs = prefs.getString('auth_token');
      final apiServiceHasToken = ApiService.hasToken();

      if (kDebugMode) {
        debugPrint('🔑 Token in SharedPreferences: ${tokenFromPrefs != null}');
        debugPrint('🔑 Token in ApiService: $apiServiceHasToken');
      }

      return (tokenFromPrefs != null && tokenFromPrefs.isNotEmpty) ||
          apiServiceHasToken;
    } catch (e) {
      return false;
    }
  }

  // Load token from SharedPreferences into ApiService
  Future<void> _loadTokenIntoApiService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        await ApiService.setAuthToken(token);
        if (kDebugMode) {
          debugPrint(
            'Token manually loaded into ApiService: ${token.substring(0, min(20, token.length))}...',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading token: $e');
      }
    }
  }

  // Initialize settings - load token first, then load data
  Future<void> _initializeSettings() async {
    await _loadTokenIntoApiService();
    final isLoggedIn = await _isLoggedIn();
    if (kDebugMode) {
      debugPrint('🔑 Final login status: $isLoggedIn');
    }
    _loadSettings();
    _loadUserProfile();
  }

  // ===== SAVE PROFILE METHOD =====
  Future<void> _saveProfile() async {
    final isLoggedIn = await _isLoggedIn();
    if (!isLoggedIn) {
      _showErrorSnackBar('You must be logged in to save changes');
      return;
    }

    if (firstNameController.text == firstName &&
        lastNameController.text == lastName &&
        emailController.text == email &&
        phoneController.text == phone) {
      _showSuccessSnackBar('No changes to save');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await ApiService.updateUserProfile({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
      });

      if (response['success'] == true) {
        setState(() {
          firstName = firstNameController.text;
          lastName = lastNameController.text;
          email = emailController.text;
          phone = phoneController.text;
        });
        _showSuccessSnackBar('Profile saved successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ===== CONTACT SUPPORT METHODS =====
  Future<void> _launchContactSupport() async {
    final String supportEmail = 'support@procurax.com';
    final String subject = Uri.encodeComponent(
      'Support Request from ProcuraX App',
    );
    final String body = Uri.encodeComponent('''
App Version: 2.4.1
Device: ${Platform.operatingSystem}
User: $firstName $lastName
Email: $email

Issue Description:
(Please describe your issue here)
''');

    final Uri emailUri = Uri.parse(
      'mailto:$supportEmail?subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Opening email client...');
      } else {
        await Clipboard.setData(
          const ClipboardData(text: 'support@procurax.com'),
        );
        _showSuccessSnackBar('Email address copied to clipboard');
      }
    } catch (e) {
      _showErrorSnackBar('Could not open email client');
    }
  }

  // ===== CONTACT SUPPORT DIALOG METHOD =====
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.support_agent,
                color: const Color(0xFF1F4CCF),
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Contact Support',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help with ProcuraX? Our support team is here to assist you.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Email Support
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4CCF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        color: Color(0xFF1F4CCF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Email Support',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'support@procurax.com',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: const Color(0xFF1F4CCF),
                        size: 20,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'support@procurax.com'),
                        );
                        Navigator.pop(context);
                        _showSuccessSnackBar('Email copied to clipboard');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Phone Support
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4CCF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFF1F4CCF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone Support',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+1 (800) 123-4567',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: const Color(0xFF1F4CCF),
                        size: 20,
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: '+1 (800) 123-4567'),
                        );
                        Navigator.pop(context);
                        _showSuccessSnackBar(
                          'Phone number copied to clipboard',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Response Time
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1F4CCF).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: const Color(0xFF1F4CCF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Response Time',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Within 24 hours on weekdays',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Operating Hours
              Text(
                'Monday - Friday: 9:00 AM - 6:00 PM (EST)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _launchContactSupport(); // Opens email client
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F4CCF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Send Email'),
            ),
          ],
        );
      },
    );
  }

  // ===== PRIVACY POLICY METHODS =====
  Future<void> _launchPrivacyPolicy() async {
    const String url = 'https://www.procurax.com/privacy';
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Opening Privacy Policy...');
      } else {
        _showPrivacyPolicyDialog();
      }
    } catch (e) {
      _showPrivacyPolicyDialog();
    }
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const Text(
            'We value your privacy. Your data is encrypted and securely stored. '
            'We never share your personal information with third parties without your consent.\n\n'
            'For the full privacy policy, please visit:\n'
            'www.procurax.com/privacy',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(text: 'https://www.procurax.com/privacy'),
                );
                Navigator.pop(context);
                _showSuccessSnackBar('URL copied to clipboard');
              },
              child: const Text('Copy URL'),
            ),
          ],
        );
      },
    );
  }

  // ===== TERMS OF SERVICE METHODS =====
  Future<void> _launchTermsOfService() async {
    const String url = 'https://www.procurax.com/terms';
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Opening Terms of Service...');
      } else {
        _showTermsDialog();
      }
    } catch (e) {
      _showTermsDialog();
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const Text(
            'By using ProcuraX, you agree to:\n\n'
            '• Version 2.4.1\n'
            '• Last updated: November 2, 2025\n'
            '• Your data is handled securely\n'
            '• You must be 18+ to use this service\n\n'
            'For the complete terms, visit:\n'
            'www.procurax.com/terms',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(text: 'https://www.procurax.com/terms'),
                );
                Navigator.pop(context);
                _showSuccessSnackBar('URL copied to clipboard');
              },
              child: const Text('Copy URL'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String buttonText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(buttonText),
          content: const Text('This feature is coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ===== PROFILE LOADING =====
  Future<void> _loadUserProfile() async {
    final isLoggedIn = await _isLoggedIn();
    if (!isLoggedIn) return;

    try {
      final userProfile = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          firstName = userProfile['firstName'] ?? firstName;
          lastName = userProfile['lastName'] ?? lastName;
          email = userProfile['email'] ?? email;
          phone = userProfile['phone'] ?? phone;

          final loadedUrl = userProfile['profileImageUrl'];
          profileImageUrl = (loadedUrl is String && loadedUrl.isNotEmpty)
              ? loadedUrl
              : null;

          // Update controllers
          firstNameController.text = firstName;
          lastNameController.text = lastName;
          emailController.text = email;
          phoneController.text = phone;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  // ===== IMAGE PICKER METHODS =====
  Future<bool> _ensurePhotoPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final primaryPermission = Platform.isIOS
        ? Permission.photos
        : Permission.photos;
    final secondaryPermission = Platform.isAndroid ? Permission.storage : null;

    final primaryStatus = await primaryPermission.status;
    if (primaryStatus.isGranted) return true;

    final primaryResult = await primaryPermission.request();
    if (primaryResult.isGranted) return true;

    if (secondaryPermission != null) {
      final secondaryStatus = await secondaryPermission.status;
      if (secondaryStatus.isGranted) return true;

      final secondaryResult = await secondaryPermission.request();
      if (secondaryResult.isGranted) return true;

      if (secondaryResult.isPermanentlyDenied) {
        _showPermissionSettingsDialog();
      }
    }

    if (primaryResult.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
    }

    return false;
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'To pick an image, the app needs access to your photos. Please enable permission in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (!await _ensurePhotoPermission()) {
        _showErrorSnackBar('Permission required to access gallery');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      if (!await _ensurePhotoPermission()) {
        _showErrorSnackBar('Permission required to use the camera');
        return;
      }

      final bool cameraAvailable = _picker.supportsImageSource(
        ImageSource.camera,
      );

      if (!cameraAvailable) {
        _showErrorSnackBar('Camera is not available on this device');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        await _uploadProfileImage();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Picture'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF1F4CCF),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: Color(0xFF1F4CCF),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePhotoWithCamera();
                  },
                ),
                if (_profileImage != null || profileImageUrl != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Current Photo'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _removeProfileImage();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.uploadProfileImage(_profileImage!);

      final dynamic dataNode = response['data'];
      final String? uploadedUrl =
          (dataNode is Map<String, dynamic>
                  ? (dataNode['profileImageUrl'] ?? dataNode['profileImage'])
                  : null)
              as String? ??
          response['profileImageUrl'] as String? ??
          response['profileImage'] as String?;

      final bool isSuccess = response['success'] == true || uploadedUrl != null;

      if (!isSuccess) {
        final backendMessage = response['message'] ?? response['error'];
        throw Exception(
          backendMessage is String && backendMessage.isNotEmpty
              ? backendMessage
              : 'Upload failed',
        );
      }

      if (mounted) {
        setState(() {
          _profileImage = null;
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            profileImageUrl = uploadedUrl;
          }
        });
        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() {
      _profileImage = null;
      _isUploading = true;
    });

    try {
      await ApiService.removeProfileImage();

      if (mounted) {
        setState(() {
          profileImageUrl = null;
        });
        _showSuccessSnackBar('Profile picture removed');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to remove image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // ===== SNACKBAR METHODS =====
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===== SETTINGS METHODS =====
  Future<void> _loadSettings() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final settings = await ApiService.getSettings();
      if (kDebugMode) {
        debugPrint('Loaded settings from MongoDB: $settings');
      }

      if (!mounted) return;
      setState(() {
        selectedTimezone = settings['timezone'] ?? 'UTC';
        role = settings['role'] ?? 'Project Manager';
        department = settings['department'] ?? 'Construction';
        defaultProject = settings['defaultProject'] ?? 'Tower A - Downtown';
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading settings from backend: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ApiService.updateMultipleSettings({
        'timezone': selectedTimezone,
        'role': role,
        'department': department,
        'defaultProject': defaultProject,
      });

      if (kDebugMode) {
        debugPrint('Settings saved to MongoDB silently');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving settings: $e');
      }
    }
  }

  void _handleTimezoneChange(String value) {
    setState(() => selectedTimezone = value);
    _saveSettings();
  }

  void _handleRoleChange(String value) {
    setState(() => role = value);
    _saveSettings();
  }

  void _handleDepartmentChange(String value) {
    setState(() => department = value);
    _saveSettings();
  }

  void _handleProjectChange(String value) {
    setState(() => defaultProject = value);
    _saveSettings();
  }

  // ===== UI BUILD METHODS =====
  Widget _buildProfilePictureSection(
    Color fieldBg,
    Color blue,
    Color lightBlue,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fieldBg,
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : (profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(profileImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                border: Border.all(color: blue.withValues(alpha: 0.3), width: 2),
              ),
              child: (_profileImage == null && profileImageUrl == null)
                  ? Center(
                      child: Text(
                        "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: blue,
                        ),
                      ),
                    )
                  : null,
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _showImageSourceDialog,
                      icon: Icon(
                        _isUploading ? Icons.hourglass_empty : Icons.camera_alt,
                        size: 18,
                      ),
                      label: Text(
                        _isUploading ? 'Uploading...' : 'Change Photo',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "JPG, PNG or GIF. Max size 2MB",
                style: TextStyle(fontSize: 11, color: lightBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = AppColors.primary;

    final bg = AppColors.neutral50;
    final cardBg = Colors.white;
    final fieldBg = AppColors.primaryLight;
    final blue = primaryBlue;
    final lightBlue = AppColors.primaryLight;

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.settings),
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Builder(
                    builder: (context) => Semantics(
                      label: 'Open navigation menu',
                      button: true,
                      child: IconButton(
                        tooltip: 'Menu',
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: Icon(Icons.menu_rounded, size: 30, color: blue),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: blue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: blue,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 24),

              // Settings Content
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: blue))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Profile Card
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.person_outline,
                              "Profile",
                              "Update your personal info",
                              Column(
                                children: [
                                  _buildProfilePictureSection(
                                    fieldBg,
                                    blue,
                                    lightBlue,
                                  ),
                                  const SizedBox(height: 20),

                                  // Input Fields
                                  _input(
                                    "First Name",
                                    firstNameController,
                                    fieldBg,
                                  ),
                                  _input(
                                    "Last Name",
                                    lastNameController,
                                    fieldBg,
                                  ),
                                  _input(
                                    "Email",
                                    emailController,
                                    fieldBg,
                                    isEditable: true,
                                  ),
                                  _input(
                                    "Phone Number",
                                    phoneController,
                                    fieldBg,
                                  ),

                                  const SizedBox(height: 16),

                                  // Save Profile Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isSaving
                                          ? null
                                          : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blue,
                                        foregroundColor: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Save Changes',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Role & Department Card
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.badge_outlined,
                              "Role & Department",
                              "Configure your role",
                              Column(
                                children: [
                                  _dropdown(
                                    "Role",
                                    role,
                                    [
                                      "Project Manager",
                                      "Engineer",
                                      "Site Worker",
                                      "Architect",
                                      "Contractor",
                                    ],
                                    fieldBg,
                                    _handleRoleChange,
                                  ),
                                  _dropdown(
                                    "Department",
                                    department,
                                    [
                                      "Construction",
                                      "IT",
                                      "Engineering",
                                      "Design",
                                      "Management",
                                    ],
                                    fieldBg,
                                    _handleDepartmentChange,
                                  ),
                                  _dropdown(
                                    "Default Project",
                                    defaultProject,
                                    [
                                      "Tower A - Downtown",
                                      "Tower B - Uptown",
                                      "Bridge Project",
                                      "Hospital Renovation",
                                    ],
                                    fieldBg,
                                    _handleProjectChange,
                                  ),
                                ],
                              ),
                            ),

                            // Display Preferences Card - TIMEZONE ONLY
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.tune_outlined,
                              "App Preferences",
                              "Customize your application experience",
                              Column(
                                children: [
                                  _dropdown(
                                    "Timezone",
                                    selectedTimezone,
                                    [
                                      "UTC",
                                      "Pacific Time (PST)",
                                      "Eastern Time (EST)",
                                      "Central Time (CST)",
                                      "Mountain Time (MST)",
                                    ],
                                    fieldBg,
                                    _handleTimezoneChange,
                                  ),
                                ],
                              ),
                            ),

                            // About Card
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.info_outline,
                              "About",
                              "Application info",
                              Column(
                                children: [
                                  _aboutRow("Version", "2.4.1", lightBlue),
                                  const Divider(),
                                  _aboutRow(
                                    "Last Updated",
                                    "Nov 2, 2025",
                                    lightBlue,
                                  ),
                                  const Divider(),
                                  _aboutRow("Database", "MongoDB", lightBlue),
                                  const SizedBox(height: 16),
                                  _aboutButton(
                                    "Contact Support",
                                    fieldBg,
                                    blue,
                                    onPressed: _showContactSupportDialog,
                                  ),
                                  const SizedBox(height: 8),
                                  _aboutButton(
                                    "Privacy Policy",
                                    fieldBg,
                                    blue,
                                    onPressed: _launchPrivacyPolicy,
                                  ),
                                  const SizedBox(height: 8),
                                  _aboutButton(
                                    "Terms of Service",
                                    fieldBg,
                                    blue,
                                    onPressed: _launchTermsOfService,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets
  Widget _card(
    Color bg,
    Color blue,
    Color lightBlue,
    IconData icon,
    String title,
    String subtitle,
    Widget child,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: lightBlue)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    Color bg, {
    bool isEditable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: isEditable,
            decoration: InputDecoration(
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    Color bg,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: bg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _aboutRow(String l, String r, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: c, fontSize: 14)),
          Text(
            r,
            style: TextStyle(
              color: c,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutButton(
    String text,
    Color bg,
    Color textColor, {
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: textColor.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed ?? () => _showInfoDialog(text),
        child: Text(text),
      ),
    );
  }
}
