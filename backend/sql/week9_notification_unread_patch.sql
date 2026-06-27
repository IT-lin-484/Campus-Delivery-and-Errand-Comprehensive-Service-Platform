-- 第9周补丁：消息中心未读能力增强
-- 目标：
-- 1) 为订单取消申请补充“需求方已读时间/接单方已读时间”
-- 2) 支持顶部消息入口展示未读角标（取消申请 + 处理结果）

SET NAMES utf8mb4;

SET @has_col_order_cancel_requester_read_at := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND column_name = 'requester_read_at'
);
SET @sql_add_col_order_cancel_requester_read_at := IF(
    @has_col_order_cancel_requester_read_at = 0,
    'ALTER TABLE order_cancel_requests ADD COLUMN requester_read_at DATETIME NULL COMMENT ''需求方通知已读时间'' AFTER handled_at',
    'SELECT 1'
);
PREPARE stmt_add_col_order_cancel_requester_read_at FROM @sql_add_col_order_cancel_requester_read_at;
EXECUTE stmt_add_col_order_cancel_requester_read_at;
DEALLOCATE PREPARE stmt_add_col_order_cancel_requester_read_at;

SET @has_col_order_cancel_runner_read_at := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND column_name = 'runner_read_at'
);
SET @sql_add_col_order_cancel_runner_read_at := IF(
    @has_col_order_cancel_runner_read_at = 0,
    'ALTER TABLE order_cancel_requests ADD COLUMN runner_read_at DATETIME NULL COMMENT ''接单方通知已读时间'' AFTER requester_read_at',
    'SELECT 1'
);
PREPARE stmt_add_col_order_cancel_runner_read_at FROM @sql_add_col_order_cancel_runner_read_at;
EXECUTE stmt_add_col_order_cancel_runner_read_at;
DEALLOCATE PREPARE stmt_add_col_order_cancel_runner_read_at;

SET @has_idx_order_cancel_requests_runner_unread := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND index_name = 'idx_order_cancel_requests_runner_unread'
);
SET @sql_add_idx_order_cancel_requests_runner_unread := IF(
    @has_idx_order_cancel_requests_runner_unread = 0,
    'CREATE INDEX idx_order_cancel_requests_runner_unread ON order_cancel_requests(runner_id, status, runner_read_at)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_cancel_requests_runner_unread FROM @sql_add_idx_order_cancel_requests_runner_unread;
EXECUTE stmt_add_idx_order_cancel_requests_runner_unread;
DEALLOCATE PREPARE stmt_add_idx_order_cancel_requests_runner_unread;

SET @has_idx_order_cancel_requests_requester_unread := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND index_name = 'idx_order_cancel_requests_requester_unread'
);
SET @sql_add_idx_order_cancel_requests_requester_unread := IF(
    @has_idx_order_cancel_requests_requester_unread = 0,
    'CREATE INDEX idx_order_cancel_requests_requester_unread ON order_cancel_requests(requester_id, status, requester_read_at)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_cancel_requests_requester_unread FROM @sql_add_idx_order_cancel_requests_requester_unread;
EXECUTE stmt_add_idx_order_cancel_requests_requester_unread;
DEALLOCATE PREPARE stmt_add_idx_order_cancel_requests_requester_unread;
