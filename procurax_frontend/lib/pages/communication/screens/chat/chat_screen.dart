import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:procurax_frontend/widgets/custom_toast.dart';
import '../../core/colors.dart';
import '../chat/message_bubble.dart';
import '../chat/typing_indicator.dart';
import 'package:procurax_frontend/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final VoidCallback? onChatRead;
  final String userName;
  final String userRole;
  final String avatarUrl;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    this.onChatRead,
    required this.userName,
    required this.userRole,
    required this.avatarUrl,
    this.isOnline = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();

  bool isUserTyping = false;
  bool isOtherTyping = false;
  bool isOtherOnline = false;
  bool _lastSentTyping = false;
  Timer? _typingDebounce;
  Timer? _typingPollTimer;
  Timer? _presenceTimer;
  bool _showScrollToBottom = false;

  final List<Message> messages = [];
  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    isOtherOnline = widget.isOnline;
    fetchMessages();
    _markChatRead();
    _startPresence();
    _startTypingPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _typingPollTimer?.cancel();
    _presenceTimer?.cancel();
    _sendTyping(false);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _markChatRead() async {
    try {
      await _chatService.markChatRead(
        chatId: widget.chatId,
        userId: widget.currentUserId,
      );
      widget.onChatRead?.call();
    } catch (e) {
      debugPrint('Failed to mark chat read: $e');
    }
  }

  Future<void> fetchMessages() async {
    try {
      final data = await _chatService.getMessagesByChat(widget.chatId);
      if (!mounted) return;
      setState(() {
        messages.clear();
        for (var msg in data) {
          final createdAt = msg['createdAt'];
          final createdAtDate = _parseMessageDate(createdAt);
          messages.add(
            Message(
              id: msg['id'].toString(),
              senderId: (msg['senderId'] ?? '').toString(),
              text: (msg['content'] ?? '').toString(),
              type: (msg['type'] ?? 'text').toString(),
              fileUrl: msg['fileUrl']?.toString(),
              fileName: msg['fileName']?.toString(),
              isMe: msg['senderId'] == widget.currentUserId,
              time: _formatMessageTime(createdAtDate ?? createdAt),
              createdAt: createdAtDate,
            ),
          );
        }
        loadError = null;
      });
      _scrollToBottom(force: true);
    } catch (e) {
      debugPrint('Failed to load messages: $e');
      if (!mounted) return;
      setState(() {
        loadError = 'Failed to load messages';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Color _getColorForUser(String value) {
    if (value.isEmpty) return AppColours.primary;
    final int hash = value.hashCode;
    const List<Color> colors = [
      Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2),
      Color(0xFF1E88E5), Color(0xFF2196F3), Color(0xFF42A5F5),
      Color(0xFF64B5F6), Color(0xFF90CAF9), Color(0xFF01579B),
      Color(0xFF0277BD), Color(0xFF0288D1), Color(0xFF039BE5),
      Color(0xFF03A9F4),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _formatMessageTime(dynamic createdAt) {
    if (createdAt == null) return '';
    if (createdAt is DateTime) {
      return TimeOfDay.fromDateTime(createdAt.toLocal()).format(context);
    }
    if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
        return TimeOfDay.fromDateTime(dt).format(context);
      }
    }
    if (createdAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(createdAt);
      final normalized = hasTz ? createdAt : '${createdAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return TimeOfDay.fromDateTime(parsed.toLocal()).format(context);
    }
    return '';
  }

  DateTime? _parseMessageDate(dynamic createdAt) {
    if (createdAt == null) return null;
    if (createdAt is DateTime) return createdAt.toLocal();
    if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
      }
    }
    if (createdAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(createdAt);
      final normalized = hasTz ? createdAt : '${createdAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (_isSameDay(target, today)) return 'Today';
    if (_isSameDay(target, today.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[target.month - 1]} ${target.day}, ${target.year}';
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  String _formatRole(String role) {
    if (role.trim().isEmpty) return 'Member';
    return role.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Future<void> _showDeleteMessageSheet(Message message) async {
    if (!message.isMe) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete message'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await _deleteMessage(message.id);
  }

  Future<void> _deleteMessage(String messageId) async {
    final old = List<Message>.from(messages);
    setState(() {
      final index = messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final m = messages[index];
        messages[index] = Message(
          id: m.id,
          senderId: m.senderId,
          text: '',
          isMe: m.isMe,
          time: m.time,
          createdAt: m.createdAt,
          isDeleted: true,
        );
      }
    });
    try {
      await _chatService.deleteMessage(
        messageId: messageId,
        userId: widget.currentUserId,
      );
    } catch (e) {
      debugPrint('Delete failed: $e');
      if (!mounted) return;
      setState(() {
        messages..clear()..addAll(old);
      });
      CustomToast.error(
        context,
        'Unable to delete message. Please try again.',
        title: 'Delete Failed',
      );
    }
  }

  List<Widget> _buildMessageItems() {
    final items = <Widget>[];
    DateTime? lastDate;

    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final date = message.createdAt;
      final dateOnly = date != null ? DateTime(date.year, date.month, date.day) : null;

      items.add(
        GestureDetector(
          onLongPress: () => _showDeleteMessageSheet(message),
          child: MessageBubble(
            message: message.text,
            type: message.type,
            fileName: message.fileName,
            fileUrl: message.fileUrl,
            isMe: message.isMe,
            time: message.time,
            onOpenFile: _openAttachment,
            isDeleted: message.isDeleted,
            isUploading: message.isUploading, // ipassed here
          ),
        ),
      );

      if (dateOnly != null) {
        if (lastDate == null || !_isSameDay(lastDate, dateOnly)) {
          items.add(_buildDateSeparator(_formatDateHeader(dateOnly)));
          lastDate = dateOnly;
        }
      }
    }
    return items;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final max = _scrollController.position.minScrollExtent;
    final current = _scrollController.position.pixels;
    return current <= max + 120;
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scrollController.hasClients) return;
    if (!force && !_isNearBottom()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _startPresence() {
    _sendPresenceHeartbeat();
    _refreshOtherPresence();
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _sendPresenceHeartbeat();
      await _refreshOtherPresence();
    });
  }

  Future<void> _sendPresenceHeartbeat() async {
    try {
      await _chatService.sendPresenceHeartbeat(widget.currentUserId);
    } catch (e) {
      debugPrint('Failed to send presence heartbeat: $e');
    }
  }

  bool _presenceFetching = false;

  Future<void> _refreshOtherPresence() async {
    
    if (_presenceFetching) return;
    _presenceFetching = true;
    try {
      final presence = await _chatService.getPresence(widget.otherUserId);
      if (!mounted) return;
      setState(() {
        isOtherOnline = presence['isOnline'] == true;
      });
    } catch (e) {
      debugPrint('Failed to refresh presence: $e');
    }
  }

  void _startTypingPolling() {
    _refreshOtherTyping();
    _typingPollTimer?.cancel();
    _typingPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshOtherTyping();
    });
  }

  bool _typingFetching = false;
  Future<void> _refreshOtherTyping() async {
    if (_typingFetching) return;
    _typingFetching = true;
    try {
      final typing = await _chatService.getTyping(
        chatId: widget.chatId,
        userId: widget.otherUserId,
      );
      if (!mounted) return;
      setState(() => isOtherTyping = typing['isTyping'] == true);
    } catch (e) {
      debugPrint('Failed to refresh typing: $e');
    }
  }

  void _scheduleTypingUpdate(bool typingNow) {
    _typingDebounce?.cancel();
    if (!typingNow) {
      _sendTyping(false);
      return;
    }
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      _sendTyping(true);
    });
  }

  Future<void> _sendTyping(bool isTyping) async {
    if (_lastSentTyping == isTyping) return;
    _lastSentTyping = isTyping;
    try {
      await _chatService.setTyping(
        chatId: widget.chatId,
        userId: widget.currentUserId,
        isTyping: isTyping,
      );
    } catch (e) {
      debugPrint('Failed to set typing: $e');
    }
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: IconButton(
                      icon: Icon(Icons.attach_file_rounded, color: Colors.grey.shade600),
                      onPressed: _pickAndSendFile,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColours.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  fillColor: Colors.grey.shade50,
                  filled: true,
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  final typingNow = value.trim().isNotEmpty;
                  setState(() => isUserTyping = typingNow);
                  _scheduleTypingUpdate(typingNow);
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              width: 48,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isUserTyping ? AppColours.primary : AppColours.primary.withOpacity(0.4),
                shape: BoxShape.circle,
                boxShadow: isUserTyping
                    ? [BoxShadow(color: AppColours.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                    : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                onPressed: isUserTyping ? _sendMessage : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final createdAt = DateTime.now();
    final time = TimeOfDay.fromDateTime(createdAt).format(context);
    final tempId = 'temp_${createdAt.microsecondsSinceEpoch}';

    setState(() {
      messages.add(Message(
        id: tempId,
        senderId: widget.currentUserId,
        text: text,
        isMe: true,
        time: time,
        createdAt: createdAt,
      ));
      _textController.clear();
      isUserTyping = false;
    });

    _sendTyping(false);
    _scrollToBottom(force: true);

    try {
      final res = await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: text,
        type: 'text',
      );
      final realId = res['id']?.toString();
      if (realId != null && mounted) {
        setState(() {
          final index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            final old = messages[index];
            messages[index] = Message(
              id: realId,
              senderId: old.senderId,
              text: old.text,
              isMe: old.isMe,
              time: old.time,
              createdAt: old.createdAt,
              type: old.type,
              fileUrl: old.fileUrl,
              fileName: old.fileName,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (mounted) {
        CustomToast.error(
          context,
          'Your message could not be sent. Please check your connection.',
          title: 'Message Not Sent',
        );
      }
    }
  }

  //  Updated with spinner + file size check
  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read file data')),
        );
        return;
      }

      

      final fileName = file.name;
      final mimeType = lookupMimeType(fileName, headerBytes: bytes) ?? 'application/octet-stream';
      final createdAt = DateTime.now();
      final time = TimeOfDay.fromDateTime(createdAt).format(context);
      final tempId = 'temp_${createdAt.microsecondsSinceEpoch}';

      // Show bubble with spinner BEFORE upload starts
      setState(() {
        messages.add(Message(
          id: tempId,
          senderId: widget.currentUserId,
          text: fileName,
          type: 'file',
          fileName: fileName,
          isMe: true,
          time: time,
          createdAt: createdAt,
          isUploading: true,
        ));
      });

      _scrollToBottom(force: true);

      // Upload file
      final upload = await _chatService.uploadFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      final fileUrl = upload['url']?.toString() ?? '';
      if (fileUrl.isEmpty) throw Exception('Upload failed: missing url');
      final originalName = upload['originalName']?.toString() ?? fileName;

      // Upload done — remove spinner
      if (mounted) {
        setState(() {
          final index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            messages[index] = Message(
              id: tempId,
              senderId: widget.currentUserId,
              text: originalName,
              type: 'file',
              fileUrl: fileUrl,
              fileName: originalName,
              isMe: true,
              time: time,
              createdAt: createdAt,
              isUploading: false,
            );
          }
        });
      }

      // Send message to backend
      final res = await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: originalName,
        type: 'file',
        fileUrl: fileUrl,
        fileName: originalName,
      );

      // Replace temp ID with real ID
      final realId = res['id']?.toString();
      if (realId != null && mounted) {
        setState(() {
          final index = messages.indexWhere((m) => m.id == tempId);
          if (index != -1) {
            final old = messages[index];
            messages[index] = Message(
              id: realId,
              senderId: old.senderId,
              text: old.text,
              isMe: old.isMe,
              time: old.time,
              createdAt: old.createdAt,
              type: old.type,
              fileUrl: old.fileUrl,
              fileName: old.fileName,
              isUploading: false,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to send file: $e');
      if (!mounted) return;
      setState(() {
        messages.removeWhere((m) => m.id.startsWith('temp_'));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send file')),
      );
    }
  }

  Future<void> _openAttachment(String? url) async {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('Invalid URL scheme: $url');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: AppColours.primary),
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getColorForUser(widget.otherUserId),
                  backgroundImage: widget.avatarUrl.isNotEmpty && widget.avatarUrl.startsWith('http')
                      ? NetworkImage(widget.avatarUrl)
                      : null,
                  child: widget.avatarUrl.isEmpty || !widget.avatarUrl.startsWith('http')
                      ? Text(
                          widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                      : null,
                ),
                if (isOtherOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(color: AppColours.neutral, fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    _formatRole(widget.userRole),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.video_call, color: AppColours.neutral), onPressed: () {}),
          IconButton(icon: const Icon(Icons.call, color: AppColours.neutral), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColours.neutral),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'details', child: Text("View details")),
              PopupMenuItem(value: 'block', child: Text("Block user")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : loadError != null
                    ? Center(child: Text(loadError!))
                    : messages.isEmpty
                        ? const Center(child: Text('No messages yet'))
                        : Builder(
                            builder: (context) {
                              final items = _buildMessageItems();
                              return Stack(
                                children: [
                                  NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      final shouldShow = !_isNearBottom();
                                      if (shouldShow != _showScrollToBottom) {
                                        setState(() => _showScrollToBottom = shouldShow);
                                      }
                                      return false;
                                    },
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      reverse: true,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      itemCount: items.length,
                                      itemBuilder: (context, index) => items[index],
                                    ),
                                  ),
                                  if (_showScrollToBottom)
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: FloatingActionButton.small(
                                        onPressed: () => _scrollToBottom(force: true),
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColours.primary,
                                        child: const Icon(Icons.arrow_downward, size: 18),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
          ),
          if (isOtherTyping) const TypingIndicator(),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 209, 221, 234),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, -3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [_buildMessageInput()],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final bool isMe;
  final String time;
  final DateTime? createdAt;
  final String type;
  final String? fileUrl;
  final String? fileName;
  final bool isDeleted;
  final bool isUploading;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.isMe,
    required this.time,
    this.createdAt,
    this.type = 'text',
    this.fileUrl,
    this.fileName,
    this.isDeleted = false,
    this.isUploading = false,
  });
}