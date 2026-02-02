import 'package:flutter/material.dart';
import 'package:procurax_frontend/models/note_model.dart';

class EditNotePage extends StatefulWidget {
  final Note note;

  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  late TextEditingController _title;
  late TextEditingController _content;
  late String _tag;
  late bool _attachment;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note.title);
    _content = TextEditingController(text: widget.note.content);
    _tag = widget.note.tag;
    _attachment = widget.note.hasAttachment;
  }

  void _saveChanges() {
    final updatedNote = Note(
      id: widget.note.id,
      title: _title.text,
      content: _content.text,
      tag: _tag,
      location: widget.note.location,
      createdAt: widget.note.createdAt,
      lastEdited: DateTime.now(),
      hasAttachment: _attachment,
    );

    Navigator.pop(context, updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Note"),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _field("Note Title", _title),
            const SizedBox(height: 12),
            _field("Edit your note...", _content, lines: 6),
            const SizedBox(height: 12),

            Row(
              children: [
                DropdownButton<String>(
                  value: _tag,
                  items: ["Issue", "Meeting", "Reminder"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _tag = v!),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _attachment = !_attachment),
                  icon: Icon(
                    _attachment ? Icons.check_box : Icons.attach_file,
                    color: primaryBlue,
                  ),
                  label: const Text("Attachment"),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController c, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: lightBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
