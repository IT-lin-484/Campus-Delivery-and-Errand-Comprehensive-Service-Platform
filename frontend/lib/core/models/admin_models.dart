import 'json_utils.dart';

class AdminOverview {
  AdminOverview({
    required this.totalOrders,
    required this.openOrders,
    required this.abnormalOrders,
    required this.pendingReports,
    required this.bannedUsers,
  });

  final int totalOrders;
  final int openOrders;
  final int abnormalOrders;
  final int pendingReports;
  final int bannedUsers;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      totalOrders: readInt(json['totalOrders']),
      openOrders: readInt(json['openOrders']),
      abnormalOrders: readInt(json['abnormalOrders']),
      pendingReports: readInt(json['pendingReports']),
      bannedUsers: readInt(json['bannedUsers']),
    );
  }
}

class AdminUserSummary {
  AdminUserSummary({
    required this.id,
    required this.username,
    required this.nickname,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String username;
  final String? nickname;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final value = nickname?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return username;
  }

  String get phoneText => phone?.trim().isNotEmpty == true ? phone! : '未填写';

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: readInt(json['id']),
      username: readString(json['username']),
      nickname: readNullableString(json['nickname']),
      phone: readNullableString(json['phone']),
      avatarUrl: readNullableString(json['avatarUrl']),
      role: readString(json['role']),
      status: readString(json['status']),
      createdAt: readDateTime(json['createdAt']),
      updatedAt: readDateTime(json['updatedAt']),
    );
  }
}

class AdminUserPage {
  AdminUserPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AdminUserSummary> list;
  final int total;
  final int page;
  final int pageSize;

  factory AdminUserPage.fromJson(Map<String, dynamic> json) {
    return AdminUserPage(
      list: readMapList(
        json['list'],
      ).map(AdminUserSummary.fromJson).toList(growable: false),
      total: readInt(json['total']),
      page: readInt(json['page']),
      pageSize: readInt(json['pageSize']),
    );
  }
}

class AdminOrderSummary {
  AdminOrderSummary({
    required this.id,
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.status,
    required this.requesterId,
    required this.requesterUsername,
    required this.runnerId,
    required this.runnerUsername,
    required this.contactValueMasked,
    required this.abnormalFlag,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? expectedTime;
  final int rewardAmount;
  final String status;
  final int requesterId;
  final String? requesterUsername;
  final int? runnerId;
  final String? runnerUsername;
  final String? contactValueMasked;
  final bool abnormalFlag;
  final DateTime? createdAt;

  String get requesterDisplayName {
    final username = requesterUsername?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return '用户#$requesterId';
  }

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    return AdminOrderSummary(
      id: readInt(json['id']),
      type: readString(json['type']),
      pickupLocation: readString(json['pickupLocation']),
      dropoffLocation: readString(json['dropoffLocation']),
      expectedTime: readDateTime(json['expectedTime']),
      rewardAmount: readInt(json['rewardAmount']),
      status: readString(json['status']),
      requesterId: readInt(json['requesterId']),
      requesterUsername: readNullableString(json['requesterUsername']),
      runnerId: json['runnerId'] == null ? null : readInt(json['runnerId']),
      runnerUsername: readNullableString(json['runnerUsername']),
      contactValueMasked: readNullableString(json['contactValueMasked']),
      abnormalFlag: readBool(json['abnormalFlag']),
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class AdminOrderStatusLog {
  AdminOrderStatusLog({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.operatorId,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final String? fromStatus;
  final String? toStatus;
  final int? operatorId;
  final String? note;
  final DateTime? createdAt;

  factory AdminOrderStatusLog.fromJson(Map<String, dynamic> json) {
    return AdminOrderStatusLog(
      id: readInt(json['id']),
      fromStatus: readNullableString(json['fromStatus']),
      toStatus: readNullableString(json['toStatus']),
      operatorId: json['operatorId'] == null
          ? null
          : readInt(json['operatorId']),
      note: readNullableString(json['note']),
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class AdminOrderDetail {
  AdminOrderDetail({
    required this.id,
    required this.requesterId,
    required this.requesterUsername,
    required this.runnerId,
    required this.runnerUsername,
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.contactMode,
    required this.contactValueMasked,
    required this.remark,
    required this.status,
    required this.cancelledBy,
    required this.cancelReason,
    required this.abnormalFlag,
    required this.abnormalNote,
    required this.createdAt,
    required this.updatedAt,
    required this.statusLogs,
  });

  final int id;
  final int requesterId;
  final String? requesterUsername;
  final int? runnerId;
  final String? runnerUsername;
  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? expectedTime;
  final int rewardAmount;
  final String contactMode;
  final String? contactValueMasked;
  final String? remark;
  final String status;
  final String? cancelledBy;
  final String? cancelReason;
  final bool abnormalFlag;
  final String? abnormalNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AdminOrderStatusLog> statusLogs;

  String get requesterDisplayName {
    final username = requesterUsername?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return '用户#$requesterId';
  }

  String get runnerDisplayName {
    final username = runnerUsername?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    if (runnerId != null) {
      return '用户#$runnerId';
    }
    return '未接单';
  }

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    return AdminOrderDetail(
      id: readInt(json['id']),
      requesterId: readInt(json['requesterId']),
      requesterUsername: readNullableString(json['requesterUsername']),
      runnerId: json['runnerId'] == null ? null : readInt(json['runnerId']),
      runnerUsername: readNullableString(json['runnerUsername']),
      type: readString(json['type']),
      pickupLocation: readString(json['pickupLocation']),
      dropoffLocation: readString(json['dropoffLocation']),
      expectedTime: readDateTime(json['expectedTime']),
      rewardAmount: readInt(json['rewardAmount']),
      contactMode: readString(json['contactMode']),
      contactValueMasked: readNullableString(json['contactValueMasked']),
      remark: readNullableString(json['remark']),
      status: readString(json['status']),
      cancelledBy: readNullableString(json['cancelledBy']),
      cancelReason: readNullableString(json['cancelReason']),
      abnormalFlag: readBool(json['abnormalFlag']),
      abnormalNote: readNullableString(json['abnormalNote']),
      createdAt: readDateTime(json['createdAt']),
      updatedAt: readDateTime(json['updatedAt']),
      statusLogs: readMapList(
        json['statusLogs'],
      ).map(AdminOrderStatusLog.fromJson).toList(growable: false),
    );
  }
}

class AdminOrderPage {
  AdminOrderPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AdminOrderSummary> list;
  final int total;
  final int page;
  final int pageSize;

  factory AdminOrderPage.fromJson(Map<String, dynamic> json) {
    return AdminOrderPage(
      list: readMapList(
        json['list'],
      ).map(AdminOrderSummary.fromJson).toList(growable: false),
      total: readInt(json['total']),
      page: readInt(json['page']),
      pageSize: readInt(json['pageSize']),
    );
  }
}

class AdminReportSummary {
  AdminReportSummary({
    required this.id,
    required this.category,
    required this.targetType,
    required this.targetId,
    required this.reporterId,
    required this.description,
    required this.status,
    required this.handledBy,
    required this.handleNote,
    required this.handledAt,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String targetType;
  final int targetId;
  final int? reporterId;
  final String? description;
  final String status;
  final int? handledBy;
  final String? handleNote;
  final DateTime? handledAt;
  final DateTime? createdAt;

  factory AdminReportSummary.fromJson(Map<String, dynamic> json) {
    return AdminReportSummary(
      id: readInt(json['id']),
      category: readString(json['category']),
      targetType: readString(json['targetType']),
      targetId: readInt(json['targetId']),
      reporterId: json['reporterId'] == null
          ? null
          : readInt(json['reporterId']),
      description: readNullableString(json['description']),
      status: readString(json['status']),
      handledBy: json['handledBy'] == null ? null : readInt(json['handledBy']),
      handleNote: readNullableString(json['handleNote']),
      handledAt: readDateTime(json['handledAt']),
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class AdminReportPage {
  AdminReportPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AdminReportSummary> list;
  final int total;
  final int page;
  final int pageSize;

  factory AdminReportPage.fromJson(Map<String, dynamic> json) {
    return AdminReportPage(
      list: readMapList(
        json['list'],
      ).map(AdminReportSummary.fromJson).toList(growable: false),
      total: readInt(json['total']),
      page: readInt(json['page']),
      pageSize: readInt(json['pageSize']),
    );
  }
}

class AdminConfig {
  AdminConfig({
    required this.id,
    required this.cancelWindowRunnerMinutes,
    required this.cancelWindowRequesterMinutes,
    required this.expireGraceMinutes,
    required this.maxConcurrentOrders,
    required this.maxDailyAccept,
    required this.updatedAt,
  });

  final int id;
  final int cancelWindowRunnerMinutes;
  final int cancelWindowRequesterMinutes;
  final int expireGraceMinutes;
  final int maxConcurrentOrders;
  final int maxDailyAccept;
  final DateTime? updatedAt;

  factory AdminConfig.fromJson(Map<String, dynamic> json) {
    return AdminConfig(
      id: readInt(json['id']),
      cancelWindowRunnerMinutes: readInt(json['cancelWindowRunnerMinutes']),
      cancelWindowRequesterMinutes: readInt(
        json['cancelWindowRequesterMinutes'],
      ),
      expireGraceMinutes: readInt(json['expireGraceMinutes']),
      maxConcurrentOrders: readInt(json['maxConcurrentOrders']),
      maxDailyAccept: readInt(json['maxDailyAccept']),
      updatedAt: readDateTime(json['updatedAt']),
    );
  }
}

String adminUserRoleLabel(String value) {
  switch (value) {
    case 'USER':
      return '普通用户';
    case 'ADMIN':
      return '管理员';
    default:
      return value;
  }
}

String adminUserStatusLabel(String value) {
  switch (value) {
    case 'ACTIVE':
      return '正常';
    case 'BANNED':
      return '已禁用';
    default:
      return value;
  }
}

String adminReportStatusLabel(String value) {
  switch (value) {
    case 'OPEN':
      return '待处理';
    case 'RESOLVED':
      return '已处理';
    case 'REJECTED':
      return '已驳回';
    default:
      return value;
  }
}
