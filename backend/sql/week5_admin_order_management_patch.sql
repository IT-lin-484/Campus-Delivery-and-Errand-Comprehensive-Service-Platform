-- 第5周补丁：管理员订单管理
-- 内容：
-- 1. 为 orders 表补充异常标记字段
-- 2. 新增 admin_audit_log 审计日志表

SET NAMES utf8mb4;

SET @has_col_abnormal_flag := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'orders'
      AND column_name = 'abnormal_flag'
);

SET @sql_add_col_abnormal_flag := IF(
    @has_col_abnormal_flag = 0,
    'ALTER TABLE orders ADD COLUMN abnormal_flag TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否异常标记''',
    'SELECT 1'
);
PREPARE stmt_add_col_abnormal_flag FROM @sql_add_col_abnormal_flag;
EXECUTE stmt_add_col_abnormal_flag;
DEALLOCATE PREPARE stmt_add_col_abnormal_flag;

SET @has_col_abnormal_note := (
    SELECT COUNT(1)
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'orders'
      AND column_name = 'abnormal_note'
);

SET @sql_add_col_abnormal_note := IF(
    @has_col_abnormal_note = 0,
    'ALTER TABLE orders ADD COLUMN abnormal_note VARCHAR(200) NULL COMMENT ''异常说明''',
    'SELECT 1'
);
PREPARE stmt_add_col_abnormal_note FROM @sql_add_col_abnormal_note;
EXECUTE stmt_add_col_abnormal_note;
DEALLOCATE PREPARE stmt_add_col_abnormal_note;

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
