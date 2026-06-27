package com.campusrunner.backend.profile.service.impl;

import java.util.List;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.profile.dto.MyProfileResponse;
import com.campusrunner.backend.profile.dto.UpdateMyProfileRequest;
import com.campusrunner.backend.profile.dto.UserProfileResponse;
import com.campusrunner.backend.profile.dto.UserRelationStatus;
import com.campusrunner.backend.profile.dto.UserSearchItemResponse;
import com.campusrunner.backend.profile.service.UserProfileService;
import com.campusrunner.backend.social.dao.FriendRequestDao;
import com.campusrunner.backend.social.dao.FriendshipDao;
import com.campusrunner.backend.social.enums.FriendRequestStatus;
import com.campusrunner.backend.social.enums.FriendshipStatus;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * User profile service implementation.
 */
@Service
public class UserProfileServiceImpl implements UserProfileService {

    private final UserDao userDao;
    private final OrderDao orderDao;
    private final FriendshipDao friendshipDao;
    private final FriendRequestDao friendRequestDao;

    public UserProfileServiceImpl(
            UserDao userDao,
            OrderDao orderDao,
            FriendshipDao friendshipDao,
            FriendRequestDao friendRequestDao) {
        this.userDao = userDao;
        this.orderDao = orderDao;
        this.friendshipDao = friendshipDao;
        this.friendRequestDao = friendRequestDao;
    }

    @Override
    @Transactional(readOnly = true)
    public MyProfileResponse getMyProfile(Long userId) {
        User user = requireActiveUser(userId);
        return toMyProfile(user);
    }

    @Override
    @Transactional
    public MyProfileResponse updateMyProfile(Long userId, UpdateMyProfileRequest request) {
        User user = requireActiveUser(userId);

        String normalizedUsername = normalizeUsername(request.getUsername());
        userDao.findByUsername(normalizedUsername)
                .filter(existingUser -> !existingUser.getId().equals(user.getId()))
                .ifPresent(existingUser -> {
                    throw new ResponseStatusException(HttpStatus.CONFLICT, "用户名已存在");
                });

        validatePhone(request.getPhone());

        user.setUsername(normalizedUsername);
        user.setNickname(request.getNickname().trim());
        user.setPhone(normalizePhone(request.getPhone()));
        user.setCommonAddress(normalizeText(request.getCommonAddress()));
        user.setBio(normalizeText(request.getBio()));
        user.setAllowFriendRequest(request.getAllowFriendRequest());
        user.setAllowSearch(request.getAllowSearch());
        user.setMessageDnd(request.getMessageDnd());

        User saved = userDao.save(user);
        return toMyProfile(saved);
    }

    @Override
    @Transactional
    public MyProfileResponse updateAvatar(Long userId, String avatarUrl) {
        User user = requireActiveUser(userId);
        user.setAvatarUrl(avatarUrl);
        User saved = userDao.save(user);
        return toMyProfile(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public UserProfileResponse getUserProfile(Long currentUserId, Long targetUserId) {
        User target = requireActiveUser(targetUserId);

        UserProfileResponse response = new UserProfileResponse();
        response.setId(target.getId());
        response.setUsername(target.getUsername());
        response.setNickname(target.getNickname());
        response.setAvatarUrl(target.getAvatarUrl());
        response.setBio(target.getBio());
        response.setTotalPublishedOrders(orderDao.countByRequesterId(target.getId()));
        response.setTotalAcceptedOrders(orderDao.countByRunnerId(target.getId()));

        UserRelationStatus relationStatus = resolveRelationStatus(currentUserId, target.getId());
        response.setRelationStatus(relationStatus);
        response.setCanSendFriendRequest(
                relationStatus == UserRelationStatus.NONE
                        && Boolean.TRUE.equals(target.getAllowFriendRequest())
                        && currentUserId != null
                        && !currentUserId.equals(target.getId()));
        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserSearchItemResponse> searchUsers(Long currentUserId, String keyword, int page, int pageSize) {
        String normalizedKeyword = keyword == null ? "" : keyword.trim();
        if (normalizedKeyword.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "搜索关键词不能为空");
        }

        Page<User> result = userDao.selectPage(
                new Page<>(page, pageSize),
                buildSearchQueryWrapper(normalizedKeyword, currentUserId));

        return result.getRecords().stream().map(user -> {
            UserSearchItemResponse item = new UserSearchItemResponse();
            item.setId(user.getId());
            item.setUsername(user.getUsername());
            item.setNickname(user.getNickname());
            item.setAvatarUrl(user.getAvatarUrl());

            UserRelationStatus relationStatus = resolveRelationStatus(currentUserId, user.getId());
            item.setRelationStatus(relationStatus);
            item.setCanSendFriendRequest(
                    relationStatus == UserRelationStatus.NONE
                            && Boolean.TRUE.equals(user.getAllowFriendRequest()));
            return item;
        }).toList();
    }

    private LambdaQueryWrapper<User> buildSearchQueryWrapper(String keyword, Long currentUserId) {
        LambdaQueryWrapper<User> wrapper = Wrappers.lambdaQuery();
        wrapper.eq(User::getStatus, UserStatus.ACTIVE)
                .eq(User::getAllowSearch, true)
                .and(group -> group.like(User::getNickname, keyword)
                        .or().like(User::getUsername, keyword))
                .orderByAsc(User::getNickname);
        if (currentUserId != null) {
            wrapper.ne(User::getId, currentUserId);
        }
        return wrapper;
    }

    private User requireActiveUser(Long userId) {
        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前用户不可用");
        }
        return user;
    }

    private UserRelationStatus resolveRelationStatus(Long currentUserId, Long targetUserId) {
        if (currentUserId == null) {
            return UserRelationStatus.NONE;
        }
        if (currentUserId.equals(targetUserId)) {
            return UserRelationStatus.SELF;
        }

        boolean isFriend = friendshipDao.existsByUserIdAndFriendUserIdAndStatus(
                currentUserId,
                targetUserId,
                FriendshipStatus.ACTIVE);
        if (isFriend) {
            return UserRelationStatus.FRIEND;
        }

        boolean pendingSent = friendRequestDao
                .findTopByFromUserIdAndToUserIdAndStatusOrderByCreatedAtDesc(
                        currentUserId,
                        targetUserId,
                        FriendRequestStatus.PENDING)
                .isPresent();
        if (pendingSent) {
            return UserRelationStatus.REQUEST_SENT;
        }

        boolean pendingReceived = friendRequestDao
                .findTopByFromUserIdAndToUserIdAndStatusOrderByCreatedAtDesc(
                        targetUserId,
                        currentUserId,
                        FriendRequestStatus.PENDING)
                .isPresent();
        if (pendingReceived) {
            return UserRelationStatus.REQUEST_RECEIVED;
        }

        return UserRelationStatus.NONE;
    }

    private MyProfileResponse toMyProfile(User user) {
        MyProfileResponse response = new MyProfileResponse();
        response.setId(user.getId());
        response.setUsername(user.getUsername());
        response.setNickname(user.getNickname());
        response.setPhone(user.getPhone());
        response.setAvatarUrl(user.getAvatarUrl());
        response.setCommonAddress(user.getCommonAddress());
        response.setBio(user.getBio());
        response.setAllowFriendRequest(user.getAllowFriendRequest());
        response.setAllowSearch(user.getAllowSearch());
        response.setMessageDnd(user.getMessageDnd());
        response.setTotalPublishedOrders(orderDao.countByRequesterId(user.getId()));
        response.setTotalAcceptedOrders(orderDao.countByRunnerId(user.getId()));
        return response;
    }

    private String normalizeUsername(String username) {
        if (username == null) {
            return "";
        }
        return username.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizePhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return null;
        }
        return phone.trim();
    }

    private void validatePhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return;
        }
        String normalizedPhone = phone.trim();
        if (!normalizedPhone.matches("^1[3-9]\\d{9}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "手机号格式不正确");
        }
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
