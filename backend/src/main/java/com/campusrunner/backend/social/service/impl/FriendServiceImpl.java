package com.campusrunner.backend.social.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.campusrunner.backend.social.dao.FriendRequestDao;
import com.campusrunner.backend.social.dao.FriendshipDao;
import com.campusrunner.backend.social.dto.FriendItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestListResponse;
import com.campusrunner.backend.social.dto.SendFriendRequestRequest;
import com.campusrunner.backend.social.entity.FriendRequest;
import com.campusrunner.backend.social.entity.Friendship;
import com.campusrunner.backend.social.enums.FriendRequestStatus;
import com.campusrunner.backend.social.enums.FriendshipStatus;
import com.campusrunner.backend.social.service.FriendService;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;

/**
 * Friend relationship service implementation.
 */
@Service
public class FriendServiceImpl implements FriendService {

    private final FriendRequestDao friendRequestDao;
    private final FriendshipDao friendshipDao;
    private final UserDao userDao;

    public FriendServiceImpl(
            FriendRequestDao friendRequestDao,
            FriendshipDao friendshipDao,
            UserDao userDao) {
        this.friendRequestDao = friendRequestDao;
        this.friendshipDao = friendshipDao;
        this.userDao = userDao;
    }

    @Override
    @Transactional
    public FriendRequestItemResponse sendRequest(Long currentUserId, SendFriendRequestRequest request) {
        Long targetUserId = request.getToUserId();
        if (targetUserId.equals(currentUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能添加自己为好友");
        }

        User fromUser = requireActiveUser(currentUserId);
        User toUser = requireActiveUser(targetUserId);

        if (!Boolean.TRUE.equals(toUser.getAllowFriendRequest())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "对方关闭了好友申请");
        }

        if (areFriends(currentUserId, targetUserId)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "你们已经是好友");
        }

        boolean hasPending = friendRequestDao
                .findTopByFromUserIdAndToUserIdAndStatusOrderByCreatedAtDesc(
                        currentUserId,
                        targetUserId,
                        FriendRequestStatus.PENDING)
                .isPresent();
        if (hasPending) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "你已发起过好友申请，请等待对方处理");
        }

        boolean pendingFromOtherSide = friendRequestDao
                .findTopByFromUserIdAndToUserIdAndStatusOrderByCreatedAtDesc(
                        targetUserId,
                        currentUserId,
                        FriendRequestStatus.PENDING)
                .isPresent();
        if (pendingFromOtherSide) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "对方已向你发起申请，请到好友页处理");
        }

        FriendRequest friendRequest = new FriendRequest();
        friendRequest.setFromUserId(currentUserId);
        friendRequest.setToUserId(targetUserId);
        friendRequest.setStatus(FriendRequestStatus.PENDING);
        friendRequest.setMessage(normalizeText(request.getMessage()));

        FriendRequest saved = friendRequestDao.save(friendRequest);
        return toFriendRequestResponse(saved, fromUser, toUser);
    }

    @Override
    @Transactional(readOnly = true)
    public FriendRequestListResponse listRequests(Long currentUserId) {
        requireActiveUser(currentUserId);

        List<FriendRequest> receivedRequests = friendRequestDao.findByToUserIdOrderByCreatedAtDesc(currentUserId);
        List<FriendRequest> sentRequests = friendRequestDao.findByFromUserIdOrderByCreatedAtDesc(currentUserId);

        Map<Long, User> userMap = loadUsersForRequests(receivedRequests, sentRequests);

        FriendRequestListResponse response = new FriendRequestListResponse();
        response.setReceived(receivedRequests.stream()
                .map(item -> toFriendRequestResponse(item, userMap.get(item.getFromUserId()), userMap.get(item.getToUserId())))
                .toList());
        response.setSent(sentRequests.stream()
                .map(item -> toFriendRequestResponse(item, userMap.get(item.getFromUserId()), userMap.get(item.getToUserId())))
                .toList());
        return response;
    }

    @Override
    @Transactional
    public FriendRequestItemResponse acceptRequest(Long currentUserId, Long requestId) {
        FriendRequest request = findRequest(requestId);
        if (!request.getToUserId().equals(currentUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有接收方可同意该申请");
        }
        if (request.getStatus() != FriendRequestStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前申请状态不可同意");
        }

        request.setStatus(FriendRequestStatus.ACCEPTED);
        FriendRequest savedRequest = friendRequestDao.save(request);
        createBidirectionalFriendship(savedRequest.getFromUserId(), savedRequest.getToUserId());

        User fromUser = requireActiveUser(savedRequest.getFromUserId());
        User toUser = requireActiveUser(savedRequest.getToUserId());
        return toFriendRequestResponse(savedRequest, fromUser, toUser);
    }

    @Override
    @Transactional
    public FriendRequestItemResponse rejectRequest(Long currentUserId, Long requestId) {
        FriendRequest request = findRequest(requestId);
        if (!request.getToUserId().equals(currentUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有接收方可拒绝该申请");
        }
        if (request.getStatus() != FriendRequestStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前申请状态不可拒绝");
        }

        request.setStatus(FriendRequestStatus.REJECTED);
        FriendRequest savedRequest = friendRequestDao.save(request);

        User fromUser = requireActiveUser(savedRequest.getFromUserId());
        User toUser = requireActiveUser(savedRequest.getToUserId());
        return toFriendRequestResponse(savedRequest, fromUser, toUser);
    }

    @Override
    @Transactional
    public FriendRequestItemResponse cancelRequest(Long currentUserId, Long requestId) {
        FriendRequest request = findRequest(requestId);
        if (!request.getFromUserId().equals(currentUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只有申请方可撤回");
        }
        if (request.getStatus() != FriendRequestStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "当前申请状态不可撤回");
        }

        request.setStatus(FriendRequestStatus.CANCELLED);
        FriendRequest savedRequest = friendRequestDao.save(request);

        User fromUser = requireActiveUser(savedRequest.getFromUserId());
        User toUser = requireActiveUser(savedRequest.getToUserId());
        return toFriendRequestResponse(savedRequest, fromUser, toUser);
    }

    @Override
    @Transactional(readOnly = true)
    public List<FriendItemResponse> listFriends(Long currentUserId) {
        requireActiveUser(currentUserId);

        List<Friendship> friendships = friendshipDao.findByUserIdAndStatusOrderByUpdatedAtDesc(
                currentUserId,
                FriendshipStatus.ACTIVE);
        List<Long> friendUserIds = friendships.stream().map(Friendship::getFriendUserId).toList();
        Map<Long, User> userMap = userDao.findAllById(friendUserIds).stream()
                .collect(HashMap::new, (map, user) -> map.put(user.getId(), user), HashMap::putAll);

        return friendships.stream()
                .map(friendship -> {
                    User friendUser = userMap.get(friendship.getFriendUserId());
                    if (friendUser == null) {
                        return null;
                    }
                    FriendItemResponse item = new FriendItemResponse();
                    item.setUserId(friendUser.getId());
                    item.setUsername(friendUser.getUsername());
                    item.setNickname(friendUser.getNickname());
                    item.setAvatarUrl(friendUser.getAvatarUrl());
                    item.setBio(friendUser.getBio());
                    item.setBecameFriendsAt(friendship.getCreatedAt());
                    return item;
                })
                .filter(item -> item != null)
                .toList();
    }

    @Override
    @Transactional
    public void deleteFriend(Long currentUserId, Long friendUserId) {
        requireActiveUser(currentUserId);
        requireActiveUser(friendUserId);

        friendshipDao.deleteByUserIdAndFriendUserId(currentUserId, friendUserId);
        friendshipDao.deleteByUserIdAndFriendUserId(friendUserId, currentUserId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean areFriends(Long userId, Long friendUserId) {
        return friendshipDao.existsByUserIdAndFriendUserIdAndStatus(
                userId,
                friendUserId,
                FriendshipStatus.ACTIVE);
    }

    private void createBidirectionalFriendship(Long userAId, Long userBId) {
        createFriendshipIfNotExists(userAId, userBId);
        createFriendshipIfNotExists(userBId, userAId);
    }

    private void createFriendshipIfNotExists(Long userId, Long friendUserId) {
        boolean exists = friendshipDao.findByUserIdAndFriendUserIdAndStatus(
                userId,
                friendUserId,
                FriendshipStatus.ACTIVE).isPresent();
        if (exists) {
            return;
        }

        Friendship friendship = new Friendship();
        friendship.setUserId(userId);
        friendship.setFriendUserId(friendUserId);
        friendship.setStatus(FriendshipStatus.ACTIVE);
        friendshipDao.save(friendship);
    }

    private FriendRequest findRequest(Long requestId) {
        return friendRequestDao.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "好友申请不存在"));
    }

    private Map<Long, User> loadUsersForRequests(List<FriendRequest> receivedRequests, List<FriendRequest> sentRequests) {
        List<Long> userIds = receivedRequests.stream()
                .flatMap(item -> List.of(item.getFromUserId(), item.getToUserId()).stream())
                .toList();
        List<Long> sentUserIds = sentRequests.stream()
                .flatMap(item -> List.of(item.getFromUserId(), item.getToUserId()).stream())
                .toList();

        Map<Long, User> userMap = new HashMap<>();
        userDao.findAllById(userIds).forEach(user -> userMap.put(user.getId(), user));
        userDao.findAllById(sentUserIds).forEach(user -> userMap.put(user.getId(), user));
        return userMap;
    }

    private User requireActiveUser(Long userId) {
        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "目标用户不可用");
        }
        return user;
    }

    private FriendRequestItemResponse toFriendRequestResponse(FriendRequest request, User fromUser, User toUser) {
        FriendRequestItemResponse response = new FriendRequestItemResponse();
        response.setId(request.getId());
        response.setFromUserId(request.getFromUserId());
        response.setFromNickname(fromUser == null ? "未知用户" : fromUser.getNickname());
        response.setFromAvatarUrl(fromUser == null ? null : fromUser.getAvatarUrl());
        response.setToUserId(request.getToUserId());
        response.setToNickname(toUser == null ? "未知用户" : toUser.getNickname());
        response.setToAvatarUrl(toUser == null ? null : toUser.getAvatarUrl());
        response.setStatus(request.getStatus());
        response.setMessage(request.getMessage());
        response.setCreatedAt(request.getCreatedAt());
        response.setUpdatedAt(request.getUpdatedAt());
        return response;
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }
}
