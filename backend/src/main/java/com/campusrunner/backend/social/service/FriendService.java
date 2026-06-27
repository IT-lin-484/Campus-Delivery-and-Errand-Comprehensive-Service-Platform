package com.campusrunner.backend.social.service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import com.campusrunner.backend.social.dto.FriendItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestListResponse;
import com.campusrunner.backend.social.dto.SendFriendRequestRequest;
import com.campusrunner.backend.social.entity.FriendRequest;
import com.campusrunner.backend.social.entity.Friendship;
import com.campusrunner.backend.social.enums.FriendRequestStatus;
import com.campusrunner.backend.social.enums.FriendshipStatus;
import com.campusrunner.backend.social.dao.FriendRequestDao;
import com.campusrunner.backend.social.dao.FriendshipDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.user.dao.UserDao;

public interface FriendService {
    FriendRequestItemResponse sendRequest(Long currentUserId, SendFriendRequestRequest request);
    FriendRequestListResponse listRequests(Long currentUserId);
    FriendRequestItemResponse acceptRequest(Long currentUserId, Long requestId);
    FriendRequestItemResponse rejectRequest(Long currentUserId, Long requestId);
    FriendRequestItemResponse cancelRequest(Long currentUserId, Long requestId);
    List<FriendItemResponse> listFriends(Long currentUserId);
    void deleteFriend(Long currentUserId, Long friendUserId);
    boolean areFriends(Long userId, Long friendUserId);
}

