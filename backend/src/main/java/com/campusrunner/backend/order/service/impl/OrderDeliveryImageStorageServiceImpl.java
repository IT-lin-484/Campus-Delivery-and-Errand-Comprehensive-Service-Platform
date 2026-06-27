package com.campusrunner.backend.order.service.impl;

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

/**
 * 璁㈠崟浜や粯鍥剧墖瀛樺偍鏈嶅姟銆? */
@Service
public class OrderDeliveryImageStorageServiceImpl implements com.campusrunner.backend.order.service.OrderDeliveryImageStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".jpg", ".jpeg", ".png", ".gif", ".webp");

    @Value("${app.upload.order-image-dir:./uploads/order-images}")
    private String orderImageDir;

    @Value("${app.upload.order-image-url-prefix:/uploads/order-images/}")
    private String orderImageUrlPrefix;

    @Value("${app.upload.order-image-max-size:8388608}")
    private long orderImageMaxSize;

    public String storeImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "璇烽€夋嫨瑕佷笂浼犵殑浜や粯鍥剧墖");
        }
        if (file.getSize() > orderImageMaxSize) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "浜や粯鍥剧墖杩囧ぇ锛屽缓璁笉瓒呰繃8MB");
        }

        String extension = extractExtension(file.getOriginalFilename());
        if (!isSupportedImage(file.getContentType(), extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "浠呮敮鎸?jpg/jpeg/png/gif/webp 鏍煎紡");
        }

        Path dirPath = Paths.get(orderImageDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(dirPath);

            String fileName = UUID.randomUUID().toString().replace("-", "") + extension;
            Path target = dirPath.resolve(fileName).normalize();
            try (InputStream input = file.getInputStream()) {
                Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
            }
            return normalizePrefix(orderImageUrlPrefix) + fileName;
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "浜や粯鍥剧墖涓婁紶澶辫触锛岃绋嶅悗閲嶈瘯");
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
        String normalized = (prefix == null || prefix.isBlank()) ? "/uploads/order-images/" : prefix.trim();
        if (!normalized.startsWith("/")) {
            normalized = "/" + normalized;
        }
        if (!normalized.endsWith("/")) {
            normalized = normalized + "/";
        }
        return normalized;
    }
}

