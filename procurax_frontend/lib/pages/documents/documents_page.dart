


import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';


class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  static const Color primaryBlue = Color(0xFF1F4CCF);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_CategoryItem> _allCategories = const [
    _CategoryItem(
      icon: Icons.image_outlined,
      title: 'Site Photos',
      files: '3 files',
    ),
    _CategoryItem(
      icon: Icons.description_outlined,
      title: 'Blueprints',
      files: '3 files',
    ),
    _CategoryItem(
      icon: Icons.assignment_outlined,
      title: 'Progress Reports',
      files: '2 files',
    ),
    _CategoryItem(
      icon: Icons.videocam_outlined,
      title: 'Videos',
      files: '2 files',
    ),
  ];

  late List<_CategoryItem> _filteredCategories;

  @override
  void initState() {
    super.initState();
    _filteredCategories = List.from(_allCategories);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories
          .where((category) =>
              category.title.toLowerCase().contains(query))
          .toList();
    });
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
              //  Top row (Menu + Title)
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

              //  Search bar
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

              //  Categories list
              Expanded(
                child: _filteredCategories.isEmpty
                    ? const Center(
                        child: Text('No matching categories.'),
                      )
                    : ListView.builder(
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final category = _filteredCategories[index];
                          return _categoryCard(
                            context,
                            icon: category.icon,
                            title: category.title,
                            files: category.files,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  Category Card
  Widget _categoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String files,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _CategoryFilesPage(categoryTitle: title),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120, // Fixed height for category cards
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.blue.shade300,
            width: 1.5,
          )
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
              child: Icon(icon, color: DocumentsPage.primaryBlue , size: 38, ),
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

class _CategoryFilesPage extends StatefulWidget {
  const _CategoryFilesPage({required this.categoryTitle});

  final String categoryTitle;

  @override
  State<_CategoryFilesPage> createState() => _CategoryFilesPageState();
}

class _CategoryFilesPageState extends State<_CategoryFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _files = [];
  List<String> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _filteredFiles = List.from(_files);
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilter);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFiles = _files
          .where((file) => file.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addFile() {
    setState(() {
      _files.add('New File ${_files.length + 1}');
      _filteredFiles = List.from(_files);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File uploaded successfully'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(int index) {
    final fileName = _filteredFiles[index];
    final parentContext = context;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _files.remove(fileName);
                _filteredFiles = List.from(_files);
              });
              Navigator.pop(dialogContext);
              if (!mounted) {
                return;
              }
              ScaffoldMessenger.of(parentContext).showSnackBar(
                const SnackBar(
                  content: Text('File deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _emptyMessage() {
    final title = widget.categoryTitle.toLowerCase();
    if (title.contains('video')) {
      return 'No videos added yet.';
    }
    if (title.contains('photo')) {
      return 'No photos added yet.';
    }
    if (title.contains('blueprint')) {
      return 'No blueprints added yet.';
    }
    if (title.contains('report')) {
      return 'No reports added yet.';
    }
    return 'No files yet. Tap + to upload.';
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
              child: _filteredFiles.isEmpty
                  ? Center(
                      child: Text(_emptyMessage()),
                    )
                  : ListView.builder(
                      itemCount: _filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = _filteredFiles[index];
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
                            title: Text(file),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDelete(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DocumentsPage.primaryBlue,
        onPressed: _addFile,
        child: const Icon(
          Icons.upload,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.icon,
    required this.title,
    required this.files,
  });

  final IconData icon;
  final String title;
  final String files;
}
