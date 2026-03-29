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
  final bool isDeleted;
  final bool isUploading;

  const MessageBubble({
    super.key,
    required this.message,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.isMe,
    required this.time,
    this.onOpenFile,
    this.isDeleted = false,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColours.primary : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 6),
            bottomRight: Radius.circular(isMe ? 6 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDeleted)
              Text(
                'Message deleted',
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              )
            else if (type == 'image')
              isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isMe ? Colors.white70 : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploading image...',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: () => onOpenFile?.call(fileUrl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fileUrl ?? '',
                              width: 240,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 240,
                                  height: 160,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null,
                                      color: isMe
                                          ? Colors.white70
                                          : AppColours.primary,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) =>
                                  Container(
                                    width: 240,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.15)
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to open',
                                          style: TextStyle(
                                            color: isMe
                                                ? Colors.white70
                                                : Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                          if (fileName != null && fileName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              fileName!,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    )
            else if (type == 'file')
              isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isMe ? Colors.white70 : Colors.black45,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  : InkWell(
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
                              fileName?.isNotEmpty == true
                                  ? fileName!
                                  : message,
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
              Text(
                message,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
