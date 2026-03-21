import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  static const Map<String, Color> _tagColors = {
    "Issue": Color(0xFFE11D48),
    "Meeting": Color(0xFF2563EB),
    "Reminder": Color(0xFF16A34A),
  };

  late TextEditingController _title;
  late TextEditingController _content;
  late String _tag;
  late bool _attachment;
  String? _pickedFilePath;
  String? _pickedFileName;
  bool _deleteExistingAttachment = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note.title);
    _content = TextEditingController(text: widget.note.content);
    _tag = widget.note.tag;
    _attachment = widget.note.hasAttachment;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path;
        _pickedFileName = result.files.single.name;
        _attachment = true;
        _deleteExistingAttachment = false;
      });
    }
  }

  void _removeNewFile() {
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
      // Revert to original attachment state
      _attachment = widget.note.hasAttachment && !_deleteExistingAttachment;
    });
  }

  void _markDeleteExisting() {
    setState(() {
      _deleteExistingAttachment = true;
      _attachment = false;
    });
  }

  void _saveChanges() {
    final updatedNote = Note(
      id: widget.note.id,
      title: _title.text,
      content: _content.text,
      tag: _tag,
      createdAt: widget.note.createdAt,
      lastEdited: DateTime.now(),
      hasAttachment: _attachment,
      attachmentUrl: _deleteExistingAttachment ? "" : widget.note.attachmentUrl,
      attachmentName: _deleteExistingAttachment
          ? ""
          : widget.note.attachmentName,
    );

    Navigator.pop(context, {
      'note': updatedNote,
      'filePath': _pickedFilePath,
      'fileName': _pickedFileName,
      'deleteExisting': _deleteExistingAttachment,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Note",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _headerCard(
              title: "Update your note",
              subtitle: "Refine details and keep your records accurate.",
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _field("Note Title", _title, icon: Icons.title_rounded),
                  const SizedBox(height: 12),
                  _field(
                    "Edit your note...",
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
                  "Save Changes",
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
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
              value: _tag,
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
              onChanged: (v) => setState(() => _tag = v!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedTagChip() {
    final color = _tagColors[_tag] ?? primaryBlue;
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
              _tag,
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

  Widget _attachmentToggle() {
    // If a NEW file has been picked, show it
    if (_pickedFileName != null) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pickedFileName!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "New file (will upload on save)",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _removeNewFile,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.red,
                size: 20,
              ),
              tooltip: "Remove",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // If existing attachment is present and not marked for deletion
    if (widget.note.hasAttachment &&
        widget.note.attachmentName.isNotEmpty &&
        !_deleteExistingAttachment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file_rounded, color: primaryBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.note.attachmentName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _pickFile,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: primaryBlue,
                size: 20,
              ),
              tooltip: "Replace file",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _markDeleteExisting,
              icon: const Icon(
                Icons.delete_outline,
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

    // No attachment — show pick button
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
