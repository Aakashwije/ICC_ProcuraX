import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/note_model.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  final _title = TextEditingController();
  final _content = TextEditingController();
  String tag = "Issue";
  bool attachment = false;

  void _save() {
    if (_title.text.isEmpty || _content.text.isEmpty) return;

    final note = Note(
      id: DateTime.now().toString(),
      title: _title.text,
      content: _content.text,
      tag: tag,
      createdAt: DateTime.now(),
      lastEdited: DateTime.now(),
      hasAttachment: attachment,
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "New Note",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _headerCard(
              title: "Capture a new note",
              subtitle: "Keep issues, meetings, and reminders in one place.",
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _field(
                    "Note Title",
                    _title,
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    "Write your note here...",
                    _content,
                    icon: Icons.edit_note_outlined,
                    lines: 6,
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel("Tag"),
                  const SizedBox(height: 8),
                  _tagSelector(),
                  const SizedBox(height: 12),
                  _sectionLabel("Attachments"),
                  const SizedBox(height: 8),
                  _attachmentToggle(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  "Save Note",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sticky_note_2_outlined,
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _tagSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: tag,
          icon: const Icon(Icons.expand_more_rounded),
          items: ["Issue", "Meeting", "Reminder"]
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => tag = v!),
        ),
      ),
    );
  }

  Widget _attachmentToggle() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text("Include attachment"),
          selected: attachment,
          selectedColor: lightBlue,
          checkmarkColor: primaryBlue,
          labelStyle: const TextStyle(fontFamily: 'Poppins'),
          avatar: Icon(
            attachment ? Icons.attach_file : Icons.attach_file_outlined,
            size: 18,
            color: primaryBlue,
          ),
          onSelected: (_) => setState(() => attachment = !attachment),
        ),
      ],
    );
  }

  Widget _field(
    String hint,
    TextEditingController c, {
    int lines = 1,
    IconData? icon,
  }) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
    );
  }
}
