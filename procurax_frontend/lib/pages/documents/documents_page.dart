import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/api_service.dart';
import 'package:procurax_frontend/widgets/custom_toast.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  static const Color primaryBlue = Color(0xFF1F4CCF);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryItem> _categories = [];
  List<CategoryItem> _filteredCategories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use your existing ApiService
      final response = await ApiService.getDocuments();

      setState(() {
        // Parse categories from API response with null safety
        final categoriesData = response['categories'];

        // Ensure we always show the 4 core categories even when there are no files
        const coreCategories = [
          'Site Photos',
          'Blueprints',
          'Progress Reports',
          'Videos',
        ];

        // Build a lookup for categories returned by the API
        final apiCategories = <String, dynamic>{};
        if (categoriesData != null && categoriesData is List) {
          for (final cat in categoriesData) {
            if (cat is Map && cat['name'] != null) {
              apiCategories[cat['name']] = cat;
            }
          }
        }

        // Start with the core categories (always shown), then append any extra categories
        _categories = [
          for (final name in coreCategories)
            () {
              final cat = apiCategories[name];
              final count = (cat != null && cat['count'] is int)
                  ? cat['count'] as int
                  : 0;
              final files = (cat != null && cat['files'] is List)
                  ? cat['files'] as List<dynamic>
                  : <dynamic>[];
              return CategoryItem(
                icon: _getCategoryIcon(name),
                title: name,
                files: '$count ${count == 1 ? 'file' : 'files'}',
                documents: files,
              );
            }(),
          // Add any non-core categories returned by the API
          for (final entry in apiCategories.entries)
            if (!coreCategories.contains(entry.key))
              () {
                final cat = entry.value;
                final count = (cat != null && cat['count'] is int)
                    ? cat['count'] as int
                    : 0;
                final files = (cat != null && cat['files'] is List)
                    ? cat['files'] as List<dynamic>
                    : <dynamic>[];
                return CategoryItem(
                  icon: _getCategoryIcon(entry.key),
                  title: entry.key,
                  files: '$count ${count == 1 ? 'file' : 'files'}',
                  documents: files,
                );
              }(),
        ];

        _filteredCategories = List.from(_categories);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Site Photos':
        return Icons.image_outlined;
      case 'Blueprints':
        return Icons.description_outlined;
      case 'Progress Reports':
        return Icons.assignment_outlined;
      case 'Videos':
        return Icons.videocam_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _categories
          .where((category) => category.title.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _uploadFile() async {
    try {
      // 1) Pick a category
      final selectedCategory = await _showUploadCategoryDialog();
      if (selectedCategory == null) return;

      // 2) Pick upload source (Gallery vs Device)
      final uploadSource = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Upload Source',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose where you want to pick the file from.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery (images)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: DocumentsPage.primaryBlue,
                  ),
                  onPressed: () => Navigator.pop(context, 'gallery'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('From Device (any file)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: DocumentsPage.primaryBlue,
                  ),
                  onPressed: () => Navigator.pop(context, 'device'),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );

      if (uploadSource == null) return;

      FilePickerResult? result;
      if (uploadSource == 'gallery') {
        result = await FilePicker.platform.pickFiles(type: FileType.image);
      } else {
        result = await FilePicker.platform.pickFiles(type: FileType.any);
      }

      if (result == null || result.files.isEmpty) return;
      if (!mounted) return;

      final file = File(result.files.single.path!);

      // Show beautiful loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DocumentsPage.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      size: 48,
                      color: DocumentsPage.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Uploading...',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: DocumentsPage.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please wait while we upload your file',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      DocumentsPage.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Use ApiService to upload
        await ApiService.uploadDocument(file, selectedCategory);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showSuccessDialog('File uploaded successfully!');
          _loadDocuments(); // Refresh list
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        _showErrorDialog('Error: $e');
      }
    }
  }

  Widget _buildCategoryOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_rounded,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.documents),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row (Menu + Title)
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 30,
                        color: DocumentsPage.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "Documents & Media",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: DocumentsPage.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              // Search bar
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 219, 228, 241),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search categories...',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DocumentsPage.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              // Categories list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadDocuments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredCategories.isEmpty
                    ? const Center(child: Text('No categories found.'))
                    : ListView.builder(
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          return CategoryCard(
                            icon: category.icon,
                            title: category.title,
                            files: category.files,
                            documents: category.documents,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryFilesPage(
                                    categoryTitle: category.title,
                                    documents: category.documents,
                                  ),
                                ),
                              ).then((_) => _loadDocuments());
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DocumentsPage.primaryBlue,
        onPressed: _uploadFile,
        child: const Icon(Icons.upload, color: Colors.white),
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String files;
  final List<dynamic> documents;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.files,
    required this.documents,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isExpanded = false;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'blueprint':
      case 'pdf':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: DocumentsPage.primaryBlue,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: DocumentsPage.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.files,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 112, 110, 110),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: DocumentsPage.primaryBlue,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content (files list)
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (widget.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No files in ${widget.title}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.documents.length,
                  itemBuilder: (context, index) {
                    final doc = widget.documents[index];
                    if (doc == null || doc is! Map) {
                      return const SizedBox.shrink();
                    }

                    final filename = doc['filename']?.toString() ?? 'Unknown';
                    final fileType = doc['fileType']?.toString() ?? 'file';
                    final fileSize = doc['size'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getFileIcon(fileType),
                            color: DocumentsPage.primaryBlue,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          filename,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_formatFileSize(fileSize)} • $fileType',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 20),
                              color: DocumentsPage.primaryBlue,
                              onPressed: () {
                                // Open file detail or view
                                widget.onTap();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class CategoryFilesPage extends StatefulWidget {
  final String categoryTitle;
  final List<dynamic> documents;

  const CategoryFilesPage({
    super.key,
    required this.categoryTitle,
    required this.documents,
  });

  @override
  State<CategoryFilesPage> createState() => _CategoryFilesPageState();
}

class _CategoryFilesPageState extends State<CategoryFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredDocuments = [];

  @override
  void initState() {
    super.initState();
    _filteredDocuments = List.from(widget.documents);
    _searchController.addListener(_applyFilter);
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDocuments = widget.documents.where((doc) {
        if (doc == null || doc is! Map) return false;
        final filename = doc['filename'];
        if (filename == null) return false;
        return filename.toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _deleteDocument(String documentId, String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Use ApiService to delete
      await ApiService.deleteDocument(documentId);

      setState(() {
        _filteredDocuments.removeWhere((doc) => doc['id'] == documentId);
      });

      if (mounted) {
        CustomToast.success(
          context,
          'The file has been removed from your documents',
          title: 'File Deleted',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          title: 'Delete Failed',
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: DocumentsPage.primaryBlue),
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(
            color: DocumentsPage.primaryBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 219, 228, 241),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search files...',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredDocuments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No files in ${widget.categoryTitle}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = _filteredDocuments[index];
                        if (doc == null || doc is! Map) {
                          return const SizedBox.shrink();
                        }

                        final filename =
                            doc['filename']?.toString() ?? 'Unknown';
                        final fileType = doc['fileType']?.toString() ?? 'file';
                        final fileSize = doc['size'] ?? 0;
                        final docId = doc['id']?.toString() ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color.fromARGB(255, 202, 210, 222),
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              fileType == 'image'
                                  ? Icons.image
                                  : fileType == 'video'
                                  ? Icons.videocam
                                  : fileType == 'blueprint'
                                  ? Icons.description
                                  : Icons.insert_drive_file,
                              color: DocumentsPage.primaryBlue,
                              size: 32,
                            ),
                            title: Text(
                              filename,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatFileSize(fileSize)} • $fileType',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _deleteDocument(docId, filename),
                            ),
                            onTap: () {
                              // Optional: Open/view file
                              // You can add file viewer functionality here
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem {
  final IconData icon;
  final String title;
  final String files;
  final List<dynamic> documents;

  CategoryItem({
    required this.icon,
    required this.title,
    required this.files,
    required this.documents,
  });
}
