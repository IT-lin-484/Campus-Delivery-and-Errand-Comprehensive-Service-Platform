# Campus Delivery and Errand Comprehensive Service Platform

校园取送综合服务平台，面向校园场景中的代取快递、代买餐食、代送物品和即时沟通需求，提供普通用户端与管理员端两套完整能力。

本项目已经完成前后端分离重构：

- 后端使用 Spring Boot 3 + Maven + MyBatis-Plus + MySQL
- 前端使用 Flutter，默认中文界面，适合 Android 模拟器演示
- 聊天模块使用 Spring WebSocket 实现实时通信
- 项目同时支持普通用户业务流和管理员监管流

## 1. 项目目标

相比单纯的页面展示项目，本系统更强调完整业务闭环：

- 普通用户可以注册、登录、发布订单、浏览订单、接单、确认完成
- 用户之间支持接单前咨询、接单后沟通、图片消息、临时聊天和好友聊天
- 管理员可以管理用户、订单、举报和系统配置
- 所有关键业务数据均真实落库到 MySQL，而不是停留在内存态

## 2. 核心功能

### 2.1 普通用户端

- 用户注册、登录、退出登录
- 个人资料修改、头像上传、用户名与手机号修改
- 订单大厅分页浏览、关键词搜索、分类筛选
- 发布订单、修改订单、取消订单、接单、确认完成
- 我的订单列表，区分发单与接单视角
- 实时聊天、图片消息、未读提醒、好友关系管理
- 临时聊天限制与好友升级机制

### 2.2 管理员端

- 管理员登录
- 概览页查看平台关键数据
- 用户搜索、分页、查看详情、禁用与恢复
- 订单搜索、分页、分类筛选、状态筛选
- 订单详情中的强制取消、强制完成、标记异常
- 举报处理与后台审计
- 系统配置维护

## 3. 技术栈

### 后端

- Java 17
- Spring Boot 3
- Maven Wrapper
- MyBatis-Plus
- MySQL
- Lombok
- JWT
- Spring WebSocket

### 前端

- Flutter
- Dio
- shared_preferences
- web_socket_channel

## 4. 项目结构

```text
Campus Runner Board/
├── backend/                 # Spring Boot 后端
│   ├── src/main/java/com/campusrunner/backend/
│   │   ├── admin
│   │   ├── auth
│   │   ├── common
│   │   ├── config
│   │   ├── conversation
│   │   ├── notification
│   │   ├── order
│   │   ├── profile
│   │   ├── report
│   │   ├── social
│   │   ├── user
│   │   └── websocket
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   ├── mapper/
│   │   └── schema.sql
│   └── pom.xml
├── frontend/                # Flutter 前端
│   ├── lib/
│   │   ├── core
│   │   ├── pages
│   │   ├── state
│   │   └── app.dart
│   └── pubspec.yaml
└── README.md
```

## 5. 后端分层规范

后端已经按 Maven 工程和业务模块进行规范拆分。每个业务模块内部统一采用：

- `controller`：接收请求，返回响应
- `service`：业务接口
- `service/impl`：业务实现
- `dao`：数据访问接口
- `entity`：实体类
- `dto`：请求与响应对象

数据库访问遵循以下规则：

- 简单 CRUD 优先使用 MyBatis-Plus 自带能力
- 复杂 SQL 与并发控制逻辑写入 `resources/mapper/**.xml`
- 命名统一使用 `dao`，避免旧版 JPA / repository 风格混用

## 6. 数据库设计

当前系统围绕以下核心表设计：

- `users`
- `orders`
- `order_cancel_requests`
- `order_delivery_images`
- `order_status_logs`
- `friend_requests`
- `friendships`
- `conversations`
- `messages`
- `admin_reports`
- `admin_audit_log`
- `system_config`

其中：

- `orders` 负责订单主流程
- `conversations` 和 `messages` 负责聊天快照与消息持久化
- `friend_requests` 和 `friendships` 负责好友关系
- `admin_reports` 和 `admin_audit_log` 负责后台监管

## 7. 实时通信设计

聊天模块已经重构为 Spring WebSocket 方案，主要特点包括：

- 登录后根据 JWT 建立 WebSocket 连接
- 前端定时心跳，后端定时清理超时连接
- 消息先持久化，再更新会话快照和未读数
- 支持文字消息与图片消息
- 接单前支持基于订单发起咨询聊天
- 非好友会话默认为临时聊天，达到上限后提示添加好友

## 8. 本地运行方式

### 8.1 启动后端

先准备本地 MySQL 数据库：

- 数据库名：`campus_runner_board`

建议通过环境变量提供数据库配置，不要把本地密码直接写入配置文件：

```powershell
$env:SPRING_DATASOURCE_URL = 'jdbc:mysql://127.0.0.1:3306/campus_runner_board?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true'
$env:SPRING_DATASOURCE_USERNAME = 'root'
$env:SPRING_DATASOURCE_PASSWORD = '你的本地数据库密码'
$env:JWT_SECRET = 'please-change-this-in-your-own-environment'
```

启动命令：

```powershell
cd backend
.\mvnw.cmd test
.\mvnw.cmd spring-boot:run
```

默认启动端口：

- `http://127.0.0.1:8080`

### 8.2 启动前端

在 Android 模拟器环境下，Flutter 建议使用 `10.0.2.2` 访问本机后端：

```powershell
cd frontend
flutter pub get
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

## 9. 接口与联调说明

- 后端 API 前缀统一为 `/api/v1`
- 登录后通过 `Authorization: Bearer <token>` 进行鉴权
- WebSocket 握手通过 token 建立身份
- 数据库初始化脚本位于 `backend/src/main/resources/schema.sql`
- Flutter 对接说明位于 `backend/docs/flutter_api_contract.md`

## 10. 项目亮点

- 完成了前后端真实联调，而不是只做静态页面
- 后端已从旧式混合风格重构为标准 Maven 分层结构
- 数据访问统一切换到 MyBatis-Plus + XML
- 聊天模块重构为 Spring WebSocket 实时通信
- 用户端与管理员端同时可演示，适合课程设计答辩
- 普通用户业务流与后台监管流形成完整闭环

## 11. 后续可继续优化

- 接入对象存储，替代本地图片文件
- 增加评价体系和信誉体系
- 增加推送通知与统计报表
- 增强订单推荐与异常工单处理能力

## 12. 说明

- 本仓库提交的是前后端项目源码
- 本地构建产物、上传文件、IDE 配置和答辩材料不会纳入版本管理
- 如需查看各子项目说明，可进一步阅读：
  - `backend/README.md`
  - `frontend/README.md`
