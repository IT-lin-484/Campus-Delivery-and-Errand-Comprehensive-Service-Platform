# Flutter 接口对接方案

这份文档用于后续把用户端从 Vue 迁移到 Flutter 时，统一前后端接口、鉴权和本地调试方式。

## 基础约定

后端统一前缀为 `/api/v1`；登录态优先使用 `Authorization: Bearer <token>`；当前后端仍兼容 `X-User-Id` 作为回退链路；统一错误结构为 `{ "status": 400, "message": "..." }`；时间格式使用 Jackson 默认 ISO-8601，Flutter 侧可直接用 `DateTime.parse`。

## 本地地址映射

Android 模拟器建议使用 `http://10.0.2.2:8080/api/v1`；iOS 模拟器、Windows、macOS、Linux 桌面端建议使用 `http://localhost:8080/api/v1`；物理手机建议使用 `http://<你的局域网IP>:8080/api/v1`。

建议把地址放进 `--dart-define`，不要写死在代码里：

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

## 推荐网络层

建议 Flutter 使用 `dio`，因为它更适合统一设置 `baseUrl`、做请求和响应拦截、自动注入 Token、统一错误包装、处理文件上传和下载；如果项目想保持更轻量，也可以用 `package:http`，但后续维护成本会更高。

## 请求头建议

必带请求头是 `Content-Type: application/json` 和 `Authorization: Bearer <token>`。

当前后端部分用户端接口仍接受 `X-User-Id`，主要是为了旧前端和迁移期兼容。Flutter 新实现建议先按 Bearer Token 走主链路；如果某些旧页面必须兼容，再短期补 `X-User-Id`；当后端彻底切到纯 JWT 后，再删除这个兼容头。

## 账号与登录

登录接口返回的数据结构包含 `token`、`tokenType`、`expiresIn`、`user`。Flutter 侧建议把 `token` 和 `user` 持久化保存。开发期可以使用 `shared_preferences`，生产期更建议使用 `flutter_secure_storage`。

## 文件上传

后端头像、交付图片等接口会返回相对路径，例如 `/uploads/avatars/...` 和 `/uploads/order-images/...`。Flutter 展示图片时，需要把它拼成完整地址：

```dart
String resolveImageUrl(String path, String baseUrl) {
  if (path.isEmpty) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$baseUrl$path';
}
```

上传建议使用 `multipart/form-data`。

## 前端模块映射

Flutter 端可以按和后端一致的业务模块拆分网络层：`auth`、`order`、`profile`、`social`、`notification`、`report`、`admin`。这种拆分方式和当前 Vue 端的 `frontend/src/api/*` 目录是一致的，迁移时更容易一一对应。

## 页面迁移顺序建议

建议先迁移登录、注册、个人中心，再迁移订单列表、订单详情、发布订单，然后迁移好友、聊天、通知，最后迁移管理员模块。这样可以先保证登录态、接口层和最核心业务链路稳定。

## 后续可直接复用的接口

`POST /auth/login`、`POST /auth/register`、`GET /auth/me`、`GET /orders`、`POST /orders`、`GET /profiles/me`、`GET /friends`、`GET /notifications/unread-summary`。

这些接口和当前 Vue 前端保持同一套路径，Flutter 可以直接沿用。

