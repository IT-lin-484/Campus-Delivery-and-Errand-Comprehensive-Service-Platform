import 'json_utils.dart';

class FriendItem {
  FriendItem({
    required this.userId,
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.bio,
    required this.becameFriendsAt,
  });

  final int userId;
  final String username;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final DateTime? becameFriendsAt;

  factory FriendItem.fromJson(Map<String, dynamic> json) {
    return FriendItem(
      userId: readInt(json['userId']),
      username: readString(json['username']),
      nickname: readString(json['nickname']),
      avatarUrl: readNullableString(json['avatarUrl']),
      bio: readNullableString(json['bio']),
      becameFriendsAt: readDateTime(json['becameFriendsAt']),
    );
  }
}

class FriendRequestItem {
  FriendRequestItem({
    required this.id,
    required this.fromUserId,
    required this.fromNickname,
    required this.fromAvatarUrl,
    required this.toUserId,
    required this.toNickname,
    required this.toAvatarUrl,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int fromUserId;
  final String fromNickname;
  final String? fromAvatarUrl;
  final int toUserId;
  final String toNickname;
  final String? toAvatarUrl;
  final String status;
  final String? message;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendRequestItem(
      id: readInt(json['id']),
      fromUserId: readInt(json['fromUserId']),
      fromNickname: readString(json['fromNickname']),
      fromAvatarUrl: readNullableString(json['fromAvatarUrl']),
      toUserId: readInt(json['toUserId']),
      toNickname: readString(json['toNickname']),
      toAvatarUrl: readNullableString(json['toAvatarUrl']),
      status: readString(json['status']),
      message: readNullableString(json['message']),
      createdAt: readDateTime(json['createdAt']),
      updatedAt: readDateTime(json['updatedAt']),
    );
  }
}

class FriendRequestPage {
  FriendRequestPage({required this.received, required this.sent});

  final List<FriendRequestItem> received;
  final List<FriendRequestItem> sent;

  factory FriendRequestPage.fromJson(Map<String, dynamic> json) {
    return FriendRequestPage(
      received: readMapList(
        json['received'],
      ).map(FriendRequestItem.fromJson).toList(growable: false),
      sent: readMapList(
        json['sent'],
      ).map(FriendRequestItem.fromJson).toList(growable: false),
    );
  }
}
