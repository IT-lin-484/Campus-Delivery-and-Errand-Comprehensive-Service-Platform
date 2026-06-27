package com.campusrunner.backend.profile.controller;

import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.profile.dto.MyProfileResponse;
import com.campusrunner.backend.profile.dto.UpdateMyProfileRequest;
import com.campusrunner.backend.profile.dto.UserProfileResponse;
import com.campusrunner.backend.profile.dto.UserSearchItemResponse;
import com.campusrunner.backend.profile.service.AvatarStorageService;
import com.campusrunner.backend.profile.service.UserProfileService;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 涓汉淇℃伅涓庣敤鎴锋悳绱㈡帴鍙ｃ€? */
@Validated
@RestController
@RequestMapping("/api/v1")
public class UserProfileController {

    private final CurrentUserService currentUserService;
    private final UserProfileService userProfileService;
    private final AvatarStorageService avatarStorageService;

    public UserProfileController(
            CurrentUserService currentUserService,
            UserProfileService userProfileService,
            AvatarStorageService avatarStorageService) {
        this.currentUserService = currentUserService;
        this.userProfileService = userProfileService;
        this.avatarStorageService = avatarStorageService;
    }

    @GetMapping("/me/profile")
    public MyProfileResponse getMyProfile(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return userProfileService.getMyProfile(currentUserId);
    }

    @PutMapping("/me/profile")
    public MyProfileResponse updateMyProfile(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @Valid @RequestBody UpdateMyProfileRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return userProfileService.updateMyProfile(currentUserId, request);
    }

    @PostMapping(value = "/me/profile/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public MyProfileResponse uploadAvatar(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestPart("file") MultipartFile file) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);

        String relativePath = avatarStorageService.storeAvatar(file);
        String publicUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path(relativePath)
                .toUriString();

        return userProfileService.updateAvatar(currentUserId, publicUrl);
    }

    @GetMapping("/users/{id}/profile")
    public UserProfileResponse getUserProfile(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long targetUserId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return userProfileService.getUserProfile(currentUserId, targetUserId);
    }

    @GetMapping("/users/search")
    public List<UserSearchItemResponse> searchUsers(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestParam("keyword") String keyword,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "20") @Min(1) @Max(100) int pageSize) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return userProfileService.searchUsers(currentUserId, keyword, page, pageSize);
    }
}

