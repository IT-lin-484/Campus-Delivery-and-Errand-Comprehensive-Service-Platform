-- 校园代取代送信息板（第1周）全量初始化脚本
-- 数据库：MySQL 8.0+

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '用户主键ID',
    username VARCHAR(32) NOT NULL COMMENT '登录用户名（唯一）',
    password_hash VARCHAR(100) NOT NULL COMMENT '密码哈希（BCrypt）',
    nickname VARCHAR(64) NOT NULL COMMENT '用户昵称',
    phone VARCHAR(20) NULL COMMENT '手机号（可选）',
    avatar_url VARCHAR(255) NULL COMMENT '头像URL（可选）',
    role ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER' COMMENT '用户角色',
    status ENUM('ACTIVE', 'BANNED') NOT NULL DEFAULT 'ACTIVE' COMMENT '账号状态',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY uk_users_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_status ON users(status);

CREATE TABLE IF NOT EXISTS orders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '订单主键ID',
    requester_id BIGINT NOT NULL COMMENT '需求方用户ID',
    runner_id BIGINT NULL COMMENT '接单方用户ID',
    type ENUM('EXPRESS', 'FOOD', 'DELIVERY') NOT NULL COMMENT '订单类型',
    pickup_location VARCHAR(120) NOT NULL COMMENT '取货点',
    dropoff_location VARCHAR(120) NOT NULL COMMENT '送达点',
    expected_time DATETIME NOT NULL COMMENT '期望完成时间',
    reward_amount INT NOT NULL COMMENT '报酬金额（元）',
    contact_mode ENUM('IN_APP', 'PHONE') NOT NULL COMMENT '联系方式类型',
    contact_value VARCHAR(64) NULL COMMENT '联系方式值',
    remark VARCHAR(200) NULL COMMENT '备注信息',
    status ENUM('OPEN', 'ACCEPTED', 'IN_PROGRESS', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'EXPIRED') NOT NULL COMMENT '订单状态',
    cancelled_by ENUM('REQUESTER', 'RUNNER', 'ADMIN') NULL COMMENT '取消操作方',
    cancel_reason VARCHAR(200) NULL COMMENT '取消原因',
    abnormal_flag TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否异常标记',
    abnormal_note VARCHAR(200) NULL COMMENT '异常说明',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT fk_orders_requester FOREIGN KEY (requester_id) REFERENCES users(id),
    CONSTRAINT fk_orders_runner FOREIGN KEY (runner_id) REFERENCES users(id),
    CONSTRAINT ck_orders_reward_range CHECK (reward_amount BETWEEN 1 AND 50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单主表';

CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC);
CREATE INDEX idx_orders_requester ON orders(requester_id, created_at DESC);
CREATE INDEX idx_orders_runner ON orders(runner_id, created_at DESC);
CREATE INDEX idx_orders_status_expected_time ON orders(status, expected_time);

CREATE TABLE IF NOT EXISTS order_status_logs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '状态日志主键ID',
    order_id BIGINT NOT NULL COMMENT '关联订单ID',
    from_status ENUM('OPEN', 'ACCEPTED', 'IN_PROGRESS', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'EXPIRED') NULL COMMENT '变更前状态',
    to_status ENUM('OPEN', 'ACCEPTED', 'IN_PROGRESS', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'EXPIRED') NOT NULL COMMENT '变更后状态',
    operator_id BIGINT NOT NULL COMMENT '操作人用户ID',
    note VARCHAR(255) NULL COMMENT '状态变更备注',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    CONSTRAINT fk_logs_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_logs_operator FOREIGN KEY (operator_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单状态流转日志表';

CREATE INDEX idx_logs_order_created ON order_status_logs(order_id, created_at DESC);
CREATE INDEX idx_logs_operator_created ON order_status_logs(operator_id, created_at DESC);

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

CREATE INDEX idx_reviews_runner_created ON reviews(runner_id, created_at DESC);
CREATE INDEX idx_reviews_reviewer_created ON reviews(reviewer_id, created_at DESC);

CREATE TABLE IF NOT EXISTS runner_stats (
    runner_id BIGINT PRIMARY KEY COMMENT '跑腿员用户ID',
    active_orders_count INT NOT NULL DEFAULT 0 COMMENT '当前进行中订单数',
    daily_accept_count INT NOT NULL DEFAULT 0 COMMENT '当日接单数',
    daily_date DATE NOT NULL COMMENT '统计日期',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    CONSTRAINT fk_runner_stats_runner FOREIGN KEY (runner_id) REFERENCES users(id),
    CONSTRAINT ck_runner_stats_active_non_negative CHECK (active_orders_count >= 0),
    CONSTRAINT ck_runner_stats_daily_non_negative CHECK (daily_accept_count >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='跑腿员统计表';

CREATE INDEX idx_runner_stats_daily_date ON runner_stats(daily_date);

CREATE TABLE IF NOT EXISTS admin_audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '审计日志主键ID',
    operator_id BIGINT NOT NULL COMMENT '管理员ID',
    action VARCHAR(60) NOT NULL COMMENT '操作动作',
    target_type VARCHAR(40) NOT NULL COMMENT '目标类型',
    target_id BIGINT NOT NULL COMMENT '目标ID',
    before_data TEXT NULL COMMENT '变更前数据快照',
    after_data TEXT NULL COMMENT '变更后数据快照',
    `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    ip VARCHAR(64) NULL COMMENT '操作IP',
    device_id VARCHAR(100) NULL COMMENT '设备标识',
    note VARCHAR(255) NULL COMMENT '备注',
    CONSTRAINT fk_admin_audit_operator FOREIGN KEY (operator_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员审计日志表';

CREATE INDEX idx_admin_audit_operator_time ON admin_audit_log(operator_id, `timestamp` DESC);
CREATE INDEX idx_admin_audit_target ON admin_audit_log(target_type, target_id);
