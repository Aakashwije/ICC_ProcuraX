import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'theme_notifier.dart';
import 'services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedTheme = "Light";
  String selectedTimezone = "UTC";
  String role = "Project Manager";
  String department = "Construction";
  String defaultProject = "Tower A - Downtown";

  String firstName = "John";
  String lastName = "Doe";
  String email = "john.doe@company.com";
  String phone = "+1 (555) 123-4567";
  String? profileImageUrl; //store image URL from backend

  bool isLoading = false;

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

    // Load all data
    _loadSettings();
    _loadUserProfile(); // load user profile
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Contact Support Button Method
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
        // Fallback - copy email to clipboard
        await Clipboard.setData(
          const ClipboardData(text: 'support@procurax.com'),
        );
        _showSuccessSnackBar('Email address copied to clipboard');
      }
    } catch (e) {
      _showErrorSnackBar('Could not open email client');
    }
  }

  // Privacy Policy Button Method
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

  // User profile loading
  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await ApiService.getUserProfile();
      if (mounted) {
        setState(() {
          firstName = userProfile['firstName'] ?? firstName;
          lastName = userProfile['lastName'] ?? lastName;
          email = userProfile['email'] ?? email;
          phone = userProfile['phone'] ?? phone;
          profileImageUrl = userProfile['profileImageUrl'];

          // Update controllers
          firstNameController.text = firstName;
          lastNameController.text = lastName;
          emailController.text = email;
          phoneController.text = phone;
        });

        if (kDebugMode) {
          debugPrint('📱 User profile loaded: $userProfile');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading user profile: $e');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
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

        if (kDebugMode) {
          debugPrint('Image selected: ${image.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking image: $e');
      }
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final bool cameraAvailable = await _picker.supportsImageSource(
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

        if (kDebugMode) {
          debugPrint('Photo captured: ${image.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error taking photo: $e');
      }
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

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            profileImageUrl = response['data']?['profileImageUrl'];
          });
          _showSuccessSnackBar('Profile picture updated successfully');
        }

        if (kDebugMode) {
          debugPrint('Profile image uploaded: $response');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading image: $e');
      }
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

      if (kDebugMode) {
        debugPrint('Profile image removed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error removing image: $e');
      }
      _showErrorSnackBar('Failed to remove image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

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
        selectedTheme = settings['theme'] ?? 'Light';
        selectedTimezone = settings['timezone'] ?? 'UTC';
        role = settings['role'] ?? 'Project Manager';
        department = settings['department'] ?? 'Construction';
        defaultProject = settings['defaultProject'] ?? 'Tower A - Downtown';
      });

      if (mounted) {
        final themeNotifier = context.read<ThemeNotifier>();
        themeNotifier.setTheme(selectedTheme);
      }
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
        'theme': selectedTheme,
        'timezone': selectedTimezone,
        'role': role,
        'department': department,
        'defaultProject': defaultProject,
      });

      if (kDebugMode) {
        debugPrint('Settings saved to MongoDB silently');
      }
      _showSuccessSnackBar('Settings saved successfully');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving settings: $e');
      }
      _showErrorSnackBar('Failed to save settings');
    }
  }

  // Save profile info
  Future<void> _saveProfileInfo() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.updateUserProfile({
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
        'phone': phoneController.text,
      });

      if (response['success'] == true) {
        setState(() {
          firstName = firstNameController.text;
          lastName = lastNameController.text;
          phone = phoneController.text;
        });
        _showSuccessSnackBar('Profile updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save profile: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _handleThemeChange(String value) {
    setState(() => selectedTheme = value);
    final themeNotifier = context.read<ThemeNotifier>();
    themeNotifier.setTheme(value);
    _saveSettings();
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

  // show both local and server images
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
                border: Border.all(color: blue.withOpacity(0.3), width: 2),
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
                    color: Colors.black.withOpacity(0.5),
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
    const Color primaryBlue = Color(0xFF1F4CCF);

    final themeNotifier = context.watch<ThemeNotifier>();
    final isDark = themeNotifier.themeMode == ThemeMode.dark;

    final bg = isDark ? Colors.black : const Color(0xFFF8FAFC);
    final cardBg = isDark ? Colors.grey[900]! : Colors.white;
    final fieldBg = isDark ? Colors.grey[800]! : const Color(0xFFDCE7F1);
    final blue = isDark ? Colors.white : primaryBlue;
    final lightBlue = isDark ? Colors.grey[400]! : const Color(0xFF769BC5);

    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.settings),
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu_rounded, size: 30, color: blue),
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
                            // Profile Card - working profile picture section
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
                                    isEditable: false,
                                  ),
                                  _input(
                                    "Phone Number",
                                    phoneController,
                                    fieldBg,
                                  ),

                                  const SizedBox(height: 8),

                                  // Save Profile Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _saveProfileInfo,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Save Profile Changes'),
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

                            // Display Preferences Card
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.palette_outlined,
                              "Display Preferences",
                              "Customize appearance",
                              Column(
                                children: [
                                  _dropdown(
                                    "Theme",
                                    selectedTheme,
                                    ["Light", "Dark"],
                                    fieldBg,
                                    _handleThemeChange,
                                  ),
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
                                  ),
                                  const SizedBox(height: 8),
                                  _aboutButton("Privacy Policy", fieldBg, blue),
                                  const SizedBox(height: 8),
                                  _aboutButton(
                                    "Terms of Service",
                                    fieldBg,
                                    blue,
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
        value: value,
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

  Widget _aboutButton(String text, Color bg, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: textColor.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          // TODO: Add action or navigation
        },
        child: Text(text),
      ),
    );
  }
}
