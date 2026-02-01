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
      location: "Unknown",
      createdAt: DateTime.now(),
      lastEdited: DateTime.now(),
      hasAttachment: attachment,
    );

    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Note"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _field("Note Title", _title),
            const SizedBox(height: 12),
            _field("Write your note here...", _content, lines: 6),
            const SizedBox(height: 12),

            Row(
              children: [
                DropdownButton<String>(
                  value: tag,
                  items: ["Issue", "Meeting", "Reminder"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => tag = v!),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => attachment = !attachment),
                  icon: Icon(
                    attachment ? Icons.check_box : Icons.attach_file,
                    color: primaryBlue,
                  ),
                  label: const Text("Add Attachment"),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Note"),
                onPressed: _save,
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
