package com.campusrunner.backend.conversation.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import com.campusrunner.backend.auth.service.CurrentUserService;
import com.campusrunner.backend.conversation.dto.ConversationSummaryResponse;
import com.campusrunner.backend.conversation.dto.CreatePrivateConversationRequest;
import com.campusrunner.backend.conversation.dto.MessageItemResponse;
import com.campusrunner.backend.conversation.dto.MessageListResponse;
import com.campusrunner.backend.conversation.dto.SendMessageRequest;
import com.campusrunner.backend.conversation.service.ChatImageStorageService;
import com.campusrunner.backend.conversation.service.ConversationService;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * 会话相关接口。
 */
@Validated
@RestController
@RequestMapping("/api/v1/conversations")
public class ConversationController {

    private final CurrentUserService currentUserService;
    private final ConversationService conversationService;
    private final ChatImageStorageService chatImageStorageService;

    public ConversationController(
            CurrentUserService currentUserService,
            ConversationService conversationService,
            ChatImageStorageService chatImageStorageService) {
        this.currentUserService = currentUserService;
        this.conversationService = conversationService;
        this.chatImageStorageService = chatImageStorageService;
    }

    @GetMapping
    public List<ConversationSummaryResponse> listConversations(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return conversationService.listConversations(currentUserId);
    }

    @PostMapping({ "", "/private" })
    public ConversationSummaryResponse createPrivateConversation(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @Valid @RequestBody CreatePrivateConversationRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        Long targetUserId = request.resolveTargetUserId();
        if (targetUserId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "目标聊天用户不能为空");
        }
        return conversationService.createOrGetConversation(currentUserId, targetUserId, request.getOrderId());
    }

    @GetMapping("/{id}/messages")
    public MessageListResponse listMessages(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId,
            @RequestParam(value = "page", defaultValue = "1") @Min(1) int page,
            @RequestParam(value = "page_size", defaultValue = "20") @Min(1) @Max(100) int pageSize) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return conversationService.listMessages(currentUserId, conversationId, page, pageSize);
    }

    @PostMapping("/{id}/messages")
    public MessageItemResponse sendMessage(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId,
            @Valid @RequestBody SendMessageRequest request) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        return conversationService.sendMessage(currentUserId, conversationId, request);
    }

    @PostMapping(value = "/{id}/images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public MessageItemResponse uploadImage(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId,
            @RequestPart("file") MultipartFile file) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        String relativePath = chatImageStorageService.storeImage(file);
        String publicUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path(relativePath)
                .toUriString();
        return conversationService.sendImageMessage(currentUserId, conversationId, publicUrl);
    }

    @PostMapping("/{id}/read")
    public void markRead(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        conversationService.markConversationRead(currentUserId, conversationId);
    }

    @DeleteMapping("/{id}")
    public void deleteConversation(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        conversationService.deleteConversation(currentUserId, conversationId);
    }

    @DeleteMapping("/{id}/messages/{messageId}")
    public void deleteMessage(
            @RequestHeader(value = "Authorization", required = false) String authorizationHeader,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @PathVariable("id") Long conversationId,
            @PathVariable("messageId") Long messageId) {
        Long currentUserId = currentUserService.resolveUserId(authorizationHeader, userId);
        conversationService.deleteMessage(currentUserId, conversationId, messageId);
    }
}
