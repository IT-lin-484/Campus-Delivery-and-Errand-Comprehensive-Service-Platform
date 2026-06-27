-- 第6周补丁：个人信息、好友系统、1v1 聊天
-- 说明：
-- 1) 扩展 users 表（个人资料与隐私开关）
-- 2) 新增 friend_requests / friendships
-- 3) 新增 conversations / messages

SET NAMES utf8mb4;

-- =========================
-- 一、扩展 users 表
-- =========================
SET @has_col_common_address := (
    SELECT COUNT(1) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'common_address'
);
SET @sql_add_col_common_address := IF(
    @has_col_common_address = 0,
    'ALTER TABLE users ADD COLUMN common_address VARCHAR(120) NULL COMMENT ''常用地址（宿舍/教学楼）'' AFTER avatar_url',
    'SELECT 1'
);
PREPARE stmt_add_col_common_address FROM @sql_add_col_common_address;
EXECUTE stmt_add_col_common_address;
DEALLOCATE PREPARE stmt_add_col_common_address;

SET @has_col_bio := (
    SELECT COUNT(1) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'bio'
);
SET @sql_add_col_bio := IF(
    @has_col_bio = 0,
    'ALTER TABLE users ADD COLUMN bio VARCHAR(200) NULL COMMENT ''个性签名'' AFTER common_address',
    'SELECT 1'
);
PREPARE stmt_add_col_bio FROM @sql_add_col_bio;
EXECUTE stmt_add_col_bio;
DEALLOCATE PREPARE stmt_add_col_bio;

SET @has_col_allow_friend_request := (
    SELECT COUNT(1) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'allow_friend_request'
);
SET @sql_add_col_allow_friend_request := IF(
    @has_col_allow_friend_request = 0,
    'ALTER TABLE users ADD COLUMN allow_friend_request TINYINT(1) NOT NULL DEFAULT 1 COMMENT ''是否允许好友申请'' AFTER bio',
    'SELECT 1'
);
PREPARE stmt_add_col_allow_friend_request FROM @sql_add_col_allow_friend_request;
EXECUTE stmt_add_col_allow_friend_request;
DEALLOCATE PREPARE stmt_add_col_allow_friend_request;

SET @has_col_allow_search := (
    SELECT COUNT(1) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'allow_search'
);
SET @sql_add_col_allow_search := IF(
    @has_col_allow_search = 0,
    'ALTER TABLE users ADD COLUMN allow_search TINYINT(1) NOT NULL DEFAULT 1 COMMENT ''是否允许被搜索'' AFTER allow_friend_request',
    'SELECT 1'
);
PREPARE stmt_add_col_allow_search FROM @sql_add_col_allow_search;
EXECUTE stmt_add_col_allow_search;
DEALLOCATE PREPARE stmt_add_col_allow_search;

SET @has_col_message_dnd := (
    SELECT COUNT(1) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'users'
      AND column_name = 'message_dnd'
);
SET @sql_add_col_message_dnd := IF(
    @has_col_message_dnd = 0,
    'ALTER TABLE users ADD COLUMN message_dnd TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''消息免打扰'' AFTER allow_search',
    'SELECT 1'
);
PREPARE stmt_add_col_message_dnd FROM @sql_add_col_message_dnd;
EXECUTE stmt_add_col_message_dnd;
DEALLOCATE PREPARE stmt_add_col_message_dnd;

-- =========================
-- 二、好友申请表
-- =========================
CREATE TABLE IF NOT EXISTS friend_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '好友申请主键ID',
    from_user_id BIGINT NOT NULL COMMENT '申请发起人ID',
    to_user_id BIGINT NOT NULL COMMENT '申请接收人ID',
    status ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED') NOT NULL DEFAULT 'PENDING' COMMENT '申请状态',
    message VARCHAR(200) NULL COMMENT '申请附言',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT fk_friend_requests_from_user FOREIGN KEY (from_user_id) REFERENCES users(id),
    CONSTRAINT fk_friend_requests_to_user FOREIGN KEY (to_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友申请表';

CREATE INDEX idx_friend_requests_to_status ON friend_requests(to_user_id, status, created_at DESC);
CREATE INDEX idx_friend_requests_from_status ON friend_requests(from_user_id, status, created_at DESC);

-- =========================
-- 三、好友关系表（双向存储）
-- =========================
CREATE TABLE IF NOT EXISTS friendships (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '好友关系主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    friend_user_id BIGINT NOT NULL COMMENT '好友用户ID',
    status ENUM('ACTIVE', 'BLOCKED') NOT NULL DEFAULT 'ACTIVE' COMMENT '关系状态',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT uk_friendships_pair UNIQUE (user_id, friend_user_id),
    CONSTRAINT fk_friendships_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_friendships_friend_user FOREIGN KEY (friend_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='好友关系表（双向）';

CREATE INDEX idx_friendships_user_status ON friendships(user_id, status, updated_at DESC);
CREATE INDEX idx_friendships_friend ON friendships(friend_user_id);

-- =========================
-- 四、会话表（1v1，每对好友最多1条）
-- =========================
CREATE TABLE IF NOT EXISTS conversations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '会话主键ID',
    user_a_id BIGINT NOT NULL COMMENT '会话参与者A（较小ID）',
    user_b_id BIGINT NOT NULL COMMENT '会话参与者B（较大ID）',
    last_message_id BIGINT NULL COMMENT '最后一条消息ID',
    last_message_preview VARCHAR(255) NULL COMMENT '最后一条消息预览',
    last_message_at DATETIME NULL COMMENT '最后消息时间',
    last_read_message_id_by_a BIGINT NULL COMMENT 'A用户已读到的消息ID',
    last_read_message_id_by_b BIGINT NULL COMMENT 'B用户已读到的消息ID',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT uk_conversations_pair UNIQUE (user_a_id, user_b_id),
    CONSTRAINT fk_conversations_user_a FOREIGN KEY (user_a_id) REFERENCES users(id),
    CONSTRAINT fk_conversations_user_b FOREIGN KEY (user_b_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='1v1聊天会话表';

CREATE INDEX idx_conversations_last_time ON conversations(last_message_at DESC);
CREATE INDEX idx_conversations_user_a ON conversations(user_a_id);
CREATE INDEX idx_conversations_user_b ON conversations(user_b_id);

-- =========================
-- 五、消息表
-- =========================
CREATE TABLE IF NOT EXISTS messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '消息主键ID',
    conversation_id BIGINT NOT NULL COMMENT '所属会话ID',
    sender_id BIGINT NOT NULL COMMENT '发送者用户ID',
    type ENUM('TEXT') NOT NULL DEFAULT 'TEXT' COMMENT '消息类型',
    content VARCHAR(1000) NOT NULL COMMENT '消息内容',
    sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='聊天消息表';

CREATE INDEX idx_messages_conv_id ON messages(conversation_id, id DESC);
CREATE INDEX idx_messages_sender_time ON messages(sender_id, sent_at DESC);
