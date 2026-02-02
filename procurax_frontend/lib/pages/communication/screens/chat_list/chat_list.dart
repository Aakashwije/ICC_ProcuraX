

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../widgets/bottom_nav.dart';
import 'package:procurax_frontend/services/chat_service.dart';

import 'chat_title.dart';
//import '../files/files_screen.dart';
import '../alerts/alerts_screen.dart';
import '../calls/calls_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}



class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  final ChatService _chatService = ChatService();
  String currentUserId = 'user_1';
  final TextEditingController _searchController = TextEditingController();
    final TextEditingController _userSearchController =
      TextEditingController();
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
  bool debugSimulatePresence = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchChats();
    fetchAlerts();
    _startPresence();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
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
      await _refreshPresence();
      await fetchAlerts();
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
      final lastMessage = (chat['lastMessage'] ?? '')
          .toString()
          .toLowerCase();

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


  Future<void> _sendPresenceHeartbeat() async {
    try {
      await _chatService.sendPresenceHeartbeat(currentUserId);
      if (kDebugMode && debugSimulatePresence) {
        final otherUserId =
            currentUserId == 'user_1' ? 'user_2' : 'user_1';
        if (otherUserId != currentUserId) {
          await _chatService.sendPresenceHeartbeat(otherUserId);
        }
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load users')),
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
                                            : (phone.isNotEmpty
                                                ? phone
                                                : userId),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        phone.isNotEmpty ? phone : userId,
                                      ),
                                      trailing: userId == currentUserId
                                          ? const Icon(Icons.check,
                                              color: AppColours.primary)
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = _filterUsers(_userSearchController.text)
                .where((u) => _getUserId(u) != currentUserId)
                .toList();

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
                      'Select contact',
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
                          hintText: 'Search by  name',
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
                                    

                                    return ListTile(
                                      leading: CircleAvatar(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      title: Text(
                                        name.isNotEmpty ? name : userId,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                                          debugPrint(
                                            'Failed to create chat: $e',
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(this.context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Failed to create chat'),
                                            ),
                                          );
                                        }
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

  Future<void> _refreshPresence() async {
    if (chats.isEmpty) return;

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

    if (otherUserIds.isEmpty) return;

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
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColours.primary, size: 30,),
          onPressed: () {},
        ),
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
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: debugSimulatePresence
                  ? 'Disable simulate presence'
                  : 'Simulate presence',
              icon: Icon(
                debugSimulatePresence ? Icons.wifi : Icons.wifi_off,
                color: AppColours.primary,
              ),
              onPressed: () async {
                setState(() {
                  debugSimulatePresence = !debugSimulatePresence;
                });
                await _sendPresenceHeartbeat();
                await _refreshPresence();
              },
            ),
          if (kDebugMode)
            TextButton.icon(
              onPressed: _showCurrentUserPicker,
              icon: const Icon(Icons.person, color: AppColours.primary),
              label: Text(
                currentUserId,
                style: const TextStyle(
                  color: AppColours.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
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
          ? FloatingActionButton(
              onPressed: _showUserPicker,
              backgroundColor: AppColours.primary,
              child: const Icon(Icons.add, color: Colors.white),
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
    if (updatedAt == null) return '';

    if (updatedAt is DateTime) {
      return TimeOfDay.fromDateTime(updatedAt.toLocal()).format(context);
    }

    if (updatedAt is Map) {
      final seconds = updatedAt['_seconds'] ?? updatedAt['seconds'];
      if (seconds is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        ).toLocal();
        return TimeOfDay.fromDateTime(dt).format(context);
      }
    }

    if (updatedAt is String) {
      final hasTz = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(updatedAt);
      final normalized = hasTz ? updatedAt : '${updatedAt}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        return TimeOfDay.fromDateTime(parsed.toLocal()).format(context);
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 1, color: Colors.grey,indent: 16, endIndent: 16),
        
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
    

        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child:  TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Conversations',
                filled: true,
                fillColor: const Color.fromARGB(255, 211, 209, 209), //light gray 
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30), // pill shape
                    borderSide: BorderSide.none, // no outline
                ),

              ),
              onChanged: onSearchChanged,
            ),
          ),
        ),

        const SizedBox(height: 10),
        const Divider(height: 1),

        // 💬 Chat list
        Expanded(
          child: chats.isEmpty
              ? const Center(child: Text('No conversations'))
              : ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final List members =
                        chat['members'] ?? chat['userIds'] ?? [];
                    final otherUserId = members.firstWhere(
                      (u) => u != currentUserId,
                      orElse: () => 'Unknown',
                    );

                    final otherUserName =
                        (chat['otherUserName'] ?? otherUserId).toString();
                    final otherUserRole =
                        (chat['otherUserRole'] ?? 'Private Chat').toString();
                    final chatId = (chat['id'] ?? chat['chatId'] ?? '').toString();

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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
