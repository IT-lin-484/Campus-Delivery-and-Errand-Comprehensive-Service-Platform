# 第1周+第2周后端交付说明

## 1. 第1周交付（设计与脚手架）
- 技术栈脚手架：Spring Boot 3 + JDK 17 + MySQL
- 核心配置：
  - `src/main/resources/application.properties`
  - CORS（支持 Vue3 本地开发）
  - 测试环境 H2 内存库
- 数据库设计草案：
  - `sql/week1_schema.sql`
- API 基础路径：
  - `/api/v1`

## 2. 第2周交付（发布/列表/详情）
已落地接口：

1. 发布订单  
`POST /api/v1/orders`

2. 订单列表（只读）  
`GET /api/v1/orders?status=OPEN&type=EXPRESS&keyword=驿站&page=1&page_size=20`

3. 订单详情（只读）  
`GET /api/v1/orders/{id}`

## 3. 请求校验规则（已实现）
- `rewardAmount`：1~50
- `remark`：最大 200
- `pickupLocation/dropoffLocation`：必填
- `expectedTime`：不能早于当前时间超过 10 分钟
- `contactMode=PHONE` 时必须填写 `contactValue`

## 4. 关键实现文件
- 订单实体：`src/main/java/com/campusrunner/backend/order/entity/Order.java`
- 枚举定义：`src/main/java/com/campusrunner/backend/order/enums/*`
- 订单接口：`src/main/java/com/campusrunner/backend/order/controller/OrderController.java`
- 订单服务：`src/main/java/com/campusrunner/backend/order/service/OrderService.java`
- 全局异常：`src/main/java/com/campusrunner/backend/common/GlobalExceptionHandler.java`

## 5. 测试状态
- `OrderControllerTests` 已覆盖：
  - 创建订单成功
  - 列表查询成功
  - 详情查询成功
- 执行命令：  
  - `.\mvnw.cmd test`

## 6. 第3周新增（登录注册）
- 新增接口：
  - `POST /api/v1/auth/register`
  - `POST /api/v1/auth/login`
  - `GET /api/v1/auth/me`
- 新增模块：
  - `auth`（控制器/服务/DTO/JWT）
  - `user`（用户实体/仓储/枚举）
- 数据库补充：
  - `users` 表新增 `username`、`password_hash`
  - 参考脚本：`sql/week3_auth_schema.sql`
