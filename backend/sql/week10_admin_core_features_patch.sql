-- 第10周补丁：管理员核心能力补齐
-- 内容：
-- 1. 新增系统配置表 system_config
-- 2. 新增举报/工单表 admin_reports

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS system_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '配置主键ID',
    cancel_window_runner_minutes INT NOT NULL DEFAULT 5 COMMENT '接单方取消窗口（分钟）',
    cancel_window_requester_minutes INT NOT NULL DEFAULT 5 COMMENT '需求方取消窗口（分钟）',
    expire_grace_minutes INT NOT NULL DEFAULT 30 COMMENT 'OPEN 过期宽限（分钟）',
    max_concurrent_orders INT NOT NULL DEFAULT 2 COMMENT '并行接单上限',
    max_daily_accept INT NOT NULL DEFAULT 10 COMMENT '每日接单上限',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

CREATE TABLE IF NOT EXISTS admin_reports (
    id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '举报/工单ID',
    category VARCHAR(60) NOT NULL COMMENT '举报分类',
    target_type VARCHAR(40) NOT NULL COMMENT '目标类型',
    target_id BIGINT NOT NULL COMMENT '目标ID',
    reporter_id BIGINT NULL COMMENT '举报人ID',
    description TEXT NULL COMMENT '举报说明',
    status ENUM('OPEN', 'RESOLVED', 'REJECTED') NOT NULL DEFAULT 'OPEN' COMMENT '处理状态',
    handled_by BIGINT NULL COMMENT '处理人ID',
    handle_note VARCHAR(200) NULL COMMENT '处理备注',
    handled_at DATETIME NULL COMMENT '处理时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员举报/工单表';

CREATE INDEX idx_admin_reports_status_created ON admin_reports(status, created_at DESC);
CREATE INDEX idx_admin_reports_target ON admin_reports(target_type, target_id);
