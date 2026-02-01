import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/services/notes_service.dart';
import 'package:procurax_frontend/models/note_model.dart';
import 'add_note_page.dart';
import 'edit_note_page.dart';
import 'note_added_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);
  static const Color neutralText = Color(0xFF6B7280);

  late Future<List<Note>> _notesFuture;

  @override
  void initState() {
    super.initState();
    _notesFuture = NotesService.fetchNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = NotesService.fetchNotes();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addNote() async {
    final note = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const AddNotePage()),
    );

    if (!mounted) return;

    if (note != null) {
      try {
        final created = await NotesService.createNote(note);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteAddedPage(note: created)),
        );
        if (!mounted) return;
        await _refreshNotes();
      } catch (err) {
        if (!mounted) return;
        _showError(err.toString());
      }
    }
  }

  Future<void> _editNote(Note note) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditNotePage(note: note)),
    );

    if (!mounted || updated == null) return;

    try {
      await NotesService.updateNote(updated);
      if (!mounted) return;
      await _refreshNotes();
    } catch (err) {
      if (!mounted) return;
      _showError(err.toString());
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete note"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await NotesService.deleteNote(note.id);
      if (!mounted) return;
      await _refreshNotes();
    } catch (err) {
      if (!mounted) return;
      _showError(err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: AppRoutes.notes),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(
                            Icons.menu_rounded,
                            size: 30,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      "Notes",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.notifications_none, color: primaryBlue),
                          SizedBox(width: 12),
                          CircleAvatar(radius: 14, child: Text("AK")),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _searchBar(),
              const SizedBox(height: 18),
              Expanded(
                child: FutureBuilder<List<Note>>(
                  future: _notesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Failed to load notes",
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      );
                    }
                    final notes = snapshot.data ?? [];
                    if (notes.isEmpty) return _emptyState();
                    return RefreshIndicator(
                      onRefresh: _refreshNotes,
                      child: ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (_, i) => _noteCard(notes[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _noteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editNote(note),
                icon: const Icon(Icons.edit_outlined, color: primaryBlue),
                tooltip: "Edit",
              ),
              IconButton(
                onPressed: () => _deleteNote(note),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Delete",
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tagBadge(note.tag),
              const Spacer(),
              Text(
                "${note.createdAt.hour.toString().padLeft(2, '0')}:${note.createdAt.minute.toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 12, color: neutralText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.search_outlined, color: neutralText),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search notes",
                border: InputBorder.none,
              ),
            ),
          ),
          Icon(Icons.mic_none_outlined, color: neutralText),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightBlue.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.note_alt_outlined, color: primaryBlue, size: 36),
            SizedBox(height: 10),
            Text(
              "No notes yet",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Tap + to create your first note",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagBadge(String tag) {
    final color = tag == "Issue"
        ? Colors.red
        : tag == "Meeting"
        ? primaryBlue
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: color),
      ),
    );
  }
}
