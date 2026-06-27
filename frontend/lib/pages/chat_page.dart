import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/models/chat_models.dart';
import '../core/models/chat_socket_event.dart';
import '../core/network/api_exception.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
    required this.conversation,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;
  final ConversationSummary conversation;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageItem> _messages = <MessageItem>[];
  final Set<int> _deletingMessageIds = <int>{};
  final ImagePicker _imagePicker = ImagePicker();

  StreamSubscription<ChatSocketEvent>? _socketSubscription;
  bool _loading = true;
  bool _sending = false;
  bool _uploadingImage = false;
  bool _friendConversation = false;
  bool _temporaryConversation = false;
  bool _canSendMessage = true;
  bool _friendRequestSubmitting = false;
  bool _friendRequestSent = false;
  bool _counterpartOnline = false;
  int _temporaryMessageLimit = 10;
  int _temporaryMessageCount = 0;
  int _temporaryMessageRemaining = 10;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _counterpartOnline = widget.conversation.counterpart?.online ?? false;
    _applyConversationSummary(widget.conversation);
    _socketSubscription = widget.chatSocketClient.events.listen(
      _handleSocketEvent,
    );
    unawaited(_reloadMessages(markRead: true));
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSocketEvent(ChatSocketEvent event) {
    if (!mounted) {
      return;
    }

    if (event.type == ChatSocketEventType.presenceChanged &&
        event.userId == widget.conversation.counterpart?.id) {
      setState(() {
        _counterpartOnline = event.online ?? false;
      });
      return;
    }

    if (event.conversationId != widget.conversation.id) {
      return;
    }

    if (event.type == ChatSocketEventType.messageAck ||
        event.type == ChatSocketEventType.messageReceived) {
      unawaited(_reloadMessages(markRead: true));
      return;
    }

    if (event.type == ChatSocketEventType.error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(event.notice ?? '消息发送失败')));
      unawaited(_reloadMessages(markRead: false));
    }
  }

  Future<void> _reloadMessages({required bool markRead}) async {
    try {
      final page = await widget.controller.api.fetchMessages(
        conversationId: widget.conversation.id,
        page: 1,
        pageSize: 50,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages
          ..clear()
          ..addAll(page.list);
        _friendConversation = page.friendConversation;
        _temporaryConversation = page.temporaryConversation;
        _temporaryMessageLimit = page.temporaryMessageLimit;
        _temporaryMessageCount = page.temporaryMessageCount;
        _temporaryMessageRemaining = page.temporaryMessageRemaining;
        _canSendMessage = page.canSendMessage;
        if (_friendConversation) {
          _friendRequestSent = false;
        }
        _loading = false;
        _errorMessage = null;
      });
      if (markRead) {
        unawaited(
          widget.controller.api.markConversationRead(widget.conversation.id),
        );
      }
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _applyConversationSummary(ConversationSummary summary) {
    _friendConversation = summary.friendConversation;
    _temporaryConversation = summary.temporaryConversation;
    _temporaryMessageLimit = summary.temporaryMessageLimit;
    _temporaryMessageCount = summary.temporaryMessageCount;
    _temporaryMessageRemaining = summary.temporaryMessageRemaining;
    _canSendMessage = summary.canSendMessage;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _sending || _uploadingImage) {
      return;
    }
    if (!_canSendMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('临时聊天消息已达上限，请先添加好友')));
      return;
    }

    final rawContent = _messageController.text;
    setState(() {
      _sending = true;
    });
    FocusScope.of(context).unfocus();

    final clientMessageId = DateTime.now().microsecondsSinceEpoch.toString();
    final sentBySocket = widget.chatSocketClient.sendChatMessage(
      conversationId: widget.conversation.id,
      content: content,
      clientMessageId: clientMessageId,
    );

    if (sentBySocket) {
      _messageController.clear();
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (mounted) {
            unawaited(_reloadMessages(markRead: true));
          }
        }),
      );
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
      return;
    }

    try {
      _messageController.clear();
      await widget.controller.api.sendMessage(
        conversationId: widget.conversation.id,
        content: content,
        clientMessageId: clientMessageId,
      );
      if (mounted) {
        await _reloadMessages(markRead: true);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _restoreInput(rawContent);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _restoreInput(rawContent);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_uploadingImage || _sending) {
      return;
    }
    if (!_canSendMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('临时聊天消息已达上限，请先添加好友')));
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null || !mounted) {
        return;
      }
      if (!_isSupportedImageFile(file.path)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('只能发送图片文件')));
        return;
      }

      setState(() {
        _uploadingImage = true;
      });

      await widget.controller.api.uploadConversationImage(
        conversationId: widget.conversation.id,
        filePath: file.path,
        fileName: file.name,
      );
      if (mounted) {
        await _reloadMessages(markRead: true);
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
          _uploadingImage = false;
        });
      }
    }
  }

  Future<void> _sendFriendRequest() async {
    final counterpartId = widget.conversation.counterpart?.id;
    if (counterpartId == null ||
        _friendRequestSubmitting ||
        _friendConversation) {
      return;
    }

    setState(() {
      _friendRequestSubmitting = true;
    });

    try {
      await widget.controller.api.sendFriendRequest(toUserId: counterpartId);
      if (!mounted) {
        return;
      }
      setState(() {
        _friendRequestSent = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('好友申请已发送')));
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
          _friendRequestSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(MessageItem message) async {
    if (!message.mine || _deletingMessageIds.contains(message.id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除消息'),
          content: const Text('删除后双方都会看不到这条消息，确定继续吗？'),
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
      _deletingMessageIds.add(message.id);
    });

    try {
      await widget.controller.api.deleteMessage(
        conversationId: widget.conversation.id,
        messageId: message.id,
      );
      if (mounted) {
        await _reloadMessages(markRead: false);
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
          _deletingMessageIds.remove(message.id);
        });
      }
    }
  }

  void _restoreInput(String content) {
    _messageController.text = content;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _showImagePreview(String url) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    AppConfig.resolveApiUrl(url),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '图片加载失败',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final counterpart = conversation.counterpart;
    final counterpartName = counterpart == null
        ? ''
        : counterpart.nickname.trim();
    final title = conversation.title.trim().isEmpty
        ? (counterpartName.isNotEmpty ? counterpartName : '聊天')
        : conversation.title.trim();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              _counterpartOnline ? '在线' : '离线',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _counterpartOnline
                    ? const Color(0xFF16A34A)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_temporaryConversation)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TemporaryChatBanner(
                remaining: _temporaryMessageRemaining,
                limit: _temporaryMessageLimit,
                sentCount: _temporaryMessageCount,
                requestSent: _friendRequestSent,
                submitting: _friendRequestSubmitting,
                onAddFriend: counterpart == null
                    ? null
                    : () {
                        unawaited(_sendFriendRequest());
                      },
              ),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _InlineNotice(message: _errorMessage!),
            ),
          Expanded(
            child: _loading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _EmptyMessageState(
                    onRefresh: () {
                      unawaited(_reloadMessages(markRead: true));
                    },
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageItemView(
                        message: message,
                        deleting: _deletingMessageIds.contains(message.id),
                        onDelete: message.mine
                            ? () {
                                unawaited(_deleteMessage(message));
                              }
                            : null,
                        onPreviewImage: message.contentType == 'IMAGE'
                            ? () {
                                unawaited(_showImagePreview(message.content));
                              }
                            : null,
                      );
                    },
                  ),
          ),
          _Composer(
            controller: _messageController,
            enabled: _canSendMessage,
            sending: _sending,
            uploadingImage: _uploadingImage,
            onPickImage: () {
              unawaited(_pickAndSendImage());
            },
            onSend: () {
              unawaited(_sendMessage());
            },
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.uploadingImage,
    required this.onPickImage,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final bool uploadingImage;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final busy = sending || uploadingImage;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: enabled && !busy ? onPickImage : null,
              icon: uploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
              tooltip: '发送图片',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !busy,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  labelText: enabled ? '输入消息' : '临时聊天已达上限',
                  hintText: enabled ? '说点什么吧…' : '添加好友后可继续发送消息',
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: enabled && !busy ? onSend : null,
              child: Text(sending ? '发送中' : '发送'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemporaryChatBanner extends StatelessWidget {
  const _TemporaryChatBanner({
    required this.remaining,
    required this.limit,
    required this.sentCount,
    required this.requestSent,
    required this.submitting,
    required this.onAddFriend,
  });

  final int remaining;
  final int limit;
  final int sentCount;
  final bool requestSent;
  final bool submitting;
  final VoidCallback? onAddFriend;

  @override
  Widget build(BuildContext context) {
    final reachedLimit = remaining <= 0;
    final title = reachedLimit ? '临时聊天已达上限' : '当前为临时聊天';
    final message = reachedLimit
        ? '双方已发送 $sentCount/$limit 条临时消息。添加好友后才可继续发送。'
        : '当前还可发送 $remaining 条消息。若想继续长期联系，可直接添加对方为好友。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reachedLimit ? const Color(0xFFFFF1F2) : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reachedLimit
              ? const Color(0xFFFDA4AF)
              : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reachedLimit ? Icons.lock_outline : Icons.info_outline_rounded,
            color: reachedLimit
                ? const Color(0xFFBE123C)
                : const Color(0xFFB45309),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(message),
                if (requestSent) ...[
                  const SizedBox(height: 6),
                  const Text(
                    '好友申请已发送，等待对方通过后即可继续长期聊天。',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          if (onAddFriend != null)
            TextButton(
              onPressed: requestSent || submitting ? null : onAddFriend,
              child: Text(submitting ? '提交中' : (requestSent ? '已发送' : '添加好友')),
            ),
        ],
      ),
    );
  }
}

class _MessageItemView extends StatelessWidget {
  const _MessageItemView({
    required this.message,
    required this.deleting,
    required this.onDelete,
    required this.onPreviewImage,
  });

  final MessageItem message;
  final bool deleting;
  final VoidCallback? onDelete;
  final VoidCallback? onPreviewImage;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final imageMessage = message.contentType == 'IMAGE';

    return Opacity(
      opacity: deleting ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!mine)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 4),
              child: Text(
                message.sender.nickname,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          GestureDetector(
            onLongPress: onDelete,
            onTap: onPreviewImage,
            child: imageMessage
                ? _ImageMessageContent(message: message, mine: mine)
                : _TextMessageBubble(message: message),
          ),
        ],
      ),
    );
  }
}

class _ImageMessageContent extends StatelessWidget {
  const _ImageMessageContent({required this.message, required this.mine});

  final MessageItem message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.62;

    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              AppConfig.resolveApiUrl(message.content),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return Container(
                  color: Colors.grey.shade100,
                  height: 180,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('图片加载失败'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatMessageTime(message.sentAt),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
      ],
    );
  }
}

class _TextMessageBubble extends StatelessWidget {
  const _TextMessageBubble({required this.message});

  final MessageItem message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final bubbleColor = mine
        ? Theme.of(context).colorScheme.primary
        : Colors.white;
    final textColor = mine ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine) ...[
          CircleAvatar(
            radius: 16,
            child: Text(
              _avatarText(message.sender.nickname, message.sender.username),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMessageTime(message.sentAt),
                  style: TextStyle(
                    color: mine ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMessageState extends StatelessWidget {
  const _EmptyMessageState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 12),
              Text(
                '暂无消息',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '发送第一条消息，开启聊天。',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onRefresh, child: const Text('刷新')),
            ],
          ),
        ),
      ],
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

bool _isSupportedImageFile(String path) {
  final value = path.toLowerCase();
  return value.endsWith('.jpg') ||
      value.endsWith('.jpeg') ||
      value.endsWith('.png') ||
      value.endsWith('.gif') ||
      value.endsWith('.webp');
}

String _avatarText(String first, String second) {
  final source = first.trim().isNotEmpty ? first.trim() : second.trim();
  if (source.isEmpty) {
    return '聊';
  }
  return source.substring(0, 1);
}

String _formatMessageTime(DateTime? value) {
  if (value == null) {
    return '';
  }
  return DateFormat('HH:mm').format(value.toLocal());
}
