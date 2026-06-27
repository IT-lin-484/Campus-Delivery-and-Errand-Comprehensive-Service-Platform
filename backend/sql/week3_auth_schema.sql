-- 第3周认证模块补丁（基于已有 users 表）
-- 兼容 MySQL 8.0，不依赖 ADD COLUMN IF NOT EXISTS 语法

SET NAMES utf8mb4;

SET @has_col_username := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'username'
);
SET @sql_add_col_username := IF(
    @has_col_username = 0,
    'ALTER TABLE users ADD COLUMN username VARCHAR(32) NOT NULL COMMENT ''登录用户名（唯一）''',
    'SELECT 1'
);
PREPARE stmt_add_col_username FROM @sql_add_col_username;
EXECUTE stmt_add_col_username;
DEALLOCATE PREPARE stmt_add_col_username;

SET @has_col_password_hash := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'password_hash'
);
SET @sql_add_col_password_hash := IF(
    @has_col_password_hash = 0,
    'ALTER TABLE users ADD COLUMN password_hash VARCHAR(100) NOT NULL COMMENT ''密码哈希（BCrypt）''',
    'SELECT 1'
);
PREPARE stmt_add_col_password_hash FROM @sql_add_col_password_hash;
EXECUTE stmt_add_col_password_hash;
DEALLOCATE PREPARE stmt_add_col_password_hash;

SET @has_col_role := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'role'
);
SET @sql_add_col_role := IF(
    @has_col_role = 0,
    'ALTER TABLE users ADD COLUMN role ENUM(''USER'', ''ADMIN'') NOT NULL DEFAULT ''USER'' COMMENT ''用户角色''',
    'SELECT 1'
);
PREPARE stmt_add_col_role FROM @sql_add_col_role;
EXECUTE stmt_add_col_role;
DEALLOCATE PREPARE stmt_add_col_role;

SET @has_col_status := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'status'
);
SET @sql_add_col_status := IF(
    @has_col_status = 0,
    'ALTER TABLE users ADD COLUMN status ENUM(''ACTIVE'', ''BANNED'') NOT NULL DEFAULT ''ACTIVE'' COMMENT ''账号状态''',
    'SELECT 1'
);
PREPARE stmt_add_col_status FROM @sql_add_col_status;
EXECUTE stmt_add_col_status;
DEALLOCATE PREPARE stmt_add_col_status;

SET @has_uk_users_username := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND index_name = 'uk_users_username'
);
SET @sql_add_uk_users_username := IF(
    @has_uk_users_username = 0,
    'ALTER TABLE users ADD CONSTRAINT uk_users_username UNIQUE (username)',
    'SELECT 1'
);
PREPARE stmt_add_uk_users_username FROM @sql_add_uk_users_username;
EXECUTE stmt_add_uk_users_username;
DEALLOCATE PREPARE stmt_add_uk_users_username;

SET @has_idx_users_username := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND index_name = 'idx_users_username'
);
SET @sql_add_idx_users_username := IF(
    @has_idx_users_username = 0,
    'CREATE INDEX idx_users_username ON users(username)',
    'SELECT 1'
);
PREPARE stmt_add_idx_users_username FROM @sql_add_idx_users_username;
EXECUTE stmt_add_idx_users_username;
DEALLOCATE PREPARE stmt_add_idx_users_username;

ALTER TABLE users COMMENT = '用户表';

