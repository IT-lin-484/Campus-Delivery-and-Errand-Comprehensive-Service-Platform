import 'json_utils.dart';

class ChatUserSummary {
  ChatUserSummary({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.online,
  });

  final int id;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final bool online;

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    return ChatUserSummary(
      id: readInt(json['id']),
      username: readString(json['username']),
      nickname: readString(json['nickname']),
      avatarUrl: readNullableString(json['avatarUrl']),
      online: readBool(json['online']),
    );
  }
}

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.avatarUrl,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.memberCount,
    required this.counterpart,
    required this.friendConversation,
    required this.temporaryConversation,
    required this.temporaryMessageLimit,
    required this.temporaryMessageCount,
    required this.temporaryMessageRemaining,
    required this.canSendMessage,
  });

  final int id;
  final String type;
  final String title;
  final String? avatarUrl;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final int memberCount;
  final ChatUserSummary? counterpart;
  final bool friendConversation;
  final bool temporaryConversation;
  final int temporaryMessageLimit;
  final int temporaryMessageCount;
  final int temporaryMessageRemaining;
  final bool canSendMessage;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final counterpartJson = json['counterpart'];
    return ConversationSummary(
      id: readInt(json['id']),
      type: readString(json['type'], fallback: 'PRIVATE'),
      title: readString(json['title'], fallback: '未命名会话'),
      avatarUrl: readNullableString(json['avatarUrl']),
      lastMessagePreview: readString(json['lastMessagePreview']),
      lastMessageAt: readDateTime(json['lastMessageAt']),
      unreadCount: readInt(json['unreadCount']),
      memberCount: readInt(json['memberCount'], fallback: 2),
      friendConversation: readBool(json['friendConversation']),
      temporaryConversation: readBool(json['temporaryConversation']),
      temporaryMessageLimit: readInt(json['temporaryMessageLimit']),
      temporaryMessageCount: readInt(json['temporaryMessageCount']),
      temporaryMessageRemaining: readInt(json['temporaryMessageRemaining']),
      canSendMessage: readBool(json['canSendMessage'], fallback: true),
      counterpart: counterpartJson is Map<String, dynamic>
          ? ChatUserSummary.fromJson(counterpartJson)
          : counterpartJson is Map
          ? ChatUserSummary.fromJson(Map<String, dynamic>.from(counterpartJson))
          : null,
    );
  }
}

class MessageItem {
  MessageItem({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.clientMessageId,
    required this.contentType,
    required this.content,
    required this.status,
    required this.sentAt,
    required this.mine,
  });

  final int id;
  final int conversationId;
  final ChatUserSummary sender;
  final String? clientMessageId;
  final String contentType;
  final String content;
  final String status;
  final DateTime? sentAt;
  final bool mine;

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    return MessageItem(
      id: readInt(json['id']),
      conversationId: readInt(json['conversationId']),
      sender: ChatUserSummary.fromJson(
        Map<String, dynamic>.from(json['sender'] as Map? ?? const {}),
      ),
      clientMessageId: readNullableString(json['clientMessageId']),
      contentType: readString(json['contentType'], fallback: 'TEXT'),
      content: readString(json['content']),
      status: readString(json['status'], fallback: 'SENT'),
      sentAt: readDateTime(json['sentAt']),
      mine: readBool(json['mine']),
    );
  }
}

class MessagePage {
  MessagePage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.friendConversation,
    required this.temporaryConversation,
    required this.temporaryMessageLimit,
    required this.temporaryMessageCount,
    required this.temporaryMessageRemaining,
    required this.canSendMessage,
  });

  final List<MessageItem> list;
  final int total;
  final int page;
  final int pageSize;
  final bool friendConversation;
  final bool temporaryConversation;
  final int temporaryMessageLimit;
  final int temporaryMessageCount;
  final int temporaryMessageRemaining;
  final bool canSendMessage;

  factory MessagePage.fromJson(Map<String, dynamic> json) {
    return MessagePage(
      list: readMapList(
        json['list'],
      ).map(MessageItem.fromJson).toList(growable: false),
      total: readInt(json['total']),
      page: readInt(json['page']),
      pageSize: readInt(json['pageSize']),
      friendConversation: readBool(json['friendConversation']),
      temporaryConversation: readBool(json['temporaryConversation']),
      temporaryMessageLimit: readInt(json['temporaryMessageLimit']),
      temporaryMessageCount: readInt(json['temporaryMessageCount']),
      temporaryMessageRemaining: readInt(json['temporaryMessageRemaining']),
      canSendMessage: readBool(json['canSendMessage'], fallback: true),
    );
  }
}

class SearchUserResult {
  SearchUserResult({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.relationStatus,
    required this.canSendFriendRequest,
  });

  final int id;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String relationStatus;
  final bool canSendFriendRequest;

  factory SearchUserResult.fromJson(Map<String, dynamic> json) {
    return SearchUserResult(
      id: readInt(json['id']),
      username: readString(json['username']),
      nickname: readString(json['nickname']),
      avatarUrl: readNullableString(json['avatarUrl']),
      relationStatus: readString(json['relationStatus'], fallback: 'NONE'),
      canSendFriendRequest: readBool(json['canSendFriendRequest']),
    );
  }
}
