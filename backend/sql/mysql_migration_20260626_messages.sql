-- Align the legacy MySQL schema with the current Spring Boot chat module.
USE campus_runner_board;

-- Preserve existing message data while renaming and extending the columns
-- required by com.campusrunner.backend.conversation.entity.ChatMessage.
ALTER TABLE messages
    ADD COLUMN client_message_id VARCHAR(64) NULL AFTER sender_id,
    ADD COLUMN content_type VARCHAR(20) NULL AFTER client_message_id,
    ADD COLUMN status VARCHAR(20) NULL AFTER content,
    ADD COLUMN created_at DATETIME NULL AFTER sent_at;

UPDATE messages
SET content_type = type,
    status = 'SENT',
    created_at = sent_at;

ALTER TABLE messages
    MODIFY content_type VARCHAR(20) NOT NULL,
    MODIFY status VARCHAR(20) NOT NULL,
    MODIFY created_at DATETIME NOT NULL,
    DROP COLUMN type,
    ADD UNIQUE KEY uk_messages_client_message_id (client_message_id);
