package com.campusrunner.backend.social.controller;

import java.util.List;

import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.social.dto.FriendItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestItemResponse;
import com.campusrunner.backend.social.dto.FriendRequestListResponse;
import com.campusrunner.backend.social.dto.SendFriendRequestRequest;
import com.campusrunner.backend.social.service.FriendService;

import jakarta.validation.Valid;

/**
 * 濂藉弸鍏崇郴鎺ュ彛銆? */
@Validated
@RestController
@RequestMapping("/api/v1/friends")
public class FriendController {

    private final CurrentUserService currentUserService;
    private final FriendService friendService;

    public FriendController(CurrentUserService currentUserService, FriendService friendService) {
        this.currentUserService = currentUserService;
        this.friendService = friendService;
    }

    @PostMapping("/requests")
    public FriendRequestItemResponse sendRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @Valid @RequestBody SendFriendRequestRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.sendRequest(currentUserId, request);
    }

    @GetMapping("/requests")
    public FriendRequestListResponse listRequests(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.listRequests(currentUserId);
    }

    @PostMapping("/requests/{id}/accept")
    public FriendRequestItemResponse acceptRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long requestId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.acceptRequest(currentUserId, requestId);
    }

    @PostMapping("/requests/{id}/reject")
    public FriendRequestItemResponse rejectRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long requestId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.rejectRequest(currentUserId, requestId);
    }

    @PostMapping("/requests/{id}/cancel")
    public FriendRequestItemResponse cancelRequest(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long requestId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.cancelRequest(currentUserId, requestId);
    }

    @GetMapping
    public List<FriendItemResponse> listFriends(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return friendService.listFriends(currentUserId);
    }

    @DeleteMapping("/{friendUserId}")
    public void deleteFriend(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("friendUserId") Long friendUserId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        friendService.deleteFriend(currentUserId, friendUserId);
    }
}

