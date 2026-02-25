import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
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

  bool isUserTyping = false; // for send button
  bool isOtherTyping = false; // for typing other
  bool isOtherOnline = false;
  bool _lastSentTyping = false;
  Timer? _typingDebounce;
  Timer? _typingPollTimer;
  Timer? _presenceTimer;
  bool debugSimulateOtherTyping = false;
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
              id: msg['id'].toString(), // ✅ messageId from backend
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

  String _formatMessageTime(dynamic createdAt) {
    if (createdAt == null) return '';

    if (createdAt is DateTime) {
      return TimeOfDay.fromDateTime(createdAt.toLocal()).format(context);
    }

    if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal();
        return TimeOfDay.fromDateTime(dt).format(context);
      }
    }

    if (createdAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(createdAt);
      final normalized = hasTz ? createdAt : '${createdAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return TimeOfDay.fromDateTime(parsed.toLocal()).format(context);
      }
    }

    return '';
  }

  DateTime? _parseMessageDate(dynamic createdAt) {
    if (createdAt == null) return null;

    if (createdAt is DateTime) {
      return createdAt.toLocal();
    }

    if (createdAt is Map) {
      final seconds = createdAt['_seconds'] ?? createdAt['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal();
      }
    }

    if (createdAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(createdAt);
      final normalized = hasTz ? createdAt : '${createdAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return parsed.toLocal();
      }
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
    if (_isSameDay(target, today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[target.month - 1];
    return '$month ${target.day}, ${target.year}';
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Long-press delete menu (only for my messages)
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

    if (confirmed == true) {
      await _deleteMessage(message.id);
    }
  }

  // ✅ Calls backend + optimistic UI
  Future<void> _deleteMessage(String messageId) async {
    final old = List<Message>.from(messages);

    setState(() {
      messages.removeWhere((m) => m.id == messageId);
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
        messages
          ..clear()
          ..addAll(old);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  List<Widget> _buildMessageItems() {
    final items = <Widget>[];
    DateTime? lastDate;

    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final date = message.createdAt;
      final dateOnly = date != null
          ? DateTime(date.year, date.month, date.day)
          : null;

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

  Future<void> _refreshOtherPresence() async {
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
    _typingPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshOtherTyping();
    });
  }

  Future<void> _refreshOtherTyping() async {
    if (kDebugMode && debugSimulateOtherTyping) return;
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

  void _toggleDebugTyping() {
    setState(() {
      debugSimulateOtherTyping = !debugSimulateOtherTyping;
      if (debugSimulateOtherTyping) {
        isOtherTyping = true;
      }
    });
    if (!debugSimulateOtherTyping) {
      _refreshOtherTyping();
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

  // Message Input
  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                      onPressed: _pickAndSendFile,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          final typingNow = value.trim().isNotEmpty;
                          setState(() {
                            isUserTyping = typingNow;
                          });
                          _scheduleTypingUpdate(typingNow);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: isUserTyping ? AppColours.primary : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
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
      messages.add(
        Message(
          id: tempId,
          senderId: widget.currentUserId,
          text: text,
          isMe: true,
          time: time,
          createdAt: createdAt,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    }
  }

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
      final mimeType =
          lookupMimeType(fileName, headerBytes: bytes) ?? 'application/octet-stream';

      final upload = await _chatService.uploadFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );

      final fileUrl = upload['url']?.toString() ?? '';
      final originalName = upload['originalName']?.toString() ?? fileName;

      if (fileUrl.isEmpty) {
        throw Exception('Upload failed: missing url');
      }

      final createdAt = DateTime.now();
      final time = TimeOfDay.fromDateTime(createdAt).format(context);

      final tempId = 'temp_${createdAt.microsecondsSinceEpoch}';

      setState(() {
        messages.add(
          Message(
            id: tempId,
            senderId: widget.currentUserId,
            text: originalName,
            type: 'file',
            fileUrl: fileUrl,
            fileName: originalName,
            isMe: true,
            time: time,
            createdAt: createdAt,
          ),
        );
      });

      _scrollToBottom(force: true);

      final res = await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        content: originalName,
        type: 'file',
        fileUrl: fileUrl,
        fileName: originalName,
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
      debugPrint('Failed to send file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send file')),
      );
    }
  }

  Future<void> _openAttachment(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
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
                  backgroundImage: NetworkImage(widget.avatarUrl),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: AppColours.neutral,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  widget.userRole,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: debugSimulateOtherTyping
                  ? 'Disable simulate typing'
                  : 'Simulate typing',
              icon: Icon(
                debugSimulateOtherTyping
                    ? Icons.keyboard
                    : Icons.keyboard_outlined,
                color: AppColours.neutral,
              ),
              onPressed: _toggleDebugTyping,
            ),
          IconButton(
            icon: const Icon(Icons.video_call, color: AppColours.neutral),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppColours.neutral),
            onPressed: () {},
          ),
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
                              final listView =
                                  NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  final shouldShow = !_isNearBottom();
                                  if (shouldShow != _showScrollToBottom) {
                                    setState(() {
                                      _showScrollToBottom = shouldShow;
                                    });
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
                              );

                              return Stack(
                                children: [
                                  listView,
                                  if (_showScrollToBottom)
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: FloatingActionButton.small(
                                        onPressed: () =>
                                            _scrollToBottom(force: true),
                                        backgroundColor: Colors.white,
                                        foregroundColor: AppColours.primary,
                                        child: const Icon(
                                          Icons.arrow_downward,
                                          size: 18,
                                        ),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String id; // ✅ messageId
  final String senderId; // ✅ sender
  final String text;
  final bool isMe;
  final String time;
  final DateTime? createdAt;
  final String type;
  final String? fileUrl;
  final String? fileName;

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
  });
}