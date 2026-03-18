import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:procurax_frontend/routes/app_routes.dart';
import 'package:procurax_frontend/widgets/app_drawer.dart';
import 'package:procurax_frontend/widgets/custom_toast.dart';
import 'package:procurax_frontend/services/chat_service.dart';
import '../../core/colors.dart';
import '../../widgets/bottom_nav.dart';
import '../chat/chat_screen.dart';
//import '../files/files_screen.dart';
import '../alerts/alerts_screen.dart';
import '../calls/calls_screen.dart';
import 'package:procurax_frontend/services/api_service.dart';

class ChatListScreen extends StatefulWidget {
  final bool showDrawer;

  const ChatListScreen({super.key, this.showDrawer = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  final ChatService _chatService = ChatService();
  String currentUserId = ApiService.currentUserId ?? '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  Timer? _searchDebounce;
  String searchQuery = '';

  List<dynamic> chats = [];
  List<dynamic> filteredChats = [];
  List<dynamic> allUsers = [];
  bool usersLoading = false;
  bool loading = true;
  int alertCount = 0;
  int messageUnreadCount = 0;
  Map<String, bool> onlineMap = {};
  Timer? _presenceTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchChats();
    fetchAlerts();
    _startPresence();
    _startPolling();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
     _pollTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _userSearchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendPresenceHeartbeat();
      _refreshPresence();
    }
  }

  Future<void> fetchChats() async {
    try {
      final data = await _chatService.getUserChats(currentUserId);
      final unread = _calculateUnreadMessages(data);
      setState(() {
        chats = data;
        filteredChats = _applySearch(data, searchQuery);
        loading = false;
        messageUnreadCount = unread;
      });
      //await _refreshPresence();
      //await fetchAlerts();
    } catch (e) {
      debugPrint('Failed to load chats: $e');
      setState(() => loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      searchQuery = value;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        filteredChats = _applySearch(chats, searchQuery);
      });
    });
  }

  List<dynamic> _applySearch(List<dynamic> data, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<dynamic>.from(data);

    return data.where((chat) {
      final name = (chat['otherUserName'] ?? chat['name'] ?? '')
          .toString()
          .toLowerCase();
      final role = (chat['otherUserRole'] ?? chat['role'] ?? '')
          .toString()
          .toLowerCase();
      final lastMessage = (chat['lastMessage'] ?? '').toString().toLowerCase();

      return name.contains(q) || role.contains(q) || lastMessage.contains(q);
    }).toList();
  }

  void _startPresence() {
    _sendPresenceHeartbeat();
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _sendPresenceHeartbeat();
      await _refreshPresence();
    });
  }
  void _startPolling() {
  _pollTimer?.cancel();
  _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
    await fetchChats();
    await fetchAlerts();
  });
}

  Future<void> _sendPresenceHeartbeat() async {
    try {
      await _chatService.sendPresenceHeartbeat(currentUserId);
    } catch (e) {
      debugPrint('Failed to send presence heartbeat: $e');
    }
  }

  Future<void> _loadUsers() async {
    if (usersLoading) return;
    if (allUsers.isNotEmpty) return;
    setState(() => usersLoading = true);
    try {
      final data = await _chatService.getAllUsers();
      if (!mounted) return;
      setState(() {
        allUsers = data;
      });
    } catch (e) {
      debugPrint('Failed to load users: $e');
      if (!mounted) return;
      CustomToast.error(
        context,
        'Unable to load user list. Please try again.',
        title: 'Connection Error',
      );
    } finally {
      if (mounted) setState(() => usersLoading = false);
    }
  }

  Future<void> _showCurrentUserPicker() async {
    await _loadUsers();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _filterUsers(_userSearchController.text);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: 520,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select current user',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _userSearchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by phone or name',
                        ),
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: usersLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filtered.isEmpty
                          ? const Center(child: Text('No users found'))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                final userId = _getUserId(user);
                                final name = _getUserName(user);
                                final phone = _getUserPhone(user);

                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(
                                    name.isNotEmpty
                                        ? name
                                        : (phone.isNotEmpty ? phone : userId),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    phone.isNotEmpty ? phone : userId,
                                  ),
                                  trailing: userId == currentUserId
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColours.primary,
                                        )
                                      : null,
                                  onTap: () async {
                                    Navigator.of(context).pop();
                                    if (userId.isEmpty) return;
                                    _userSearchController.clear();
                                    setState(() {
                                      currentUserId = userId;
                                      chats = [];
                                      loading = true;
                                      alertCount = 0;
                                      messageUnreadCount = 0;
                                      onlineMap = {};
                                    });
                                    await _sendPresenceHeartbeat();
                                    await fetchChats();
                                    await fetchAlerts();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getUserId(dynamic user) {
    return (user['userId'] ?? user['uid'] ?? user['id'] ?? '').toString();
  }

  String _getUserName(dynamic user) {
    return (user['name'] ?? user['displayName'] ?? user['email'] ?? '')
        .toString();
  }

  String _getUserPhone(dynamic user) {
    return (user['phone'] ?? user['phoneNumber'] ?? '').toString();
  }

  List<dynamic> _filterUsers(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<dynamic>.from(allUsers);
    return allUsers.where((user) {
      final name = _getUserName(user).toLowerCase();
      final phone = _getUserPhone(user).toLowerCase();
      final userId = _getUserId(user).toLowerCase();
      return name.contains(q) || phone.contains(q) || userId.contains(q);
    }).toList();
  }

  Future<void> _showUserPicker() async {
    await _loadUsers();
    if (!mounted) return;
    _userSearchController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _filterUsers(
              _userSearchController.text,
            ).where((u) => _getUserId(u) != currentUserId).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Drag Handle
                    Container(
                      height: 5,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: AppColours.primary, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'New Conversation',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: TextField(
                          controller: _userSearchController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            hintText: 'Search contacts...',
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User List
                    Expanded(
                      child: usersLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColours.primary))
                          : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No contacts found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                final userId = _getUserId(user);
                                final name = _getUserName(user);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () async {
                                        Navigator.of(context).pop();
                                        if (userId.isEmpty) return;
                                        try {
                                          await _chatService.createChat(
                                            members: [currentUserId, userId],
                                            isGroup: false,
                                          );
                                          await fetchChats();
                                        } catch (e) {
                                          debugPrint('Failed to create chat: $e');
                                          if (!mounted) return;
                                          CustomToast.error(
                                            this.context,
                                            'Unable to start a new conversation. Please try again.',
                                            title: 'Chat Creation Failed',
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 50,
                                              width: 50,
                                              decoration: BoxDecoration(
                                                color: _getColorForUser(userId),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                name.isNotEmpty ? name : userId,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _presenceFetching = false;
  Future<void> _refreshPresence() async {
    if (chats.isEmpty) return;
    if (_presenceFetching) return; // new
    _presenceFetching = true;  //new

    final otherUserIds = <String>{};
    for (final chat in chats) {
      final List members = chat['members'] ?? chat['userIds'] ?? [];
      final otherUserId = members.firstWhere(
        (u) => u != currentUserId,
        orElse: () => null,
      );
      if (otherUserId != null) {
        otherUserIds.add(otherUserId.toString());
      }
    }

    if (otherUserIds.isEmpty) {
      _presenceFetching = false; // new
      return;
    }

    try {
      final results = await Future.wait(
        otherUserIds.map((id) async {
          final presence = await _chatService.getPresence(id);
          final isOnline = presence['isOnline'] == true;
          return MapEntry(id, isOnline);
        }),
      );

      if (!mounted) return;
      setState(() {
        onlineMap = {for (final entry in results) entry.key: entry.value};
      });
    } catch (e) {
      debugPrint('Failed to refresh presence: $e');
    }
  }

  int _calculateUnreadMessages(List<dynamic> data) {
    int total = 0;
    for (final chat in data) {
      final unreadCounts = chat['unreadCounts'];
      if (unreadCounts is Map && unreadCounts[currentUserId] != null) {
        final rawCount = unreadCounts[currentUserId];
        final count = rawCount is int
            ? rawCount
            : int.tryParse(rawCount.toString()) ?? 0;
        total += count;
      }
    }
    return total;
  }

  Future<void> _refreshBadges() async {
    await fetchChats();
    await fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      final data = await _chatService.getUserAlerts(currentUserId);
      final unread = data.where((a) => a['isRead'] != true).length;
      setState(() {
        alertCount = unread;
      });
    } catch (e) {
      debugPrint('Failed to load alerts: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() => currentIndex = index);
    if (index == 2) {
      fetchAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      drawer: widget.showDrawer
          ? const AppDrawer(currentRoute: AppRoutes.communication)
          : null,

      appBar: AppBar(
        leading: widget.showDrawer
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: AppColours.primary,
                    size: 30,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        title: const Text(
          'Communication',
          style: TextStyle(
            color: AppColours.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [],
      ),

      body: currentIndex == 0
          ? MessagesPage(
              chats: filteredChats,
              loading: loading,
              onRefresh: fetchChats,
              currentUserId: currentUserId,
              onChatClosed: _refreshBadges,
              onlineMap: onlineMap,
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
            )
          : currentIndex == 1
          ? const CallsScreen()
          : AlertsScreen(userId: currentUserId),

      floatingActionButton: currentIndex == 0
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 60,
              width: 60,
              child: FloatingActionButton(
                onPressed: _showUserPicker,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColours.primary.withOpacity(0.8),
                        AppColours.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_comment_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            )
          : null,

      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        messageBadgeCount: messageUnreadCount,
        alertBadgeCount: alertCount,
        onTap: _onTabTapped,
      ),
    );
  }
}

Color _getColorForUser(String name) {
  if (name.isEmpty) return AppColours.primary;
  final int hash = name.hashCode;
  final List<Color> colors = [
    const Color(0xFF0D47A1), // Blue 900
    const Color(0xFF1565C0), // Blue 800
    const Color(0xFF1976D2), // Blue 700
    const Color(0xFF1E88E5), // Blue 600
    const Color(0xFF2196F3), // Blue 500
    const Color(0xFF42A5F5), // Blue 400
    const Color(0xFF64B5F6), // Blue 300
    const Color(0xFF90CAF9), // Blue 200
    const Color(0xFF01579B), // Light Blue 900
    const Color(0xFF0277BD), // Light Blue 800
    const Color(0xFF0288D1), // Light Blue 700
    const Color(0xFF039BE5), // Light Blue 600
    const Color(0xFF03A9F4), // Light Blue 500
  ];
  return colors[hash.abs() % colors.length];
}

class MessagesPage extends StatelessWidget {
  final List<dynamic> chats;
  final bool loading;
  final VoidCallback onRefresh;
  final String currentUserId;
  final VoidCallback onChatClosed;
  final Map<String, bool> onlineMap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const MessagesPage({
    super.key,
    required this.chats,
    required this.loading,
    required this.onRefresh,
    required this.currentUserId,
    required this.onChatClosed,
    required this.onlineMap,
    required this.searchController,
    required this.onSearchChanged,
  });

  String _formatChatTime(dynamic updatedAt, BuildContext context) {
    final dt = _parseChatTime(updatedAt);
    if (dt == null) return '';

    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return TimeOfDay.fromDateTime(local).format(context);
    }

    if (date == yesterday) {
      return 'Yesterday';
    }

    return '${local.day.toString().padLeft(2, '0')} '
        '${_monthName(local.month)} '
        '${local.year}';
  }

  DateTime? _parseChatTime(dynamic updatedAt) {
    if (updatedAt == null) return null;

    if (updatedAt is DateTime) return updatedAt;

    if (updatedAt is Map) {
      final seconds = updatedAt['_seconds'] ?? updatedAt['seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      }
    }

    if (updatedAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(updatedAt);
      final normalized = hasTz ? updatedAt : '${updatedAt}Z';
      return DateTime.tryParse(normalized);
    }

    return null;
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey,
          indent: 16,
          endIndent: 16,
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Align(
            alignment: Alignment.center,

            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 18,
                color: AppColours.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        //  Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 22),
                hintText: 'Search conversations',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,  size: 20),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // "Recent Messages" Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recent Messages',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),

        //  Chat list
        Expanded(
          child: chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No conversations yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final List members =
                        chat['members'] ?? chat['userIds'] ?? [];
                    final otherUserId = members.firstWhere(
                      (u) => u != currentUserId,
                      orElse: () => 'Unknown',
                    );

                    final otherUserName = (chat['otherUserName'] ?? otherUserId)
                        .toString();
                    final otherUserRole =
                        (chat['otherUserRole'] ?? 'Private Chat').toString();
                    final chatId = (chat['id'] ?? chat['chatId'] ?? '')
                        .toString();

                    final unreadCounts = chat['unreadCounts'];
                    int unreadCount = 0;
                    if (unreadCounts is Map &&
                        unreadCounts[currentUserId] != null) {
                      final rawCount = unreadCounts[currentUserId];
                      unreadCount = rawCount is int
                          ? rawCount
                          : int.tryParse(rawCount.toString()) ?? 0;
                    }

                    return ChatTile(
                      chatId: chatId,
                      currentUserId: currentUserId,
                      otherUserId: otherUserId,
                      onChatClosed: onChatClosed,
                      onChatRead: onChatClosed,
                      name: otherUserName,
                      role: otherUserRole,
                      message: chat['lastMessage'] ?? '',
                      time: _formatChatTime(
                        chat['updatedAt'] ?? chat['lastMessageAt'],
                        context,
                      ),
                      isOnline: onlineMap[otherUserId] ?? false,
                      unreadCount: unreadCount,
                      avatarColor: _getColorForUser(otherUserId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ChatTile extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final VoidCallback onChatClosed;
  final VoidCallback? onChatRead;
  final String name;
  final String role;
  final String message;
  final String time;
  final bool isOnline;
  final int unreadCount;
  final Color avatarColor;

  const ChatTile({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.onChatClosed,
    this.onChatRead,
    required this.name,
    required this.role,
    required this.message,
    required this.time,
    required this.isOnline,
    required this.unreadCount,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? AppColours.primary.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isUnread ? Border.all(color: AppColours.primary.withOpacity(0.1)) : null,
          boxShadow: isUnread ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              if (chatId.isEmpty) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chatId,
                    currentUserId: currentUserId,
                    otherUserId: otherUserId,
                    userName: name,
                    userRole: role,
                    avatarUrl: '',
                    isOnline: isOnline,
                    onChatRead: onChatRead,
                  ),
                ),
              );
              onChatClosed();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: avatarColor,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              color: Colors.green.shade500,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 16,
                                  color: isUnread ? Colors.black87 : Colors.black.withOpacity(0.8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread ? AppColours.primary : Colors.grey.shade500,
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                            color: AppColours.primary.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                message.isEmpty ? 'No messages yet' : message,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isUnread ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: AppColours.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
