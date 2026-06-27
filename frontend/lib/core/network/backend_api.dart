import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/admin_models.dart';
import '../models/auth_models.dart';
import '../models/chat_models.dart';
import '../models/friend_models.dart';
import '../models/notification_models.dart';
import '../models/order_models.dart';
import '../storage/session_store.dart';
import 'api_exception.dart';

class BackendApi {
  BackendApi(this._sessionStore)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

  final SessionStore _sessionStore;
  final Dio _dio;

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/login',
      data: <String, dynamic>{'username': username, 'password': password},
      auth: false,
    );
    return AuthResult.fromJson(_requireMap(data));
  }

  Future<AuthResult> adminLogin({
    required String username,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/admin/login',
      data: <String, dynamic>{'username': username, 'password': password},
      auth: false,
    );
    return AuthResult.fromJson(_requireMap(data));
  }

  Future<AuthResult> register({
    required String username,
    required String password,
    String? nickname,
    String? phone,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
      'nickname': nickname,
      'phone': phone,
    };
    final data = await _request(
      'POST',
      '/api/v1/auth/register',
      data: payload,
      auth: false,
    );
    return AuthResult.fromJson(_requireMap(data));
  }

  Future<AuthResult> adminRegister({
    required String username,
    required String password,
    required String nickname,
    required String phone,
    required String inviteCode,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/auth/admin/register',
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'nickname': nickname,
        'phone': phone,
        'inviteCode': inviteCode,
      },
      auth: false,
    );
    return AuthResult.fromJson(_requireMap(data));
  }

  Future<AuthUser> me() async {
    final data = await _request('GET', '/api/v1/auth/me');
    return AuthUser.fromJson(_requireMap(data));
  }

  Future<HealthInfo> health() async {
    final data = await _request('GET', '/api/v1/health', auth: false);
    return HealthInfo.fromJson(_requireMap(data));
  }

  Future<List<ConversationSummary>> fetchConversations() async {
    final data = await _request('GET', '/api/v1/conversations');
    return _requireList(data)
        .map(
          (item) => ConversationSummary.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<ConversationSummary> createPrivateConversation({
    required int friendId,
    int? orderId,
  }) async {
    final payload = <String, dynamic>{'friendId': friendId};
    if (orderId != null) {
      payload['orderId'] = orderId;
    }
    final data = await _request(
      'POST',
      '/api/v1/conversations/private',
      data: payload,
    );
    return ConversationSummary.fromJson(_requireMap(data));
  }

  Future<MessagePage> fetchMessages({
    required int conversationId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/v1/conversations/$conversationId/messages',
      queryParameters: <String, dynamic>{'page': page, 'page_size': pageSize},
    );
    return MessagePage.fromJson(_requireMap(data));
  }

  Future<MessageItem> sendMessage({
    required int conversationId,
    required String content,
    String? clientMessageId,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/conversations/$conversationId/messages',
      data: <String, dynamic>{
        'clientMessageId': clientMessageId,
        'content': content,
      },
    );
    return MessageItem.fromJson(_requireMap(data));
  }

  Future<MessageItem> uploadConversationImage({
    required int conversationId,
    required String filePath,
    String? fileName,
  }) async {
    final data = await _requestMultipart(
      'POST',
      '/api/v1/conversations/$conversationId/images',
      data: FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      }),
    );
    return MessageItem.fromJson(_requireMap(data));
  }

  Future<void> markConversationRead(int conversationId) async {
    await _request('POST', '/api/v1/conversations/$conversationId/read');
  }

  Future<void> deleteConversation(int conversationId) async {
    await _request('DELETE', '/api/v1/conversations/$conversationId');
  }

  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
  }) async {
    await _request(
      'DELETE',
      '/api/v1/conversations/$conversationId/messages/$messageId',
    );
  }

  Future<List<SearchUserResult>> searchUsers({
    required String keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _request(
      'GET',
      '/api/v1/users/search',
      queryParameters: <String, dynamic>{
        'keyword': keyword,
        'page': page,
        'page_size': pageSize,
      },
    );
    return _requireList(data)
        .map(
          (item) =>
              SearchUserResult.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<List<FriendItem>> listFriends() async {
    final data = await _request('GET', '/api/v1/friends');
    return _requireList(data)
        .map(
          (item) => FriendItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }

  Future<FriendRequestPage> listFriendRequests() async {
    final data = await _request('GET', '/api/v1/friends/requests');
    return FriendRequestPage.fromJson(_requireMap(data));
  }

  Future<FriendRequestItem> sendFriendRequest({
    required int toUserId,
    String? message,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/friends/requests',
      data: <String, dynamic>{'toUserId': toUserId, 'message': message},
    );
    return FriendRequestItem.fromJson(_requireMap(data));
  }

  Future<FriendRequestItem> acceptFriendRequest(int requestId) async {
    final data = await _request(
      'POST',
      '/api/v1/friends/requests/$requestId/accept',
    );
    return FriendRequestItem.fromJson(_requireMap(data));
  }

  Future<FriendRequestItem> rejectFriendRequest(int requestId) async {
    final data = await _request(
      'POST',
      '/api/v1/friends/requests/$requestId/reject',
    );
    return FriendRequestItem.fromJson(_requireMap(data));
  }

  Future<FriendRequestItem> cancelFriendRequest(int requestId) async {
    final data = await _request(
      'POST',
      '/api/v1/friends/requests/$requestId/cancel',
    );
    return FriendRequestItem.fromJson(_requireMap(data));
  }

  Future<UnreadNotificationSummary> getUnreadNotificationSummary() async {
    final data = await _request('GET', '/api/v1/notifications/unread-summary');
    return UnreadNotificationSummary.fromJson(_requireMap(data));
  }

  Future<OrderPage> listOrders({
    String? status,
    String? type,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }

    final data = await _request(
      'GET',
      '/api/v1/orders',
      queryParameters: query,
    );
    return OrderPage.fromJson(_requireMap(data));
  }

  Future<OrderDetail> getOrder(int id) async {
    final data = await _request('GET', '/api/v1/orders/$id');
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderDetail> createOrder(CreateOrderRequest request) async {
    final data = await _request(
      'POST',
      '/api/v1/orders',
      data: request.toJson(),
    );
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderPage> listMyOrders({
    required String asRole,
    String? status,
    String? type,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'as': asRole,
      'page': page,
      'page_size': pageSize,
    };
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }

    final data = await _request(
      'GET',
      '/api/v1/me/orders',
      queryParameters: query,
    );
    return OrderPage.fromJson(_requireMap(data));
  }

  Future<OrderDetail> acceptOrder(int id) async {
    final data = await _request('POST', '/api/v1/orders/$id/accept');
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderDetail> updateOrder({
    required int id,
    required UpdateOrderRequest request,
  }) async {
    final data = await _request(
      'PATCH',
      '/api/v1/orders/$id',
      data: request.toJson(),
    );
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderDetail> cancelOrder({required int id, String? reason}) async {
    final data = await _request(
      'POST',
      '/api/v1/orders/$id/cancel',
      data: CancelOrderRequest(reason: reason).toJson(),
    );
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderDetail> updateOrderStatus({
    required int id,
    required UpdateOrderStatusRequest request,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/orders/$id/status',
      data: request.toJson(),
    );
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<OrderDetail> confirmOrder(int id) async {
    final data = await _request('POST', '/api/v1/orders/$id/confirm');
    return OrderDetail.fromJson(_requireMap(data));
  }

  Future<void> updateMyProfile({
    required String username,
    required String nickname,
    String? phone,
    String? commonAddress,
    String? bio,
    required bool allowFriendRequest,
    required bool allowSearch,
    required bool messageDnd,
  }) async {
    await _request(
      'PUT',
      '/api/v1/me/profile',
      data: <String, dynamic>{
        'username': username,
        'nickname': nickname,
        'phone': phone,
        'commonAddress': commonAddress,
        'bio': bio,
        'allowFriendRequest': allowFriendRequest,
        'allowSearch': allowSearch,
        'messageDnd': messageDnd,
      },
    );
  }

  Future<void> uploadMyAvatar({
    required String filePath,
    String? fileName,
  }) async {
    await _requestMultipart(
      'POST',
      '/api/v1/me/profile/avatar',
      data: FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      }),
    );
  }

  Future<void> createOrderReport({
    required int orderId,
    required String category,
    required String description,
  }) async {
    await _request(
      'POST',
      '/api/v1/reports',
      data: <String, dynamic>{
        'category': category,
        'targetType': 'ORDER',
        'targetId': orderId,
        'description': description,
      },
    );
  }

  Future<AdminOverview> adminOverview() async {
    final data = await _request('GET', '/api/v1/admin/overview');
    return AdminOverview.fromJson(_requireMap(data));
  }

  Future<AdminUserPage> adminUsers({
    String? role,
    String? status,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (role != null && role.isNotEmpty) {
      query['role'] = role;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }
    final data = await _request(
      'GET',
      '/api/v1/admin/users',
      queryParameters: query,
    );
    return AdminUserPage.fromJson(_requireMap(data));
  }

  Future<AdminUserSummary> adminUpdateUserStatus({
    required int userId,
    required String status,
    String? note,
  }) async {
    final data = await _request(
      'PATCH',
      '/api/v1/admin/users/$userId/status',
      data: <String, dynamic>{'status': status, 'note': note},
    );
    return AdminUserSummary.fromJson(_requireMap(data));
  }

  Future<AdminOrderPage> adminOrders({
    String? status,
    String? type,
    String? keyword,
    String? startTime,
    String? endTime,
    bool? isAbnormal,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }
    if (startTime != null && startTime.isNotEmpty) {
      query['start_time'] = startTime;
    }
    if (endTime != null && endTime.isNotEmpty) {
      query['end_time'] = endTime;
    }
    if (isAbnormal != null) {
      query['is_abnormal'] = isAbnormal;
    }
    final data = await _request(
      'GET',
      '/api/v1/admin/orders',
      queryParameters: query,
    );
    return AdminOrderPage.fromJson(_requireMap(data));
  }

  Future<AdminOrderDetail> adminOrderDetail(int orderId) async {
    final data = await _request('GET', '/api/v1/admin/orders/$orderId');
    return AdminOrderDetail.fromJson(_requireMap(data));
  }

  Future<void> adminForceCancel({
    required int orderId,
    required String reason,
  }) async {
    await _request(
      'POST',
      '/api/v1/admin/orders/$orderId/force-cancel',
      data: <String, dynamic>{'reason': reason},
    );
  }

  Future<void> adminForceComplete({required int orderId, String? note}) async {
    await _request(
      'POST',
      '/api/v1/admin/orders/$orderId/force-complete',
      data: <String, dynamic>{'note': note},
    );
  }

  Future<void> adminMarkException({
    required int orderId,
    required String note,
  }) async {
    await _request(
      'POST',
      '/api/v1/admin/orders/$orderId/mark-exception',
      data: <String, dynamic>{'note': note},
    );
  }

  Future<AdminReportPage> adminReports({
    String? status,
    String? keyword,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (keyword != null && keyword.isNotEmpty) {
      query['keyword'] = keyword;
    }
    final data = await _request(
      'GET',
      '/api/v1/admin/reports',
      queryParameters: query,
    );
    return AdminReportPage.fromJson(_requireMap(data));
  }

  Future<AdminReportSummary> adminHandleReport({
    required int reportId,
    required String status,
    String? handleNote,
  }) async {
    final data = await _request(
      'POST',
      '/api/v1/admin/reports/$reportId/handle',
      data: <String, dynamic>{'status': status, 'handleNote': handleNote},
    );
    return AdminReportSummary.fromJson(_requireMap(data));
  }

  Future<AdminConfig> adminConfig() async {
    final data = await _request('GET', '/api/v1/admin/config');
    return AdminConfig.fromJson(_requireMap(data));
  }

  Future<AdminConfig> adminUpdateConfig({
    required int cancelWindowRunnerMinutes,
    required int cancelWindowRequesterMinutes,
    required int expireGraceMinutes,
    required int maxConcurrentOrders,
    required int maxDailyAccept,
  }) async {
    final data = await _request(
      'PUT',
      '/api/v1/admin/config',
      data: <String, dynamic>{
        'cancelWindowRunnerMinutes': cancelWindowRunnerMinutes,
        'cancelWindowRequesterMinutes': cancelWindowRequesterMinutes,
        'expireGraceMinutes': expireGraceMinutes,
        'maxConcurrentOrders': maxConcurrentOrders,
        'maxDailyAccept': maxDailyAccept,
      },
    );
    return AdminConfig.fromJson(_requireMap(data));
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: await _headers(auth: auth),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        _extractMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<dynamic> _requestMultipart(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: await _headers(auth: auth),
          contentType: Headers.multipartFormDataContentType,
          responseType: ResponseType.json,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw ApiException(
        _extractMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      Headers.acceptHeader: Headers.jsonContentType,
    };
    if (!auth) {
      return headers;
    }
    final session = await _sessionStore.read();
    final token = session.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _requireMap(dynamic data) {
    final payload = _unwrapPayload(data);
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw const ApiException('服务器返回的数据格式不正确');
  }

  List<dynamic> _requireList(dynamic data) {
    final payload = _unwrapPayload(data);
    if (payload is List) {
      return payload;
    }
    throw const ApiException('服务器返回的数据格式不正确');
  }

  dynamic _unwrapPayload(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final looksWrapped =
          map.containsKey('data') &&
          (map.containsKey('code') ||
              map.containsKey('message') ||
              map.containsKey('status'));
      if (looksWrapped) {
        return map['data'];
      }
      return map;
    }
    return data;
  }

  String _extractMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      for (final key in const ['message', 'detail', 'error', 'title']) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接后端超时，请检查模拟器网络';
      case DioExceptionType.sendTimeout:
        return '请求发送超时';
      case DioExceptionType.receiveTimeout:
        return '响应接收超时';
      case DioExceptionType.badCertificate:
        return '证书校验失败';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '无法连接到后端，请确认服务已启动';
      case DioExceptionType.badResponse:
        return '服务端请求失败';
      case DioExceptionType.unknown:
        return '网络请求失败';
    }
  }
}
