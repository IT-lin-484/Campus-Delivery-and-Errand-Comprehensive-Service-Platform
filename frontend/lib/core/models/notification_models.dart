import 'json_utils.dart';

class UnreadNotificationSummary {
  UnreadNotificationSummary({
    required this.totalUnreadCount,
    required this.chatUnreadCount,
    required this.orderCancelUnreadCount,
    required this.requesterActiveOrderCount,
    required this.runnerActiveOrderCount,
    required this.friendRequestUnreadCount,
    required this.myOrderNoticeCount,
    required this.myPageNoticeCount,
  });

  final int totalUnreadCount;
  final int chatUnreadCount;
  final int orderCancelUnreadCount;
  final int requesterActiveOrderCount;
  final int runnerActiveOrderCount;
  final int friendRequestUnreadCount;
  final int myOrderNoticeCount;
  final int myPageNoticeCount;

  factory UnreadNotificationSummary.fromJson(Map<String, dynamic> json) {
    return UnreadNotificationSummary(
      totalUnreadCount: readInt(json['totalUnreadCount']),
      chatUnreadCount: readInt(json['chatUnreadCount']),
      orderCancelUnreadCount: readInt(json['orderCancelUnreadCount']),
      requesterActiveOrderCount: readInt(json['requesterActiveOrderCount']),
      runnerActiveOrderCount: readInt(json['runnerActiveOrderCount']),
      friendRequestUnreadCount: readInt(json['friendRequestUnreadCount']),
      myOrderNoticeCount: readInt(json['myOrderNoticeCount']),
      myPageNoticeCount: readInt(json['myPageNoticeCount']),
    );
  }
}
