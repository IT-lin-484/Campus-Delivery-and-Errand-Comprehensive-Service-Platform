-- 第8周补丁：订单取消规则增强
-- 目标：
-- 1) 接单方开始执行后（IN_PROGRESS），需求方取消需发起申请并由接单方处理
-- 2) 支持取消申请的审核轨迹与每日额度统计

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS order_cancel_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '取消申请主键ID',
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    requester_id BIGINT NOT NULL COMMENT '发起取消申请的需求方ID',
    runner_id BIGINT NOT NULL COMMENT '处理取消申请的接单方ID',
    reason VARCHAR(200) NOT NULL COMMENT '取消申请原因',
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING' COMMENT '取消申请状态',
    handled_by BIGINT NULL COMMENT '处理人ID（通常为接单方）',
    handle_note VARCHAR(200) NULL COMMENT '处理备注',
    handled_at DATETIME NULL COMMENT '处理时间',
    requester_read_at DATETIME NULL COMMENT '需求方通知已读时间',
    runner_read_at DATETIME NULL COMMENT '接单方通知已读时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT fk_order_cancel_requests_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_cancel_requests_requester FOREIGN KEY (requester_id) REFERENCES users(id),
    CONSTRAINT fk_order_cancel_requests_runner FOREIGN KEY (runner_id) REFERENCES users(id),
    CONSTRAINT fk_order_cancel_requests_handled_by FOREIGN KEY (handled_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单取消申请表';

SET @has_idx_order_cancel_requests_order_status := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND index_name = 'idx_order_cancel_requests_order_status'
);
SET @sql_add_idx_order_cancel_requests_order_status := IF(
    @has_idx_order_cancel_requests_order_status = 0,
    'CREATE INDEX idx_order_cancel_requests_order_status ON order_cancel_requests(order_id, status, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_cancel_requests_order_status FROM @sql_add_idx_order_cancel_requests_order_status;
EXECUTE stmt_add_idx_order_cancel_requests_order_status;
DEALLOCATE PREPARE stmt_add_idx_order_cancel_requests_order_status;

SET @has_idx_order_cancel_requests_requester_created := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'order_cancel_requests'
      AND index_name = 'idx_order_cancel_requests_requester_created'
);
SET @sql_add_idx_order_cancel_requests_requester_created := IF(
    @has_idx_order_cancel_requests_requester_created = 0,
    'CREATE INDEX idx_order_cancel_requests_requester_created ON order_cancel_requests(requester_id, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_add_idx_order_cancel_requests_requester_created FROM @sql_add_idx_order_cancel_requests_requester_created;
EXECUTE stmt_add_idx_order_cancel_requests_requester_created;
DEALLOCATE PREPARE stmt_add_idx_order_cancel_requests_requester_created;

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
