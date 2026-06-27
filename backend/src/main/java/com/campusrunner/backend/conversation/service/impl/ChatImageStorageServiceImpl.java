package com.campusrunner.backend.conversation.service.impl;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.conversation.service.ChatImageStorageService;

/**
 * 聊天图片存储服务实现。
 */
@Service
public class ChatImageStorageServiceImpl implements ChatImageStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".jpg", ".jpeg", ".png", ".gif", ".webp");

    @Value("${app.upload.chat-image-dir:./uploads/chat-images}")
    private String chatImageDir;

    @Value("${app.upload.chat-image-url-prefix:/uploads/chat-images/}")
    private String chatImageUrlPrefix;

    @Value("${app.upload.chat-image-max-size:8388608}")
    private long chatImageMaxSize;

    @Override
    public String storeImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请选择要发送的图片");
        }
        if (file.getSize() > chatImageMaxSize) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "聊天图片大小不能超过 8MB");
        }

        String extension = extractExtension(file.getOriginalFilename());
        if (!isSupportedImage(file.getContentType(), extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "仅支持 jpg/jpeg/png/gif/webp 图片");
        }

        Path dirPath = Paths.get(chatImageDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(dirPath);

            String fileName = UUID.randomUUID().toString().replace("-", "") + extension;
            Path target = dirPath.resolve(fileName).normalize();
            try (InputStream input = file.getInputStream()) {
                Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
            }
            return normalizePrefix(chatImageUrlPrefix) + fileName;
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "聊天图片保存失败");
        }
    }

    private String extractExtension(String originalFileName) {
        if (originalFileName == null || originalFileName.isBlank()) {
            return ".png";
        }
        int lastDotIndex = originalFileName.lastIndexOf('.');
        if (lastDotIndex < 0 || lastDotIndex == originalFileName.length() - 1) {
            return ".png";
        }
        return originalFileName.substring(lastDotIndex).toLowerCase(Locale.ROOT);
    }

    private boolean isSupportedImage(String contentType, String extension) {
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            return false;
        }
        if (contentType == null || contentType.isBlank()) {
            return true;
        }
        return contentType.toLowerCase(Locale.ROOT).startsWith("image/");
    }

    private String normalizePrefix(String prefix) {
        String normalized = (prefix == null || prefix.isBlank()) ? "/uploads/chat-images/" : prefix.trim();
        if (!normalized.startsWith("/")) {
            normalized = "/" + normalized;
        }
        if (!normalized.endsWith("/")) {
            normalized = normalized + "/";
        }
        return normalized;
    }
}
