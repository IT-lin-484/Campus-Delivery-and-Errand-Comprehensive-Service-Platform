# 登录注册模块设计说明

## 1. 目标范围

本模块只实现以下能力：

1. 用户注册
2. 用户登录
3. 获取当前登录用户信息

不在本次范围内：

1. 找回密码
2. 手机验证码登录
3. 第三方统一认证（SSO）

## 2. 数据库设计

基于 `users` 表实现认证能力，核心字段如下：

| 字段 | 类型 | 约束 | 说明 |
| --- | --- | --- | --- |
| `id` | BIGINT | PK, AUTO_INCREMENT | 用户主键 |
| `username` | VARCHAR(32) | NOT NULL, UNIQUE | 登录账号 |
| `password_hash` | VARCHAR(100) | NOT NULL | BCrypt 密码摘要 |
| `nickname` | VARCHAR(64) | NOT NULL | 昵称 |
| `phone` | VARCHAR(20) | NULL | 手机号（可选） |
| `role` | ENUM('USER','ADMIN') | NOT NULL | 角色 |
| `status` | ENUM('ACTIVE','BANNED') | NOT NULL | 状态 |
| `created_at` | DATETIME | NOT NULL | 创建时间 |
| `updated_at` | DATETIME | NOT NULL | 更新时间 |

索引：

1. `uk_users_username`（唯一索引）
2. `idx_users_username`（普通索引）

脚本位置：

1. 全量建表：`sql/week1_schema.sql`
2. 增量补丁：`sql/week3_auth_schema.sql`

## 3. API 设计

统一前缀：`/api/v1/auth`

1. 注册：`POST /register`
2. 登录：`POST /login`
3. 当前用户：`GET /me`

## 4. 安全策略

1. 密码不落库明文，统一使用 BCrypt 摘要。
2. 登录成功返回 JWT（Bearer Token）。
3. `Authorization` 头格式统一为：`Bearer <token>`。
4. Token 内包含 `sub(userId)`、`username`、`role`。

