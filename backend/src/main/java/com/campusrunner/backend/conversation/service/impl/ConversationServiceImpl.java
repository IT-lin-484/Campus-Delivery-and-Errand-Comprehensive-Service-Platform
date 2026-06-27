package com.campusrunner.backend.conversation.service.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.campusrunner.backend.conversation.dao.ChatMessageDao;
import com.campusrunner.backend.conversation.dao.ConversationDao;
import com.campusrunner.backend.conversation.dto.ConversationSummaryResponse;
import com.campusrunner.backend.conversation.dto.MessageItemResponse;
import com.campusrunner.backend.conversation.dto.MessageListResponse;
import com.campusrunner.backend.conversation.dto.RealtimeMessageDispatchResult;
import com.campusrunner.backend.conversation.dto.SendMessageRequest;
import com.campusrunner.backend.conversation.entity.ChatMessage;
import com.campusrunner.backend.conversation.entity.Conversation;
import com.campusrunner.backend.conversation.enums.MessageContentType;
import com.campusrunner.backend.conversation.enums.MessageStatus;
import com.campusrunner.backend.conversation.service.ConversationService;
import com.campusrunner.backend.order.dao.OrderDao;
import com.campusrunner.backend.order.entity.Order;
import com.campusrunner.backend.order.enums.OrderStatus;
import com.campusrunner.backend.social.dao.FriendshipDao;
import com.campusrunner.backend.social.enums.FriendshipStatus;
import com.campusrunner.backend.user.dao.UserDao;
import com.campusrunner.backend.user.entity.User;
import com.campusrunner.backend.user.enums.UserStatus;
import com.campusrunner.backend.websocket.PresenceService;
import com.campusrunner.backend.websocket.RealtimeMessageNotifier;

/**
 * 会话服务实现。
 */
@Service
public class ConversationServiceImpl implements ConversationService {

    private static final Set<OrderStatus> ORDER_CHAT_ENABLED_STATUSES = Set.of(
            OrderStatus.ACCEPTED,
            OrderStatus.IN_PROGRESS,
            OrderStatus.DELIVERED,
            OrderStatus.COMPLETED,
            OrderStatus.CANCELLED);

    private static final int TEMPORARY_MESSAGE_LIMIT = 10;

    private final ConversationDao conversationDao;
    private final ChatMessageDao chatMessageDao;
    private final UserDao userDao;
    private final FriendshipDao friendshipDao;
    private final OrderDao orderDao;
    private final PresenceService presenceService;
    private final RealtimeMessageNotifier realtimeMessageNotifier;

    public ConversationServiceImpl(
            ConversationDao conversationDao,
            ChatMessageDao chatMessageDao,
            UserDao userDao,
            FriendshipDao friendshipDao,
            OrderDao orderDao,
            PresenceService presenceService,
            RealtimeMessageNotifier realtimeMessageNotifier) {
        this.conversationDao = conversationDao;
        this.chatMessageDao = chatMessageDao;
        this.userDao = userDao;
        this.friendshipDao = friendshipDao;
        this.orderDao = orderDao;
        this.presenceService = presenceService;
        this.realtimeMessageNotifier = realtimeMessageNotifier;
    }

    @Override
    @Transactional(readOnly = true)
    public List<ConversationSummaryResponse> listConversations(Long currentUserId) {
        requireActiveUser(currentUserId);

        List<Conversation> conversations = conversationDao.selectList(Wrappers.<Conversation>lambdaQuery()
                .and(group -> group.eq(Conversation::getUserAId, currentUserId)
                        .or()
                        .eq(Conversation::getUserBId, currentUserId))
                .isNotNull(Conversation::getLastMessageId)
                .orderByDesc(Conversation::getLastMessageAt, Conversation::getUpdatedAt));

        if (conversations.isEmpty()) {
            return List.of();
        }

        List<Long> counterpartIds = conversations.stream()
                .map(item -> item.getUserAId().equals(currentUserId) ? item.getUserBId() : item.getUserAId())
                .toList();
        Map<Long, User> userMap = loadUsers(counterpartIds);

        return conversations.stream()
                .map(conversation -> {
                    Long counterpartId = conversation.getUserAId().equals(currentUserId)
                            ? conversation.getUserBId()
                            : conversation.getUserAId();
                    return toConversationSummary(conversation, currentUserId, userMap.get(counterpartId), counterpartId);
                })
                .toList();
    }

    @Override
    @Transactional
    public ConversationSummaryResponse createOrGetConversation(Long currentUserId, Long targetUserId, Long orderId) {
        if (currentUserId.equals(targetUserId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "不能和自己创建会话");
        }

        requireActiveUser(currentUserId);
        requireActiveUser(targetUserId);

        boolean allowed = canUsersChat(currentUserId, targetUserId);
        if (!allowed && orderId != null) {
            allowed = canChatBeforeAcceptByOrder(currentUserId, targetUserId, orderId);
        }
        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "仅好友或订单相关用户可以聊天");
        }

        Conversation conversation = createOrLoadConversation(currentUserId, targetUserId);
        Map<Long, User> userMap = loadUsers(List.of(conversation.getUserAId(), conversation.getUserBId()));
        Long counterpartId = conversation.getUserAId().equals(currentUserId)
                ? conversation.getUserBId()
                : conversation.getUserAId();
        return toConversationSummary(conversation, currentUserId, userMap.get(counterpartId), counterpartId);
    }

    @Override
    @Transactional(readOnly = true)
    public MessageListResponse listMessages(Long currentUserId, Long conversationId, int page, int pageSize) {
        Conversation conversation = requireConversationMember(currentUserId, conversationId);
        Long counterpartId = conversation.getUserAId().equals(currentUserId)
                ? conversation.getUserBId()
                : conversation.getUserAId();
        ConversationAccess access = buildConversationAccess(conversation.getId(), currentUserId, counterpartId);

        Page<ChatMessage> messagePage = chatMessageDao.selectPage(
                new Page<>(page, pageSize),
                Wrappers.<ChatMessage>lambdaQuery()
                        .eq(ChatMessage::getConversationId, conversation.getId())
                        .orderByDesc(ChatMessage::getId));

        if (messagePage.getRecords().isEmpty()) {
            MessageListResponse response = new MessageListResponse();
            response.setList(List.of());
            response.setTotal(messagePage.getTotal());
            response.setPage(page);
            response.setPageSize(pageSize);
            applyConversationAccess(response, access);
            return response;
        }

        Map<Long, User> senderMap = loadUsers(messagePage.getRecords().stream()
                .map(ChatMessage::getSenderId)
                .distinct()
                .toList());

        List<MessageItemResponse> items = messagePage.getRecords().stream()
                .map(message -> toMessageItem(currentUserId, message, senderMap.get(message.getSenderId())))
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
        Collections.reverse(items);

        MessageListResponse response = new MessageListResponse();
        response.setList(items);
        response.setTotal(messagePage.getTotal());
        response.setPage(page);
        response.setPageSize(pageSize);
        applyConversationAccess(response, access);
        return response;
    }

    @Override
    @Transactional
    public MessageItemResponse sendMessage(Long currentUserId, Long conversationId, SendMessageRequest request) {
        RealtimeMessageDispatchResult dispatch = sendTextMessageByRealtime(currentUserId, conversationId, request);
        realtimeMessageNotifier.notifyRecipients(conversationId, dispatch.recipientMessages());
        return dispatch.senderAck();
    }

    @Override
    @Transactional
    public MessageItemResponse sendTextMessage(Long currentUserId, Long conversationId, SendMessageRequest request) {
        return sendTextMessageByRealtime(currentUserId, conversationId, request).senderAck();
    }

    @Override
    @Transactional
    public RealtimeMessageDispatchResult sendTextMessageByRealtime(
            Long currentUserId,
            Long conversationId,
            SendMessageRequest request) {
        String normalizedContent = normalizeText(request.getContent());
        if (normalizedContent == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "消息内容不能为空");
        }

        return persistMessage(
                currentUserId,
                conversationId,
                normalizeClientMessageId(request.getClientMessageId()),
                MessageContentType.TEXT,
                normalizedContent,
                normalizedContent);
    }

    @Override
    @Transactional
    public MessageItemResponse sendImageMessage(Long currentUserId, Long conversationId, String imageUrl) {
        String normalizedImageUrl = normalizeText(imageUrl);
        if (normalizedImageUrl == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "图片地址不能为空");
        }

        RealtimeMessageDispatchResult dispatch = persistMessage(
                currentUserId,
                conversationId,
                UUID.randomUUID().toString(),
                MessageContentType.IMAGE,
                normalizedImageUrl,
                null);
        realtimeMessageNotifier.notifyRecipients(conversationId, dispatch.recipientMessages());
        return dispatch.senderAck();
    }

    @Override
    @Transactional
    public void markConversationRead(Long currentUserId, Long conversationId) {
        Conversation conversation = requireConversationMember(currentUserId, conversationId);
        if (conversation.getLastMessageId() == null) {
            return;
        }

        if (conversation.getUserAId().equals(currentUserId)) {
            conversation.setLastReadMessageIdByA(conversation.getLastMessageId());
        } else {
            conversation.setLastReadMessageIdByB(conversation.getLastMessageId());
        }
        conversationDao.save(conversation);
    }

    @Override
    @Transactional(readOnly = true)
    public long countTotalUnreadMessages(Long currentUserId) {
        requireActiveUser(currentUserId);

        List<Conversation> conversations = conversationDao.selectList(Wrappers.<Conversation>lambdaQuery()
                .and(group -> group.eq(Conversation::getUserAId, currentUserId)
                        .or()
                        .eq(Conversation::getUserBId, currentUserId)));

        long total = 0L;
        for (Conversation conversation : conversations) {
            total += calculateUnreadCount(conversation, currentUserId);
        }
        return total;
    }

    @Override
    @Transactional
    public void ensureConversationBetweenUsers(Long userAId, Long userBId) {
        if (userAId.equals(userBId)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "会话参与者不能相同");
        }

        requireActiveUser(userAId);
        requireActiveUser(userBId);
        createOrLoadConversation(userAId, userBId);
    }

    @Override
    @Transactional
    public void deleteConversation(Long currentUserId, Long conversationId) {
        requireConversationMember(currentUserId, conversationId);
        chatMessageDao.delete(Wrappers.<ChatMessage>lambdaQuery()
                .eq(ChatMessage::getConversationId, conversationId));
        conversationDao.deleteById(conversationId);
    }

    @Override
    @Transactional
    public void deleteMessage(Long currentUserId, Long conversationId, Long messageId) {
        Conversation conversation = requireConversationMember(currentUserId, conversationId);
        ChatMessage message = chatMessageDao.findById(messageId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "消息不存在"));
        if (!conversation.getId().equals(message.getConversationId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "消息不属于当前会话");
        }
        if (!currentUserId.equals(message.getSenderId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "只能删除自己发送的消息");
        }

        chatMessageDao.deleteById(messageId);
        refreshConversationSnapshot(conversation);
    }

    @Override
    @Transactional
    public void sendOrderImageMessage(Long senderId, Long receiverId, Long orderId, String imageUrl, String note) {
        String normalizedImageUrl = normalizeText(imageUrl);
        if (normalizedImageUrl == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "订单图片地址不能为空");
        }
        if (!canUsersChat(senderId, receiverId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "当前关系不能发送订单凭证");
        }

        Conversation conversation = ensureConversationBetweenUsersAndLoad(senderId, receiverId);
        RealtimeMessageDispatchResult imageDispatch = persistMessage(
                senderId,
                conversation.getId(),
                null,
                MessageContentType.IMAGE,
                normalizedImageUrl,
                "订单#" + orderId + " 配送图片");
        realtimeMessageNotifier.notifyRecipients(conversation.getId(), imageDispatch.recipientMessages());

        String normalizedNote = normalizeText(note);
        if (normalizedNote != null) {
            RealtimeMessageDispatchResult noteDispatch = persistMessage(
                    senderId,
                    conversation.getId(),
                    null,
                    MessageContentType.TEXT,
                    "订单#" + orderId + " 备注：" + normalizedNote,
                    normalizedNote);
            realtimeMessageNotifier.notifyRecipients(conversation.getId(), noteDispatch.recipientMessages());
        }
    }

    private ConversationSummaryResponse toConversationSummary(
            Conversation conversation,
            Long currentUserId,
            User counterpart,
            Long counterpartId) {
        int unreadCount = calculateUnreadCount(conversation, currentUserId);
        boolean online = counterpart != null && presenceService.isUserOnline(counterpart.getId());
        ConversationAccess access = buildConversationAccess(conversation.getId(), currentUserId, counterpartId);
        return ConversationSummaryResponse.from(
                conversation,
                counterpart,
                unreadCount,
                online,
                access.friendConversation(),
                TEMPORARY_MESSAGE_LIMIT,
                access.temporaryMessageCount(),
                access.canSendMessage());
    }

    private MessageItemResponse toMessageItem(Long currentUserId, ChatMessage message, User sender) {
        if (sender == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "消息发送者不存在");
        }
        boolean online = presenceService.isUserOnline(sender.getId());
        return MessageItemResponse.from(currentUserId, message, sender, online);
    }

    private Conversation requireConversationMember(Long currentUserId, Long conversationId) {
        Conversation conversation = conversationDao.findById(conversationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "会话不存在"));
        if (!conversation.getUserAId().equals(currentUserId) && !conversation.getUserBId().equals(currentUserId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权访问该会话");
        }
        return conversation;
    }

    private User requireActiveUser(Long userId) {
        User user = userDao.findById(userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "用户不存在"));
        if (user.getStatus() != UserStatus.ACTIVE) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "目标用户当前不可用");
        }
        return user;
    }

    private Conversation createOrLoadConversation(Long userAId, Long userBId) {
        long minId = Math.min(userAId, userBId);
        long maxId = Math.max(userAId, userBId);
        return conversationDao.findByUserAIdAndUserBId(minId, maxId)
                .orElseGet(() -> {
                    Conversation created = new Conversation();
                    created.setUserAId(minId);
                    created.setUserBId(maxId);
                    return conversationDao.save(created);
                });
    }

    private Conversation ensureConversationBetweenUsersAndLoad(Long userAId, Long userBId) {
        return createOrLoadConversation(userAId, userBId);
    }

    private boolean canUsersChat(Long userId, Long targetUserId) {
        if (friendshipDao.existsByUserIdAndFriendUserIdAndStatus(userId, targetUserId, FriendshipStatus.ACTIVE)) {
            return true;
        }
        return orderDao.existsCommunicationOrderBetweenUsers(userId, targetUserId, ORDER_CHAT_ENABLED_STATUSES);
    }

    private boolean canChatBeforeAcceptByOrder(Long currentUserId, Long targetUserId, Long orderId) {
        Order order = orderDao.findById(orderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "订单不存在"));
        if (order.getStatus() != OrderStatus.OPEN) {
            return false;
        }
        if (currentUserId.equals(order.getRequesterId())) {
            return false;
        }
        return targetUserId.equals(order.getRequesterId());
    }

    private RealtimeMessageDispatchResult persistMessage(
            Long senderId,
            Long conversationId,
            String clientMessageId,
            MessageContentType contentType,
            String content,
            String previewText) {
        Conversation conversation = requireConversationMember(senderId, conversationId);
        User sender = requireActiveUser(senderId);
        Long targetUserId = conversation.getUserAId().equals(senderId)
                ? conversation.getUserBId()
                : conversation.getUserAId();
        ConversationAccess access = buildConversationAccess(conversation.getId(), senderId, targetUserId);
        if (normalizeClientMessageId(clientMessageId) != null && !access.canSendMessage()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "临时聊天已达到 10 条上限，请先添加对方为好友");
        }

        ChatMessage message = new ChatMessage();
        message.setConversationId(conversation.getId());
        message.setSenderId(senderId);
        message.setClientMessageId(normalizeClientMessageId(clientMessageId));
        message.setContentType(contentType);
        message.setContent(content);
        message.setStatus(MessageStatus.SENT);
        ChatMessage saved = chatMessageDao.save(message);

        String preview = normalizeText(previewText);
        if (preview == null) {
            preview = buildPreview(contentType, content);
        }
        conversation.setLastMessageId(saved.getId());
        conversation.setLastMessageAt(saved.getSentAt());
        conversation.setLastMessagePreview(preview);
        if (conversation.getUserAId().equals(senderId)) {
            conversation.setLastReadMessageIdByA(saved.getId());
        } else {
            conversation.setLastReadMessageIdByB(saved.getId());
        }
        conversationDao.save(conversation);

        User targetUser = requireActiveUser(targetUserId);
        MessageItemResponse senderAck = toMessageItem(senderId, saved, sender);
        Map<Long, MessageItemResponse> recipientMessages = new LinkedHashMap<>();
        recipientMessages.put(targetUserId, toMessageItem(targetUserId, saved, targetUser));
        return new RealtimeMessageDispatchResult(senderAck, recipientMessages);
    }

    private Map<Long, User> loadUsers(List<Long> ids) {
        if (ids == null || ids.isEmpty()) {
            return Map.of();
        }
        return userDao.findAllById(ids).stream()
                .collect(Collectors.toMap(User::getId, user -> user, (left, right) -> left, HashMap::new));
    }

    private int calculateUnreadCount(Conversation conversation, Long currentUserId) {
        Long lastReadId = conversation.getUserAId().equals(currentUserId)
                ? conversation.getLastReadMessageIdByA()
                : conversation.getLastReadMessageIdByB();
        if (lastReadId == null) {
            return (int) chatMessageDao.countByConversationIdAndSenderIdNot(conversation.getId(), currentUserId);
        }
        return (int) chatMessageDao.countByConversationIdAndSenderIdNotAndIdGreaterThan(
                conversation.getId(),
                currentUserId,
                lastReadId);
    }

    private String buildPreview(MessageContentType type, String content) {
        if (type == MessageContentType.IMAGE) {
            return "[图片]";
        }
        if (type == MessageContentType.FILE) {
            return "[文件]";
        }
        return content;
    }

    private void refreshConversationSnapshot(Conversation conversation) {
        chatMessageDao.findTopByConversationIdOrderByIdDesc(conversation.getId()).ifPresentOrElse(
                latestMessage -> {
                    conversation.setLastMessageId(latestMessage.getId());
                    conversation.setLastMessageAt(latestMessage.getSentAt());
                    conversation.setLastMessagePreview(buildPreview(
                            latestMessage.getContentType(),
                            latestMessage.getContent()));
                    if (conversation.getLastReadMessageIdByA() != null
                            && conversation.getLastReadMessageIdByA() > latestMessage.getId()) {
                        conversation.setLastReadMessageIdByA(latestMessage.getId());
                    }
                    if (conversation.getLastReadMessageIdByB() != null
                            && conversation.getLastReadMessageIdByB() > latestMessage.getId()) {
                        conversation.setLastReadMessageIdByB(latestMessage.getId());
                    }
                    conversationDao.save(conversation);
                },
                () -> {
                    conversation.setLastMessageId(null);
                    conversation.setLastMessageAt(null);
                    conversation.setLastMessagePreview(null);
                    conversation.setLastReadMessageIdByA(null);
                    conversation.setLastReadMessageIdByB(null);
                    conversationDao.save(conversation);
                });
    }

    private ConversationAccess buildConversationAccess(Long conversationId, Long currentUserId, Long counterpartId) {
        boolean friendConversation = friendshipDao.existsByUserIdAndFriendUserIdAndStatus(
                currentUserId,
                counterpartId,
                FriendshipStatus.ACTIVE);
        if (friendConversation) {
            return new ConversationAccess(true, 0, true);
        }

        int temporaryMessageCount = (int) chatMessageDao.countTemporaryMessagesByConversationId(conversationId);
        boolean canSendMessage = temporaryMessageCount < TEMPORARY_MESSAGE_LIMIT;
        return new ConversationAccess(false, temporaryMessageCount, canSendMessage);
    }

    private void applyConversationAccess(MessageListResponse response, ConversationAccess access) {
        response.setFriendConversation(access.friendConversation());
        response.setTemporaryConversation(!access.friendConversation());
        response.setTemporaryMessageLimit(TEMPORARY_MESSAGE_LIMIT);
        response.setTemporaryMessageCount(access.temporaryMessageCount());
        response.setTemporaryMessageRemaining(Math.max(0, TEMPORARY_MESSAGE_LIMIT - access.temporaryMessageCount()));
        response.setCanSendMessage(access.canSendMessage());
    }

    private String normalizeText(String text) {
        if (text == null) {
            return null;
        }
        String normalized = text.trim();
        return normalized.isEmpty() ? null : normalized;
    }

    private String normalizeClientMessageId(String clientMessageId) {
        String normalized = normalizeText(clientMessageId);
        return normalized == null ? null : normalized;
    }

    private record ConversationAccess(
            boolean friendConversation,
            int temporaryMessageCount,
            boolean canSendMessage) {
    }
}
