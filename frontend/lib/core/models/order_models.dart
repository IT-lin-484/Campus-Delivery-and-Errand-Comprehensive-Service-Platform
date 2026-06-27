import 'json_utils.dart';

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.requesterId,
    required this.requesterUsername,
    required this.requesterNickname,
    required this.requesterAvatarUrl,
    required this.runnerId,
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int requesterId;
  final String? requesterUsername;
  final String? requesterNickname;
  final String? requesterAvatarUrl;
  final int? runnerId;
  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? expectedTime;
  final int rewardAmount;
  final String status;
  final DateTime? createdAt;

  String get requesterDisplayName {
    final nickname = requesterNickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    final username = requesterUsername?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return '匿名用户';
  }

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: readInt(json['id']),
      requesterId: readInt(json['requesterId']),
      requesterUsername: readNullableString(json['requesterUsername']),
      requesterNickname: readNullableString(json['requesterNickname']),
      requesterAvatarUrl: readNullableString(json['requesterAvatarUrl']),
      runnerId: json['runnerId'] == null ? null : readInt(json['runnerId']),
      type: readString(json['type']),
      pickupLocation: readString(json['pickupLocation']),
      dropoffLocation: readString(json['dropoffLocation']),
      expectedTime: readDateTime(json['expectedTime']),
      rewardAmount: readInt(json['rewardAmount']),
      status: readString(json['status']),
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class OrderDeliveryImage {
  OrderDeliveryImage({
    required this.id,
    required this.orderId,
    required this.uploaderId,
    required this.imageUrl,
    required this.note,
    required this.createdAt,
  });

  final int id;
  final int orderId;
  final int uploaderId;
  final String imageUrl;
  final String? note;
  final DateTime? createdAt;

  factory OrderDeliveryImage.fromJson(Map<String, dynamic> json) {
    return OrderDeliveryImage(
      id: readInt(json['id']),
      orderId: readInt(json['orderId']),
      uploaderId: readInt(json['uploaderId']),
      imageUrl: readString(json['imageUrl']),
      note: readNullableString(json['note']),
      createdAt: readDateTime(json['createdAt']),
    );
  }
}

class OrderCancelRequest {
  OrderCancelRequest({
    required this.id,
    required this.orderId,
    required this.requesterId,
    required this.runnerId,
    required this.reason,
    required this.status,
    required this.handledBy,
    required this.handleNote,
    required this.handledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int orderId;
  final int requesterId;
  final int runnerId;
  final String reason;
  final String status;
  final int? handledBy;
  final String? handleNote;
  final DateTime? handledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory OrderCancelRequest.fromJson(Map<String, dynamic> json) {
    return OrderCancelRequest(
      id: readInt(json['id']),
      orderId: readInt(json['orderId']),
      requesterId: readInt(json['requesterId']),
      runnerId: readInt(json['runnerId']),
      reason: readString(json['reason']),
      status: readString(json['status']),
      handledBy: json['handledBy'] == null ? null : readInt(json['handledBy']),
      handleNote: readNullableString(json['handleNote']),
      handledAt: readDateTime(json['handledAt']),
      createdAt: readDateTime(json['createdAt']),
      updatedAt: readDateTime(json['updatedAt']),
    );
  }
}

class OrderDetail {
  OrderDetail({
    required this.id,
    required this.requesterId,
    required this.requesterUsername,
    required this.requesterNickname,
    required this.requesterAvatarUrl,
    required this.runnerId,
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.contactMode,
    required this.contactValue,
    required this.remark,
    required this.status,
    required this.cancelledBy,
    required this.cancelReason,
    required this.cancelRequest,
    required this.deliveryImages,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int requesterId;
  final String? requesterUsername;
  final String? requesterNickname;
  final String? requesterAvatarUrl;
  final int? runnerId;
  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? expectedTime;
  final int rewardAmount;
  final String contactMode;
  final String? contactValue;
  final String? remark;
  final String status;
  final String? cancelledBy;
  final String? cancelReason;
  final OrderCancelRequest? cancelRequest;
  final List<OrderDeliveryImage> deliveryImages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get requesterDisplayName {
    final nickname = requesterNickname?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    final username = requesterUsername?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return '匿名用户';
  }

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: readInt(json['id']),
      requesterId: readInt(json['requesterId']),
      requesterUsername: readNullableString(json['requesterUsername']),
      requesterNickname: readNullableString(json['requesterNickname']),
      requesterAvatarUrl: readNullableString(json['requesterAvatarUrl']),
      runnerId: json['runnerId'] == null ? null : readInt(json['runnerId']),
      type: readString(json['type']),
      pickupLocation: readString(json['pickupLocation']),
      dropoffLocation: readString(json['dropoffLocation']),
      expectedTime: readDateTime(json['expectedTime']),
      rewardAmount: readInt(json['rewardAmount']),
      contactMode: readString(json['contactMode']),
      contactValue: readNullableString(json['contactValue']),
      remark: readNullableString(json['remark']),
      status: readString(json['status']),
      cancelledBy: readNullableString(json['cancelledBy']),
      cancelReason: readNullableString(json['cancelReason']),
      cancelRequest: json['cancelRequest'] is Map
          ? OrderCancelRequest.fromJson(
              Map<String, dynamic>.from(json['cancelRequest'] as Map),
            )
          : null,
      deliveryImages: readMapList(
        json['deliveryImages'],
      ).map(OrderDeliveryImage.fromJson).toList(growable: false),
      createdAt: readDateTime(json['createdAt']),
      updatedAt: readDateTime(json['updatedAt']),
    );
  }
}

class OrderPage {
  OrderPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<OrderSummary> list;
  final int total;
  final int page;
  final int pageSize;

  factory OrderPage.fromJson(Map<String, dynamic> json) {
    return OrderPage(
      list: readMapList(
        json['list'],
      ).map(OrderSummary.fromJson).toList(growable: false),
      total: readInt(json['total']),
      page: readInt(json['page']),
      pageSize: readInt(json['pageSize']),
    );
  }
}

class CreateOrderRequest {
  CreateOrderRequest({
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.contactMode,
    required this.contactValue,
    required this.remark,
  });

  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime expectedTime;
  final int rewardAmount;
  final String contactMode;
  final String? contactValue;
  final String? remark;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'expectedTime': formatLocalDateTime(expectedTime),
      'rewardAmount': rewardAmount,
      'contactMode': contactMode,
      'contactValue': contactValue,
      'remark': remark,
    };
  }
}

class UpdateOrderRequest {
  UpdateOrderRequest({
    required this.type,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.expectedTime,
    required this.rewardAmount,
    required this.contactMode,
    required this.contactValue,
    required this.remark,
  });

  final String type;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime expectedTime;
  final int rewardAmount;
  final String contactMode;
  final String? contactValue;
  final String? remark;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'expectedTime': formatLocalDateTime(expectedTime),
      'rewardAmount': rewardAmount,
      'contactMode': contactMode,
      'contactValue': contactValue,
      'remark': remark,
    };
  }
}

class CancelOrderRequest {
  CancelOrderRequest({this.reason});

  final String? reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'reason': reason};
  }
}

class UpdateOrderStatusRequest {
  UpdateOrderStatusRequest({required this.toStatus, this.note});

  final String toStatus;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'toStatus': toStatus, 'note': note};
  }
}

String orderTypeLabel(String value) {
  switch (value) {
    case 'EXPRESS':
      return '快递';
    case 'FOOD':
      return '餐食';
    case 'DELIVERY':
      return '代取送';
    default:
      return value;
  }
}

String orderStatusLabel(String value) {
  switch (value) {
    case 'OPEN':
      return '待接单';
    case 'ACCEPTED':
      return '已接单';
    case 'IN_PROGRESS':
      return '配送中';
    case 'DELIVERED':
      return '已送达';
    case 'COMPLETED':
      return '已完成';
    case 'CANCELLED':
      return '已取消';
    case 'EXPIRED':
      return '已过期';
    default:
      return value;
  }
}

String contactModeLabel(String value) {
  switch (value) {
    case 'IN_APP':
      return '站内联系';
    case 'PHONE':
      return '电话联系';
    default:
      return value;
  }
}
