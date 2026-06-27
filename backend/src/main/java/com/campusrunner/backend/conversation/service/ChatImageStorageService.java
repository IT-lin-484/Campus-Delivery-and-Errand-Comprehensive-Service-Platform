package com.campusrunner.backend.conversation.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * 聊天图片存储服务。
 */
public interface ChatImageStorageService {

    String storeImage(MultipartFile file);
}
