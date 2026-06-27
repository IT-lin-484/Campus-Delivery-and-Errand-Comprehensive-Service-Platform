package com.campusrunner.backend.profile.service;

import java.util.List;

import com.campusrunner.backend.profile.dto.MyProfileResponse;
import com.campusrunner.backend.profile.dto.UpdateMyProfileRequest;
import com.campusrunner.backend.profile.dto.UserProfileResponse;
import com.campusrunner.backend.profile.dto.UserSearchItemResponse;

/**
 * Profile service for current-user and public-profile operations.
 */
public interface UserProfileService {

    MyProfileResponse getMyProfile(Long userId);

    MyProfileResponse updateMyProfile(Long userId, UpdateMyProfileRequest request);

    MyProfileResponse updateAvatar(Long userId, String avatarUrl);

    UserProfileResponse getUserProfile(Long currentUserId, Long targetUserId);

    List<UserSearchItemResponse> searchUsers(Long currentUserId, String keyword, int page, int pageSize);
}
