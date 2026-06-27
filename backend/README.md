# Campus Runner Board Backend

校园取送系统后端工程，使用 Spring Boot 3、Java 17、Maven 和 MyBatis-Plus 构建。

## 技术栈

- Spring Boot 3.3.x
- Java 17
- Maven Wrapper
- MyBatis-Plus
- JWT
- Bean Validation
- Lombok
- 默认数据源为本地 MySQL `campus_runner_board`

## 项目结构

`src/main/java/com/campusrunner/backend` 按业务模块拆分为：

- `admin`
- `auth`
- `common`
- `config`
- `conversation`
- `notification`
- `order`
- `profile`
- `report`
- `social`
- `user`

每个模块都遵循统一分层：

- `controller`：接收请求，返回响应
- `service`：业务接口
- `service/impl`：业务实现
- `dao`：数据访问接口
- `entity`：实体类
- `dto`：请求和响应对象

## 启动前准备

1. 本机需要先启动 MySQL 服务，并确保存在 `campus_runner_board` 数据库。
2. 如果要切换到其他数据库，可以通过环境变量覆盖 `src/main/resources/application.properties` 中的默认值：
   - `SPRING_DATASOURCE_URL`
   - `SPRING_DATASOURCE_USERNAME`
   - `SPRING_DATASOURCE_PASSWORD`
   - `SPRING_DATASOURCE_DRIVER_CLASS_NAME`
3. 启动时仍会执行 `src/main/resources/schema.sql` 来初始化表结构，如果表已存在则不会重复创建。

## 快速启动

```powershell
cd backend
.\mvnw.cmd test
.\mvnw.cmd spring-boot:run
```

## 接口约定

- 所有接口统一以 `/api/v1` 开头。
- 登录后使用 `Authorization: Bearer <token>`。
- 管理员注册邀请码固定为 `9527`。

## Flutter 对接

Flutter 端的接口约定与实时通信说明见 `docs/flutter_api_contract.md`。
