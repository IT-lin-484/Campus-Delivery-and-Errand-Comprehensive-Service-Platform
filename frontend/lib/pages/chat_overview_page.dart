import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/chat_models.dart';
import '../core/models/chat_socket_event.dart';
import '../core/network/api_exception.dart';
import '../core/network/backend_api.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'chat_page.dart';

class ChatOverviewPage extends StatefulWidget {
  const ChatOverviewPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;

  @override
  State<ChatOverviewPage> createState() => _ChatOverviewPageState();
}

class _ChatOverviewPageState extends State<ChatOverviewPage> {
  final List<ConversationSummary> _conversations = <ConversationSummary>[];
  final Set<int> _deletingConversationIds = <int>{};

  StreamSubscription<ChatSocketEvent>? _socketSubscription;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _socketSubscription = widget.chatSocketClient.events.listen(
      _handleSocketEvent,
    );
    unawaited(_reload());
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    if (!mounted) {
      return;
    }

    if (event.type == ChatSocketEventType.messageAck ||
        event.type == ChatSocketEventType.messageReceived ||
        event.type == ChatSocketEventType.presenceChanged ||
        event.type == ChatSocketEventType.connected) {
      unawaited(_reload(silent: true));
    }
  }

  Future<void> _reload({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final conversations = await widget.controller.api.fetchConversations();
      if (!mounted) {
        return;
      }
      setState(() {
        _conversations
          ..clear()
          ..addAll(conversations);
        _errorMessage = null;
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
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _startNewChat() async {
    final user = await showModalBottomSheet<SearchUserResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSearchSheet(api: widget.controller.api),
    );
    if (user == null || !mounted) {
      return;
    }

    try {
      final conversation = await widget.controller.api
          .createPrivateConversation(friendId: user.id);
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
        await _reload(silent: true);
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
    }
  }

  Future<void> _openConversation(ConversationSummary conversation) async {
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
      await _reload(silent: true);
    }
  }

  Future<void> _deleteConversation(ConversationSummary conversation) async {
    if (_deletingConversationIds.contains(conversation.id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除聊天'),
          content: const Text('删除后双方都会清空该聊天记录，确定继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _deletingConversationIds.add(conversation.id);
    });

    try {
      await widget.controller.api.deleteConversation(conversation.id);
      if (mounted) {
        await _reload(silent: true);
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
          _deletingConversationIds.remove(conversation.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '长按聊天可删除记录',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              FilledButton.icon(
                onPressed: _startNewChat,
                icon: const Icon(Icons.search_rounded),
                label: const Text('搜索用户'),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(
              message: _errorMessage!,
              onRetry: () {
                unawaited(_reload());
              },
            ),
          ],
          const SizedBox(height: 12),
          if (_loading && _conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_conversations.isEmpty)
            _EmptyState(onStartChat: _startNewChat)
          else
            ..._conversations.map(
              (conversation) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ConversationCard(
                  conversation: conversation,
                  deleting: _deletingConversationIds.contains(conversation.id),
                  onTap: () => _openConversation(conversation),
                  onLongPress: () => _deleteConversation(conversation),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.deleting,
    required this.onTap,
    required this.onLongPress,
  });

  final ConversationSummary conversation;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final counterpart = conversation.counterpart;
    final title = conversation.title.trim().isEmpty
        ? '未命名会话'
        : conversation.title.trim();
    final preview = conversation.lastMessagePreview.trim().isEmpty
        ? '开始聊天吧'
        : conversation.lastMessagePreview.trim();

    return Opacity(
      opacity: deleting ? 0.5 : 1,
      child: Card(
        child: InkWell(
          onTap: deleting ? null : onTap,
          onLongPress: deleting ? null : onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    _avatarText(title, counterpart?.username ?? ''),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatConversationTime(conversation.lastMessageAt),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          if (conversation.temporaryConversation) ...[
                            const SizedBox(width: 8),
                            const _Tag(text: '临时聊天'),
                          ],
                          if (counterpart?.online == true) ...[
                            const SizedBox(width: 8),
                            const _DotLabel(
                              label: '在线',
                              color: Color(0xFF16A34A),
                            ),
                          ],
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            _UnreadBadge(count: conversation.unreadCount),
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
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DotLabel extends StatelessWidget {
  const _DotLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB45309),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartChat});

  final VoidCallback onStartChat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              '暂无聊天',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '先搜索一个用户，再开始聊天。',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onStartChat,
              child: const Text('搜索用户'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            const SizedBox(width: 12),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  const _UserSearchSheet({required this.api});

  final BackendApi api;

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final TextEditingController _keywordController = TextEditingController();
  final List<SearchUserResult> _results = <SearchUserResult>[];
  bool _searching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _errorMessage = '请输入用户名或昵称';
        _results.clear();
      });
      return;
    }

    setState(() {
      _searching = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.api.searchUsers(keyword: keyword);
      if (!mounted) {
        return;
      }
      setState(() {
        _results
          ..clear()
          ..addAll(results);
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _results.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _results.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '搜索用户',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keywordController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: const InputDecoration(
                          labelText: '用户名或昵称',
                          hintText: '输入关键词搜索',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _searching ? null : _search,
                      child: Text(_searching ? '搜索中' : '搜索'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _InlineNotice(message: _errorMessage!),
                ),
              if (_results.isEmpty && !_searching) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '搜索后选择一个用户，系统会自动创建或打开私聊。',
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                SizedBox(
                  height: 420,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      return Card(
                        child: ListTile(
                          onTap: item.relationStatus == 'SELF'
                              ? null
                              : () => Navigator.of(context).pop(item),
                          leading: CircleAvatar(
                            child: Text(
                              _avatarText(item.nickname, item.username),
                            ),
                          ),
                          title: Text(item.nickname),
                          subtitle: Text(
                            '@${item.username} · ${_relationStatusLabel(item.relationStatus)}',
                          ),
                          trailing: item.relationStatus == 'SELF'
                              ? const Text('自己')
                              : FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.of(context).pop(item),
                                  child: const Text('发消息'),
                                ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
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

String _avatarText(String first, String second) {
  final source = first.trim().isNotEmpty ? first.trim() : second.trim();
  if (source.isEmpty) {
    return '聊';
  }
  return source.substring(0, 1);
}

String _relationStatusLabel(String value) {
  switch (value) {
    case 'SELF':
      return '自己';
    case 'FRIEND':
      return '好友';
    case 'REQUEST_SENT':
      return '已申请';
    case 'REQUEST_RECEIVED':
      return '待确认';
    default:
      return '陌生人';
  }
}

String _formatConversationTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  final time = value.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(time.year, time.month, time.day);
  final diffDays = today.difference(target).inDays;

  if (diffDays == 0) {
    return DateFormat('HH:mm').format(time);
  }
  if (diffDays == 1) {
    return '昨天';
  }
  if (diffDays > 1 && diffDays < 7) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[time.weekday - 1];
  }
  return DateFormat('MM-dd').format(time);
}
