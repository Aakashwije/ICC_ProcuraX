import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

    // Load settings from MongoDB automatically
    _loadSettings();

    _loadProfileImage();
  }

  @override
  void dispose() {
    // Clean up controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {}

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Resize to save bandwidth
        maxHeight: 512,
        imageQuality: 85, // Compress image
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // Automatically upload after selection
        await _uploadProfileImage();

        if (kDebugMode) {
          debugPrint('✅ Image selected: ${image.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error picking image: $e');
      }
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      // Check if camera is available
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

        // Automatically upload after capture
        await _uploadProfileImage();

        if (kDebugMode) {
          debugPrint('✅ Photo captured: ${image.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error taking photo: $e');
      }
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  //Show dialog to choose image source
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
                if (_profileImage != null) ...[
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

  // Upload profile image to backend
  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // TODO: Implement actual API call to upload image
      // await ApiService.uploadProfileImage(_profileImage!);

      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _showSuccessSnackBar('Profile picture updated successfully');
      }

      if (kDebugMode) {
        debugPrint('✅ Profile image uploaded');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error uploading image: $e');
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

  // Remove profile image
  Future<void> _removeProfileImage() async {
    setState(() {
      _profileImage = null;
      _isUploading = true;
    });

    try {
      // TODO: Implement API call to remove image
      // await ApiService.removeProfileImage();

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSuccessSnackBar('Profile picture removed');
      }

      if (kDebugMode) {
        debugPrint('✅ Profile image removed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error removing image: $e');
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

  /// Show success snackbar
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

  /// Show error snackbar
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
        debugPrint('📱 Loaded settings from MongoDB: $settings');
      }

      if (!mounted) return;
      setState(() {
        selectedTheme = settings['theme'] ?? 'Light';
        selectedTimezone = settings['timezone'] ?? 'UTC';
        role = settings['role'] ?? 'Project Manager';
        department = settings['department'] ?? 'Construction';
        defaultProject = settings['defaultProject'] ?? 'Tower A - Downtown';
      });

      // Update app theme immediately
      if (mounted) {
        final themeNotifier = context.read<ThemeNotifier>();
        themeNotifier.setTheme(selectedTheme);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error loading settings from backend: $e');
      }
      // Use default values if API fails
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
        debugPrint('✅ Settings saved to MongoDB silently');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error saving settings: $e');
      }
    }
  }

  void _handleThemeChange(String value) {
    setState(() => selectedTheme = value);

    // Update app theme
    final themeNotifier = context.read<ThemeNotifier>();
    themeNotifier.setTheme(value);

    // Save to MongoDB silently
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

  /// Widget for profile picture section (extracted for clarity)
  Widget _buildProfilePictureSection(
    Color fieldBg,
    Color blue,
    Color lightBlue,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Image Container
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
                    : null,
                border: Border.all(color: blue.withOpacity(0.3), width: 2),
              ),
              child: _profileImage == null
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
        // Buttons Column
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
              // ---------- HEADER (your original code) ----------
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

              // ---------- SETTINGS CONTENT ----------
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: blue))
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // ---------- Profile Card ----------
                            _card(
                              cardBg,
                              blue,
                              lightBlue,
                              Icons.person_outline,
                              "Profile",
                              "Update your personal info",
                              Column(
                                children: [
                                  // Profile Picture
                                  Row(
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: fieldBg,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${firstName[0]}${lastName[0]}",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: blue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          OutlinedButton(
                                            onPressed: () {},
                                            child: const Text("Change Photo"),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "JPG, PNG or GIF. Max size 2MB",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: lightBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                                ],
                              ),
                            ),

                            // ---------- Role & Department Card ----------
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

                            // ---------- Display Preferences Card ----------
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

                            // ---------- About Card ----------
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

  // ---------- REUSABLE WIDGETS ----------
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
          Text(label, style: TextStyle(color: Colors.grey[400])),
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
        ),
      ),
    );
  }

  Widget _aboutRow(String l, String r, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(color: c)),
        Text(r, style: TextStyle(color: c)),
      ],
    );
  }

  Widget _aboutButton(String text, Color bg, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: textColor,
          elevation: 0,
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
