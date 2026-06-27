-- 第7周补丁：订单完整流转 + 交付图片 + 聊天图片消息
-- 变更内容：
-- 1) 新增 order_delivery_images（订单交付凭证图片）
-- 2) 扩展 messages.type 支持 IMAGE（聊天图片）

SET NAMES utf8mb4;

-- =========================
-- 一、订单交付图片表
-- =========================
CREATE TABLE IF NOT EXISTS order_delivery_images (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '交付图片主键ID',
    order_id BIGINT NOT NULL COMMENT '所属订单ID',
    uploader_id BIGINT NOT NULL COMMENT '上传用户ID（通常为接单方）',
    image_url VARCHAR(255) NOT NULL COMMENT '图片访问地址',
    note VARCHAR(200) NULL COMMENT '图片说明/备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    CONSTRAINT fk_order_delivery_images_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_delivery_images_uploader FOREIGN KEY (uploader_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单交付图片表';

SET @has_idx_order_delivery_images_order_created := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_delivery_images'
      AND index_name = 'idx_order_delivery_images_order_created'
);
SET @sql_add_idx_order_delivery_images_order_created := IF(
    @has_idx_order_delivery_images_order_created = 0,
    'CREATE INDEX idx_order_delivery_images_order_created ON order_delivery_images(order_id, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_delivery_images_order_created FROM @sql_add_idx_order_delivery_images_order_created;
EXECUTE stmt_add_idx_order_delivery_images_order_created;
DEALLOCATE PREPARE stmt_add_idx_order_delivery_images_order_created;

SET @has_idx_order_delivery_images_uploader_created := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_delivery_images'
      AND index_name = 'idx_order_delivery_images_uploader_created'
);
SET @sql_add_idx_order_delivery_images_uploader_created := IF(
    @has_idx_order_delivery_images_uploader_created = 0,
    'CREATE INDEX idx_order_delivery_images_uploader_created ON order_delivery_images(uploader_id, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_delivery_images_uploader_created FROM @sql_add_idx_order_delivery_images_uploader_created;
EXECUTE stmt_add_idx_order_delivery_images_uploader_created;
DEALLOCATE PREPARE stmt_add_idx_order_delivery_images_uploader_created;

-- =========================
-- 二、扩展聊天消息类型
-- =========================
SET @has_messages_table := (
    SELECT COUNT(1)
    FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = 'messages'
);

SET @messages_type_column := (
    SELECT column_type
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'messages'
      AND column_name = 'type'
    LIMIT 1
);

SET @sql_alter_messages_type := IF(
    @has_messages_table = 1 AND @messages_type_column IS NOT NULL AND @messages_type_column NOT LIKE '%''IMAGE''%',
    'ALTER TABLE messages MODIFY COLUMN type ENUM(''TEXT'', ''IMAGE'') NOT NULL DEFAULT ''TEXT'' COMMENT ''消息类型''',
    'SELECT 1'
);
PREPARE stmt_alter_messages_type FROM @sql_alter_messages_type;
EXECUTE stmt_alter_messages_type;
DEALLOCATE PREPARE stmt_alter_messages_type;
