CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(32) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    nickname VARCHAR(64) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(255),
    common_address VARCHAR(120),
    bio VARCHAR(200),
    allow_friend_request BOOLEAN NOT NULL,
    allow_search BOOLEAN NOT NULL,
    message_dnd BOOLEAN NOT NULL,
    role VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY uk_users_username (username),
    KEY idx_users_username (username)
);

CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    requester_id BIGINT NOT NULL,
    runner_id BIGINT,
    type VARCHAR(20) NOT NULL,
    pickup_location VARCHAR(120) NOT NULL,
    dropoff_location VARCHAR(120) NOT NULL,
    expected_time DATETIME NOT NULL,
    reward_amount INT NOT NULL,
    contact_mode VARCHAR(20) NOT NULL,
    contact_value VARCHAR(64),
    remark VARCHAR(200),
    status VARCHAR(20) NOT NULL,
    cancelled_by VARCHAR(20),
    cancel_reason VARCHAR(200),
    abnormal_flag BOOLEAN NOT NULL,
    abnormal_note VARCHAR(200),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    KEY idx_orders_status_created (status, created_at),
    KEY idx_orders_requester (requester_id, created_at),
    KEY idx_orders_runner (runner_id, created_at)
);

CREATE TABLE IF NOT EXISTS order_cancel_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    requester_id BIGINT NOT NULL,
    runner_id BIGINT NOT NULL,
    reason VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL,
    handled_by BIGINT,
    handle_note VARCHAR(200),
    handled_at DATETIME,
    requester_read_at DATETIME,
    runner_read_at DATETIME,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    KEY idx_order_cancel_requests_order_status (order_id, status, created_at),
    KEY idx_order_cancel_requests_requester_created (requester_id, created_at),
    KEY idx_order_cancel_requests_runner_unread (runner_id, status, runner_read_at),
    KEY idx_order_cancel_requests_requester_unread (requester_id, status, requester_read_at)
);

CREATE TABLE IF NOT EXISTS order_delivery_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    uploader_id BIGINT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    note VARCHAR(200),
    created_at DATETIME NOT NULL,
    KEY idx_order_delivery_images_order_created (order_id, created_at),
    KEY idx_order_delivery_images_uploader_created (uploader_id, created_at)
);

CREATE TABLE IF NOT EXISTS order_status_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    from_status VARCHAR(20),
    to_status VARCHAR(20) NOT NULL,
    operator_id BIGINT NOT NULL,
    note VARCHAR(255),
    created_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS admin_reports (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category VARCHAR(60) NOT NULL,
    target_type VARCHAR(40) NOT NULL,
    target_id BIGINT NOT NULL,
    reporter_id BIGINT,
    description TEXT,
    status VARCHAR(20) NOT NULL,
    handled_by BIGINT,
    handle_note VARCHAR(200),
    handled_at DATETIME,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    KEY idx_admin_reports_status_created (status, created_at),
    KEY idx_admin_reports_target (target_type, target_id)
);

CREATE TABLE IF NOT EXISTS admin_audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    operator_id BIGINT NOT NULL,
    action VARCHAR(60) NOT NULL,
    target_type VARCHAR(40) NOT NULL,
    target_id BIGINT NOT NULL,
    before_data TEXT,
    after_data TEXT,
    `timestamp` DATETIME NOT NULL,
    ip VARCHAR(64),
    device_id VARCHAR(100),
    note VARCHAR(255),
    KEY idx_admin_audit_operator_time (operator_id, `timestamp`),
    KEY idx_admin_audit_target (target_type, target_id)
);

CREATE TABLE IF NOT EXISTS system_config (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    cancel_window_runner_minutes INT NOT NULL,
    cancel_window_requester_minutes INT NOT NULL,
    expire_grace_minutes INT NOT NULL,
    max_concurrent_orders INT NOT NULL,
    max_daily_accept INT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

CREATE TABLE IF NOT EXISTS friend_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    from_user_id BIGINT NOT NULL,
    to_user_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    message VARCHAR(200),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    KEY idx_friend_requests_to_status (to_user_id, status),
    KEY idx_friend_requests_from_status (from_user_id, status)
);

CREATE TABLE IF NOT EXISTS friendships (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    friend_user_id BIGINT NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY uk_friendships_pair (user_id, friend_user_id),
    KEY idx_friendships_user_status (user_id, status),
    KEY idx_friendships_friend (friend_user_id)
);

CREATE TABLE IF NOT EXISTS conversations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_a_id BIGINT NOT NULL,
    user_b_id BIGINT NOT NULL,
    last_message_id BIGINT,
    last_message_preview VARCHAR(255),
    last_message_at DATETIME,
    last_read_message_id_by_a BIGINT,
    last_read_message_id_by_b BIGINT,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    UNIQUE KEY uk_conversations_pair (user_a_id, user_b_id),
    KEY idx_conversations_last_time (last_message_at),
    KEY idx_conversations_user_a (user_a_id),
    KEY idx_conversations_user_b (user_b_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id BIGINT NOT NULL,
    sender_id BIGINT NOT NULL,
    client_message_id VARCHAR(64),
    content_type VARCHAR(20) NOT NULL,
    content VARCHAR(1000) NOT NULL,
    status VARCHAR(20) NOT NULL,
    sent_at DATETIME NOT NULL,
    created_at DATETIME NOT NULL,
    UNIQUE KEY uk_messages_client_message_id (client_message_id),
    KEY idx_messages_conv_id (conversation_id, id),
    KEY idx_messages_sender_time (sender_id, sent_at)
);
