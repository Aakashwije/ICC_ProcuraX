import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:procurax_frontend/models/note_model.dart';

/// Screen that lets the user compose and save a new note.
///
/// When the user taps "Save Note" the page pops with a [Map] containing:
/// - `'note'`     → the constructed [Note] object
/// - `'filePath'` → local file path of the picked attachment (or null)
/// - `'fileName'` → original filename of the attachment (or null)
///
/// The caller ([NotesPage]) is responsible for persisting the note via
/// [NotesService.createNote] and then uploading the attachment if present.
class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  // ── Design tokens ───────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1F4DF0);
  static const Color lightBlue = Color(0xFFEAF1FF);

  /// Maps each tag name to its display colour.
  static const Map<String, Color> _tagColors = {
    "Issue": Color(0xFFE11D48), // red
    "Meeting": Color(0xFF2563EB), // blue
    "Reminder": Color(0xFF16A34A), // green
  };

  // ── Form controllers ────────────────────────────────────────────────
  final _title = TextEditingController();
  final _content = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────
  /// Currently selected tag; defaults to "Issue".
  String tag = "Issue";

  /// True when the user has picked a file to attach.
  bool attachment = false;

  /// Full local path to the picked file (null if none picked).
  String? _pickedFilePath;

  /// Original filename of the picked file (null if none picked).
  String? _pickedFileName;

  /// Opens the system file picker and stores the selected file's
  /// local path and name in state.
  /// The [attachment] flag is also set to true so [_save] knows to
  /// include it in the return value.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
        attachment = true;
      });
    }
  }

  /// Clears the picked file from state and resets the attachment flag.
  void _removeFile() {
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
      attachment = false;
    });
  }

  /// Validates inputs, constructs a [Note] object, and pops the route.
  ///
  /// A temporary `id` is assigned from the current timestamp — the real
  /// MongoDB ID is assigned by the backend and returned after [NotesService.createNote].
  ///
  /// Returns a [Map] so the caller can also receive the optional file
  /// path/name without needing a separate return channel.
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

    // Return both the note and the picked file info
    Navigator.pop(context, {
      'note': note,
      'filePath': _pickedFilePath,
      'fileName': _pickedFileName,
    });
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
                  _field("Note Title", _title, icon: Icons.title_rounded),
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
                  const SizedBox(height: 8),
                  _selectedTagChip(),
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
            child: const Icon(Icons.sticky_note_2_outlined, color: primaryBlue),
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

  /// Styled container with an icon, "Select tag" label, and a
  /// [DropdownButton] whose items each show a colour dot next to the tag name.
  Widget _tagSelector() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.label_rounded,
              color: primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "Select tag",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: tag,
              icon: const Icon(Icons.expand_more_rounded),
              items: ["Issue", "Meeting", "Reminder"]
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _tagColors[e] ?? primaryBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => tag = v!),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a small coloured pill below the tag selector that reflects
  /// the currently chosen tag — gives instant visual feedback.
  Widget _selectedTagChip() {
    final color = _tagColors[tag] ?? primaryBlue;
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              tag,
              style: TextStyle(
                color: color,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders the attachment area with two possible states:
  ///
  /// 1. **File picked** — shows the filename with a red ✕ button to remove it.
  /// 2. **No file** — shows a dashed-style "Tap to attach a file" prompt
  ///    that opens the system file picker on tap.
  Widget _attachmentToggle() {
    if (_pickedFileName != null) {
      // Show selected file with remove option
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              color: primaryBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _pickedFileName!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _removeFile,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.red,
                size: 20,
              ),
              tooltip: "Remove attachment",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // Show pick file button
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primaryBlue.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file_rounded,
              color: primaryBlue.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Tap to attach a file",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: primaryBlue.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
