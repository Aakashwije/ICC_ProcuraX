import 'package:flutter/material.dart';
import '../../core/colors.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final String type;
  final String? fileUrl;
  final String? fileName;
  final bool isMe;
  final String time;
  final ValueChanged<String?>? onOpenFile;

  const MessageBubble({
    super.key,
    required this.message,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.isMe,
    required this.time,
    this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColours.primary : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'file')
              InkWell(
                onTap: () => onOpenFile?.call(fileUrl),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 18,
                      color: isMe ? Colors.white : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fileName?.isNotEmpty == true ? fileName! : message,
                        style: TextStyle(
                          color: textColor,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(message, style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
