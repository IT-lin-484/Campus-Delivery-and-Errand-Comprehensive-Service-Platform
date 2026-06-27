import 'json_utils.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.phone,
    required this.avatarUrl,
    required this.commonAddress,
    required this.bio,
    required this.allowFriendRequest,
    required this.allowSearch,
    required this.messageDnd,
    required this.role,
    required this.status,
  });

  final int id;
  final String username;
  final String nickname;
  final String? phone;
  final String? avatarUrl;
  final String? commonAddress;
  final String? bio;
  final bool allowFriendRequest;
  final bool allowSearch;
  final bool messageDnd;
  final String role;
  final String status;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: readInt(json['id']),
      username: readString(json['username']),
      nickname: readString(json['nickname']),
      phone: readNullableString(json['phone']),
      avatarUrl: readNullableString(json['avatarUrl']),
      commonAddress: readNullableString(json['commonAddress']),
      bio: readNullableString(json['bio']),
      allowFriendRequest: readBool(json['allowFriendRequest'], fallback: true),
      allowSearch: readBool(json['allowSearch'], fallback: true),
      messageDnd: readBool(json['messageDnd']),
      role: readString(json['role']),
      status: readString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'nickname': nickname,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'commonAddress': commonAddress,
      'bio': bio,
      'allowFriendRequest': allowFriendRequest,
      'allowSearch': allowSearch,
      'messageDnd': messageDnd,
      'role': role,
      'status': status,
    };
  }
}

class AuthResult {
  AuthResult({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String token;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: readString(json['token']),
      tokenType: readString(json['tokenType'], fallback: 'Bearer'),
      expiresIn: readInt(json['expiresIn']),
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}

class HealthInfo {
  HealthInfo({
    required this.status,
    required this.service,
    required this.timestamp,
  });

  final String status;
  final String service;
  final DateTime? timestamp;

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      status: readString(json['status']),
      service: readString(json['service']),
      timestamp: readDateTime(json['timestamp']),
    );
  }
}
