import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/api_service.dart';

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
        // Parse categories from API response
        _categories = (response['categories'] as List).map((cat) {
          return CategoryItem(
            icon: _getCategoryIcon(cat['name']),
            title: cat['name'],
            files: '${cat['count']} ${cat['count'] == 1 ? 'file' : 'files'}',
            documents: cat['files'],
          );
        }).toList();

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
      // Pick category first
      String? selectedCategory = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Site Photos'),
                onTap: () => Navigator.pop(context, 'Site Photos'),
              ),
              ListTile(
                title: const Text('Blueprints'),
                onTap: () => Navigator.pop(context, 'Blueprints'),
              ),
              ListTile(
                title: const Text('Progress Reports'),
                onTap: () => Navigator.pop(context, 'Progress Reports'),
              ),
              ListTile(
                title: const Text('Videos'),
                onTap: () => Navigator.pop(context, 'Videos'),
              ),
            ],
          ),
        ),
      );

      if (selectedCategory == null) return;

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Use ApiService to upload
        await ApiService.uploadDocument(file, selectedCategory);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showSnackBar('File uploaded successfully');
          _loadDocuments(); // Refresh list
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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

class CategoryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blue.shade300, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: DocumentsPage.primaryBlue, size: 38),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    files,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 112, 110, 110),
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
      _filteredDocuments = widget.documents
          .where((doc) => doc['filename'].toLowerCase().contains(query))
          .toList();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Refresh parent
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
                              doc['fileType'] == 'image'
                                  ? Icons.image
                                  : doc['fileType'] == 'video'
                                  ? Icons.videocam
                                  : doc['fileType'] == 'blueprint'
                                  ? Icons.description
                                  : Icons.insert_drive_file,
                              color: DocumentsPage.primaryBlue,
                              size: 32,
                            ),
                            title: Text(
                              doc['filename'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatFileSize(doc['size'])} • ${doc['fileType']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _deleteDocument(doc['id'], doc['filename']),
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
