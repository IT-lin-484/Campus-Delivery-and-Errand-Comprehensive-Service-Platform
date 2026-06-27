package com.campusrunner.backend.profile.service.impl;

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
 * 澶村儚鏂囦欢瀛樺偍鏈嶅姟銆? */
@Service
public class AvatarStorageServiceImpl implements com.campusrunner.backend.profile.service.AvatarStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of(".jpg", ".jpeg", ".png", ".gif", ".webp");

    @Value("${app.upload.avatar-dir:./uploads/avatars}")
    private String avatarDir;

    @Value("${app.upload.avatar-url-prefix:/uploads/avatars/}")
    private String avatarUrlPrefix;

    @Value("${app.upload.avatar-max-size:5242880}")
    private long avatarMaxSize;

    public String storeAvatar(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "璇烽€夋嫨瑕佷笂浼犵殑澶村儚鏂囦欢");
        }

        if (file.getSize() > avatarMaxSize) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "澶村儚鏂囦欢杩囧ぇ锛屽缓璁笉瓒呰繃5MB");
        }

        String extension = extractExtension(file.getOriginalFilename());
        if (!isSupportedImage(file.getContentType(), extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "浠呮敮鎸?jpg/jpeg/png/gif/webp 鏍煎紡");
        }

        Path dirPath = Paths.get(avatarDir).toAbsolutePath().normalize();
        try {
            Files.createDirectories(dirPath);

            String fileName = UUID.randomUUID().toString().replace("-", "") + extension;
            Path target = dirPath.resolve(fileName).normalize();

            try (InputStream input = file.getInputStream()) {
                Files.copy(input, target, StandardCopyOption.REPLACE_EXISTING);
            }

            return normalizePrefix(avatarUrlPrefix) + fileName;
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "澶村儚涓婁紶澶辫触锛岃绋嶅悗閲嶈瘯");
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
        String normalized = (prefix == null || prefix.isBlank()) ? "/uploads/avatars/" : prefix.trim();

        if (!normalized.startsWith("/")) {
            normalized = "/" + normalized;
        }
        if (!normalized.endsWith("/")) {
            normalized = normalized + "/";
        }
        return normalized;
    }
}

