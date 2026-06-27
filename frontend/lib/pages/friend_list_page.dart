import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/friend_models.dart';
import '../core/network/api_exception.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'chat_page.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  final Set<String> _busyActions = <String>{};

  List<FriendItem> _friends = const <FriendItem>[];
  FriendRequestPage _requestPage = FriendRequestPage(
    received: const <FriendRequestItem>[],
    sent: const <FriendRequestItem>[],
  );
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait<dynamic>([
        widget.controller.api.listFriends(),
        widget.controller.api.listFriendRequests(),
      ]);
      if (!mounted) {
        return;
      }

      final friends = futures[0] as List<FriendItem>;
      final requestPage = futures[1] as FriendRequestPage;
      final friendIds = friends.map((item) => item.userId).toSet();

      setState(() {
        _friends = friends;
        _requestPage = FriendRequestPage(
          received: requestPage.received
              .where(
                (item) =>
                    item.status == 'PENDING' &&
                    !friendIds.contains(item.fromUserId),
              )
              .toList(growable: false),
          sent: requestPage.sent
              .where(
                (item) =>
                    item.status == 'PENDING' &&
                    !friendIds.contains(item.toUserId),
              )
              .toList(growable: false),
        );
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openChat({
    required int userId,
    required String actionKey,
  }) async {
    if (_busyActions.contains(actionKey)) {
      return;
    }

    setState(() {
      _busyActions.add(actionKey);
    });

    try {
      final conversation = await widget.controller.api
          .createPrivateConversation(friendId: userId);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            controller: widget.controller,
            chatSocketClient: widget.chatSocketClient,
            conversation: conversation,
          ),
        ),
      );
      if (mounted) {
        await _reload();
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busyActions.remove(actionKey);
        });
      }
    }
  }

  Future<void> _handleRequestAction({
    required String actionKey,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_busyActions.contains(actionKey)) {
      return;
    }

    setState(() {
      _busyActions.add(actionKey);
    });

    try {
      await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busyActions.remove(actionKey);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        _friends.isNotEmpty ||
        _requestPage.received.isNotEmpty ||
        _requestPage.sent.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('我的好友')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InlineNotice(message: _errorMessage!),
              ),
            if (_loading && !hasContent)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!hasContent)
              const _EmptyFriendState()
            else ...[
              _SectionCard(
                title: '好友列表',
                subtitle: '点击好友可直接进入聊天',
                child: _friends.isEmpty
                    ? const _SectionEmptyText('还没有好友，先从临时聊天里添加好友吧')
                    : Column(
                        children: _friends
                            .map(
                              (friend) => _FriendTile(
                                friend: friend,
                                busy: _busyActions.contains(
                                  'friend-chat-${friend.userId}',
                                ),
                                onTap: () => _openChat(
                                  userId: friend.userId,
                                  actionKey: 'friend-chat-${friend.userId}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '收到的申请',
                subtitle: '通过后即可长期聊天',
                child: _requestPage.received.isEmpty
                    ? const _SectionEmptyText('暂无收到的好友申请')
                    : Column(
                        children: _requestPage.received
                            .map(
                              (request) => _FriendRequestTile(
                                title: request.fromNickname,
                                subtitle: _buildRequestSubtitle(
                                  request.message,
                                  request.createdAt,
                                ),
                                avatarSeed: request.fromNickname,
                                busy:
                                    _busyActions.contains(
                                      'accept-${request.id}',
                                    ) ||
                                    _busyActions.contains(
                                      'reject-${request.id}',
                                    ),
                                actions: [
                                  OutlinedButton(
                                    onPressed:
                                        _busyActions.contains(
                                          'reject-${request.id}',
                                        )
                                        ? null
                                        : () => _handleRequestAction(
                                            actionKey: 'reject-${request.id}',
                                            action: () async {
                                              await widget.controller.api
                                                  .rejectFriendRequest(
                                                    request.id,
                                                  );
                                            },
                                            successMessage: '已拒绝好友申请',
                                          ),
                                    child: const Text('拒绝'),
                                  ),
                                  FilledButton(
                                    onPressed:
                                        _busyActions.contains(
                                          'accept-${request.id}',
                                        )
                                        ? null
                                        : () => _handleRequestAction(
                                            actionKey: 'accept-${request.id}',
                                            action: () async {
                                              await widget.controller.api
                                                  .acceptFriendRequest(
                                                    request.id,
                                                  );
                                            },
                                            successMessage: '已通过好友申请',
                                          ),
                                    child: const Text('通过'),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: '发出的申请',
                subtitle: '等待对方处理',
                child: _requestPage.sent.isEmpty
                    ? const _SectionEmptyText('暂无发出的好友申请')
                    : Column(
                        children: _requestPage.sent
                            .map(
                              (request) => _FriendRequestTile(
                                title: request.toNickname,
                                subtitle: _buildRequestSubtitle(
                                  request.message,
                                  request.createdAt,
                                ),
                                avatarSeed: request.toNickname,
                                busy: _busyActions.contains(
                                  'cancel-${request.id}',
                                ),
                                actions: [
                                  OutlinedButton(
                                    onPressed:
                                        _busyActions.contains(
                                          'cancel-${request.id}',
                                        )
                                        ? null
                                        : () => _handleRequestAction(
                                            actionKey: 'cancel-${request.id}',
                                            action: () async {
                                              await widget.controller.api
                                                  .cancelFriendRequest(
                                                    request.id,
                                                  );
                                            },
                                            successMessage: '已撤回好友申请',
                                          ),
                                    child: const Text('撤回'),
                                  ),
                                ],
                              ),
                            )
                            .toList(growable: false),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _buildRequestSubtitle(String? message, DateTime? time) {
    final note = message?.trim();
    final parts = <String>[];
    if (note != null && note.isNotEmpty) {
      parts.add(note);
    }
    if (time != null) {
      parts.add(DateFormat('MM-dd HH:mm').format(time.toLocal()));
    }
    return parts.isEmpty ? '暂无附言' : parts.join('  ·  ');
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    required this.friend,
    required this.busy,
    required this.onTap,
  });

  final FriendItem friend;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (friend.bio != null && friend.bio!.trim().isNotEmpty) {
      subtitleParts.add(friend.bio!.trim());
    }
    if (friend.becameFriendsAt != null) {
      subtitleParts.add(
        '成为好友 ${DateFormat('yyyy-MM-dd').format(friend.becameFriendsAt!.toLocal())}',
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(_avatarText(friend.nickname))),
      title: Text(
        friend.nickname,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitleParts.isEmpty
            ? '@${friend.username}'
            : '@${friend.username}  ·  ${subtitleParts.join('  ·  ')}',
      ),
      trailing: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: busy ? null : onTap,
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.title,
    required this.subtitle,
    required this.avatarSeed,
    required this.busy,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final String avatarSeed;
  final bool busy;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(_avatarText(avatarSeed))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: action,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEmptyText extends StatelessWidget {
  const _SectionEmptyText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }
}

class _EmptyFriendState extends StatelessWidget {
  const _EmptyFriendState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 52,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              '还没有好友内容',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '先从订单临时聊天开始，聊满后可在聊天页直接添加好友。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Text(message),
    );
  }
}

String _avatarText(String source) {
  final value = source.trim();
  if (value.isEmpty) {
    return '友';
  }
  return value.substring(0, 1);
}
