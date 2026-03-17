import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'speech_helper.dart';
import 'package:procurax_frontend/theme/app_theme.dart' as theme;

class BottomInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const BottomInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<BottomInput> createState() => _BottomInputState();
}

class _BottomInputState extends State<BottomInput> {
  late SpeechHelper _speechHelper;
  bool _isListening = false;
  String _voiceText = '';
  bool _micError = false;

  @override
  void initState() {
    super.initState();
    _speechHelper = SpeechHelper();
    _speechHelper
        .init()
        .then((_) {
          if (mounted && !_speechHelper.isAvailable) {
            setState(() {
              _micError = true;
            });
          }
        })
        .catchError((e) {
          print('Speech init error in BottomInput: $e');
          if (mounted) {
            setState(() {
              _micError = true;
            });
          }
        });
  }

  void _startListening() {
    if (!_speechHelper.isAvailable) {
      setState(() {
        _micError = true;
      });
      return;
    }
    setState(() {
      _isListening = true;
      _voiceText = '';
      _micError = false;
    });
    _speechHelper.startListening((text) {
      setState(() {
        _voiceText = text;
        widget.controller.text = text;
      });
    });
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
      _voiceText = '';
    });
    _speechHelper.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_micError)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Microphone unavailable or permission denied. Please enable mic access in settings.',
                    style: theme.AppTextStyles.caption.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_isListening && _voiceText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: theme.AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _voiceText,
                    style: theme.AppTextStyles.bodySmall.copyWith(
                      color: theme.AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                tooltip: 'Attach file/image',
                onPressed: widget.isLoading
                    ? null
                    : () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(
                              type: FileType.any,
                              allowMultiple: false,
                            );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          // You can send file info or upload here
                          // For demo, just show file name in input
                          widget.controller.text = 'Attachment: ${file.name}';
                        }
                      },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                tooltip: 'Pick date/time',
                onPressed: widget.isLoading
                    ? null
                    : () async {
                        // Date picker
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          // Time picker
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final dt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            widget.controller.text =
                                'Scheduled for: ${dt.toString()}';
                          }
                        }
                      },
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.isLoading,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    filled: true,
                    fillColor: theme.AppColors.neutral100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty && !widget.isLoading) {
                      widget.onSend(value);
                      widget.controller.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                tooltip: _isListening ? 'Stop listening' : 'Voice input',
                onPressed: widget.isLoading
                    ? null
                    : () {
                        if (_isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          if (widget.controller.text.trim().isNotEmpty) {
                            widget.onSend(widget.controller.text);
                            widget.controller.clear();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
