-- 第4周结构补丁：在已有 week1/week3 基础上补齐表结构
-- 目标：
-- 1) 若缺失则新增 reviews 表；
-- 2) 若缺失则补 orders 过期扫描索引；
-- 3) 若缺失则补 reviews 索引。

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '评价主键ID',
    order_id BIGINT NOT NULL COMMENT '关联订单ID（一单一评）',
    reviewer_id BIGINT NOT NULL COMMENT '评价人用户ID',
    runner_id BIGINT NOT NULL COMMENT '被评价跑腿员ID',
    rating TINYINT NOT NULL COMMENT '评分（1到5）',
    tags JSON NULL COMMENT '评价标签（JSON）',
    content TEXT NULL COMMENT '评价内容',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    CONSTRAINT uk_reviews_order UNIQUE (order_id),
    CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id),
    CONSTRAINT fk_reviews_runner FOREIGN KEY (runner_id) REFERENCES users(id),
    CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单评价表';

SET @has_idx_orders_status_expected_time := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'orders'
      AND index_name = 'idx_orders_status_expected_time'
);
SET @sql_orders_index := IF(
    @has_idx_orders_status_expected_time = 0,
    'CREATE INDEX idx_orders_status_expected_time ON orders(status, expected_time)',
    'SELECT 1'
);
PREPARE stmt_orders_index FROM @sql_orders_index;
EXECUTE stmt_orders_index;
DEALLOCATE PREPARE stmt_orders_index;

SET @has_fk_orders_requester := (
    SELECT COUNT(1)
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = 'orders'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name = 'fk_orders_requester'
);
SET @sql_fk_orders_requester := IF(
    @has_fk_orders_requester = 0,
    'ALTER TABLE orders ADD CONSTRAINT fk_orders_requester FOREIGN KEY (requester_id) REFERENCES users(id)',
    'SELECT 1'
);
PREPARE stmt_fk_orders_requester FROM @sql_fk_orders_requester;
EXECUTE stmt_fk_orders_requester;
DEALLOCATE PREPARE stmt_fk_orders_requester;

SET @has_fk_orders_runner := (
    SELECT COUNT(1)
    FROM information_schema.table_constraints
    WHERE table_schema = DATABASE()
      AND table_name = 'orders'
      AND constraint_type = 'FOREIGN KEY'
      AND constraint_name = 'fk_orders_runner'
);
SET @sql_fk_orders_runner := IF(
    @has_fk_orders_runner = 0,
    'ALTER TABLE orders ADD CONSTRAINT fk_orders_runner FOREIGN KEY (runner_id) REFERENCES users(id)',
    'SELECT 1'
);
PREPARE stmt_fk_orders_runner FROM @sql_fk_orders_runner;
EXECUTE stmt_fk_orders_runner;
DEALLOCATE PREPARE stmt_fk_orders_runner;

SET @has_idx_reviews_runner_created := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'reviews'
      AND index_name = 'idx_reviews_runner_created'
);
SET @sql_reviews_runner_index := IF(
    @has_idx_reviews_runner_created = 0,
    'CREATE INDEX idx_reviews_runner_created ON reviews(runner_id, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_reviews_runner_index FROM @sql_reviews_runner_index;
EXECUTE stmt_reviews_runner_index;
DEALLOCATE PREPARE stmt_reviews_runner_index;

SET @has_idx_reviews_reviewer_created := (
    SELECT COUNT(1)
    FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name = 'reviews'
      AND index_name = 'idx_reviews_reviewer_created'
);
SET @sql_reviews_reviewer_index := IF(
    @has_idx_reviews_reviewer_created = 0,
    'CREATE INDEX idx_reviews_reviewer_created ON reviews(reviewer_id, created_at DESC)',
    'SELECT 1'
);
PREPARE stmt_reviews_reviewer_index FROM @sql_reviews_reviewer_index;
EXECUTE stmt_reviews_reviewer_index;
DEALLOCATE PREPARE stmt_reviews_reviewer_index;
