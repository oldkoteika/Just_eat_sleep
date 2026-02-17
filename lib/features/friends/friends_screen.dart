import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/friends/friends_storage.dart';
import '../../core/repositories/repository_providers.dart';
import '../../shared/models/friend.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/bottom_navigation.dart';
import '../workout/add_workout_screen.dart';
import 'friend_detail_card.dart';
import 'scan_friend_qr_screen.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateHome;

  const FriendsScreen({
    super.key,
    this.onNavigateHome,
  });

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Friend> _allFriends = [];
  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final list = await FriendsStorage.getFriends();
    if (!mounted) return;
    setState(() {
      _allFriends = list;
      _filteredFriends = list;
    });
  }

  void _filterFriends() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) => friend.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _openQuickInvite(Friend friend) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => AddWorkoutScreen(initialFriend: friend),
      ),
    );
  }

  Future<void> _showFriendDetail(Friend friend) async {
    final eventsRepo = ref.read(eventsRepositoryProvider);
    final currentUser = await ref.read(userRepositoryProvider).getCurrentUser();
    final myId = currentUser?.id;
    final allEvents = await eventsRepo.getEvents();
    final friendEvents = allEvents
        .where((e) {
          final iAmSender = myId != null && e.sender == myId;
          final friendIsRecipient = e.recipient == friend.id || e.recipients.contains(friend.id);
          final friendIsSender = e.sender == friend.id;
          final iAmRecipient = myId != null && e.recipients.contains(myId);
          return (iAmSender && friendIsRecipient) || (friendIsSender && iAmRecipient);
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final limited = friendEvents.take(10).toList();

    final updatedFriend = await showCupertinoModalPopup<Friend>(
      context: context,
      builder: (context) => FriendDetailCard(
        friend: friend,
        friendEvents: limited,
        onDeleted: () async {
          await FriendsStorage.removeFriend(friend.id);
          if (!mounted) return;
          setState(() {
            _allFriends = _allFriends.where((f) => f.id != friend.id).toList();
            _filteredFriends =
                _filteredFriends.where((f) => f.id != friend.id).toList();
          });
        },
        onInviteToWorkout: () {
          Navigator.of(context).pop();
          _openQuickInvite(friend);
        },
      ),
    );

    if (updatedFriend != null) {
      setState(() {
        _allFriends = _allFriends.map((f) => f.id == updatedFriend.id ? updatedFriend : f).toList();
        _filteredFriends = _filteredFriends.map((f) => f.id == updatedFriend.id ? updatedFriend : f).toList();
      });
      await FriendsStorage.saveFriends(_allFriends);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? CupertinoColors.systemGrey6.darkColor
        : CupertinoColors.systemGrey6;
    final textColor = isDark
        ? CupertinoColors.white
        : CupertinoColors.label;
    final secondaryTextColor = isDark
        ? CupertinoColors.systemGrey
        : CupertinoColors.systemGrey2;

    return AppScaffold(
      title: 'Мои друзья',
      onHomePressed: widget.onNavigateHome,
      onAddPressed: _showAddFriendOptions,
      body: Column(
        children: [
          // Отступ от верхней панели
          SizedBox(
            height: AppScaffold.kTopBarHeight + AppScaffold.kContentTopGap,
          ),
          // Поиск во всю длину
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.black
                  : CupertinoColors.systemBackground,
            ),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Поиск',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Список друзей
          Expanded(
            child: _filteredFriends.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Нет друзей'
                          : 'Ничего не найдено',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: kBottomNavContentHeight + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isLast = index == _filteredFriends.length - 1;

                      return Dismissible(
                        key: Key('friend_${friend.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: CupertinoColors.destructiveRed,
                          child: const Icon(
                            CupertinoIcons.delete,
                            color: CupertinoColors.white,
                            size: 28,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showCupertinoDialog<bool>(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Удалить друга?'),
                              content: Text(
                                '${friend.name} будет удалён из списка друзей.',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Отмена'),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) async {
                          await FriendsStorage.removeFriend(friend.id);
                          if (!mounted) return;
                          setState(() {
                            _allFriends = _allFriends.where((f) => f.id != friend.id).toList();
                            _filteredFriends = _filteredFriends.where((f) => f.id != friend.id).toList();
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _showFriendDetail(friend),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 0,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.activeBlue
                                            .withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          friend.initials,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: CupertinoColors.activeBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        friend.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: const EdgeInsets.all(8),
                                      minSize: 0,
                                      onPressed: () => _openQuickInvite(friend),
                                      child: Icon(
                                        CupertinoIcons.calendar_badge_plus,
                                        size: 24,
                                        color: CupertinoColors.activeBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 56),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: secondaryTextColor.withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddFriendOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? CupertinoColors.white : CupertinoColors.label;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Добавить друга',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _addFriendFromCamera();
            },
            child: const Text('Сканировать QR-код'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _addFriendFromGallery();
            },
            child: const Text('Выбрать QR-код из галереи'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          isDefaultAction: true,
          child: const Text('Отмена'),
        ),
      ),
    );
  }

  Future<void> _addFriendFromCamera() async {
    final existingIds = _allFriends.map((f) => f.id).toSet();
    final friend = await Navigator.of(context).push<Friend>(
      CupertinoPageRoute(
        builder: (context) => ScanFriendQrScreen(existingFriendIds: existingIds),
      ),
    );

    if (friend != null && mounted) {
      await FriendsStorage.addFriend(friend);
      await _loadFriends();
    }
  }

  Future<void> _addFriendFromGallery() async {
    final existingIds = _allFriends.map((f) => f.id).toSet();
    final friend = await Navigator.of(context).push<Friend>(
      CupertinoPageRoute(
        builder: (context) => ScanFriendQrScreen(
          startWithGallery: true,
          existingFriendIds: existingIds,
        ),
      ),
    );

    if (friend != null && mounted) {
      await FriendsStorage.addFriend(friend);
      await _loadFriends();
    }
  }
}
