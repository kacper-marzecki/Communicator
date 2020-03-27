package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.api.conversation.MessageRequest;
import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.model.auth.UserEntity;
import com.kmarzecki.communicator.model.conversation.ChannelEntity;
import com.kmarzecki.communicator.model.conversation.ChannelListResponse;
import com.kmarzecki.communicator.model.conversation.MessageEntity;
import com.kmarzecki.communicator.model.conversation.MessageResponse;
import com.kmarzecki.communicator.repository.ChannelRepository;
import com.kmarzecki.communicator.repository.MessageRepository;
import com.kmarzecki.communicator.repository.UserRepository;
import com.kmarzecki.communicator.util.DateTimeProvider;
import lombok.AllArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Set;

import static com.kmarzecki.communicator.util.CollectionUtils.mapList;
import static com.kmarzecki.communicator.util.InternationalizationUtil.*;
import static com.kmarzecki.communicator.util.MessageUtils.*;

@Service
@AllArgsConstructor
class ConversationServiceImpl implements ConversationService {
    private final ChannelRepository channelRepository;
    private final UserRepository userRepository;
    private final SimpMessageSendingOperations messagingTemplate;
    private final MessageRepository messageRepository;
    private final DateTimeProvider dateTimeProvider;

    public void getUserChannels(Principal principal) {
        mapList(this::map,
                channelRepository.findAllByUsers_Username(principal.getName())
        ).forEach(c -> messagingTemplate.convertAndSendToUser(
                principal.getName(),
                CHANNELS_TOPIC,
                c));
    }

    @Override
    public void createChannel(String channelName, Set<String> usernames, Language language, Principal creator) {
        usernames.add(creator.getName());
        Set<UserEntity> users = userRepository.findAllByUsernameIn(usernames);
        if (users.size() != usernames.size()) {
            sendError(messagingTemplate, creator.getName(), cannotFindRequestedUsers(language));
            throw new OperationNotPermittedException();
        }
        if (channelRepository.existsByNameAndUsers_UsernameIn(channelName, usernames)){
            sendError(messagingTemplate, creator.getName(), conversationNameIsNotUnique(language) );
            throw new OperationNotPermittedException();
        }

        ChannelEntity entity = channelRepository.save(ChannelEntity.builder()
                .name(channelName)
                .users(users)
                .build());
        usernames.forEach(username -> messagingTemplate.convertAndSendToUser(
                username,
                CHANNELS_TOPIC,
                map(entity)));
    }

    @Override
    public void message(String from, MessageRequest request) {
        ChannelEntity channelEntity = channelRepository.getOne(request.getChannelId());
        UserEntity userEntity = userRepository.findByUsername(from);
        MessageEntity message = MessageEntity.builder()
                .channelId(request.getChannelId())
                .user(userEntity)
                .payload(request.getPayload())
                .time(dateTimeProvider.currentLocalDateTime())
                .build();
        MessageResponse response = map(messageRepository.save(message));
        channelEntity.getUsers().forEach(user -> messagingTemplate.convertAndSendToUser(
                user.getUsername(),
                MESSAGES_TOPIC,
                response
                ));
    }

    @Override
    public void getMessages(String user, Integer channelId) {
        ChannelEntity channelEntity = channelRepository.getOne(channelId);
        if(channelEntity.getUsers().stream().noneMatch(u -> u.getUsername().equals(user))) {
            throw new OperationNotPermittedException();
        }
        Pageable pageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "time"));
        List<MessageEntity> messages = messageRepository.findAllByChannelId(channelId, pageable);
        messages.forEach(m -> messagingTemplate.convertAndSendToUser(
                user,
                MESSAGES_TOPIC,
                map(m)
        ));
    }


    @Override
    public void getPreviousMessages(Principal requester, Integer channelId, Long beforeTime) {
        ChannelEntity channelEntity = channelRepository.getOne(channelId);
        if(channelEntity.getUsers().stream().noneMatch(u -> u.getUsername().equals(requester.getName()))) {
            throw new OperationNotPermittedException();
        }
        Pageable pageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "time"));
        List<MessageEntity> messages = messageRepository.findAllByChannelIdAndTimeBefore(
                channelId,
                LocalDateTime.ofEpochSecond(beforeTime, 0, ZoneOffset.ofTotalSeconds(0)),
                pageable
        );
        messages.forEach(m -> messagingTemplate.convertAndSendToUser(
                requester.getName(),
                PREVIOUS_MESSAGES_TOPIC,
                map(m)
        ));
    }

    private MessageResponse map(MessageEntity entity) {
        return MessageResponse.builder()
                .id(entity.getId())
                .channelId(entity.getChannelId())
                .payload(entity.getPayload())
                .time(entity.getTime().toEpochSecond(ZoneOffset.ofTotalSeconds(0)))
                .username(entity.getUser().getUsername())
                .build();
    }

    private ChannelListResponse map(ChannelEntity c) {
        return ChannelListResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .users(mapList(UserEntity::getUsername, c.getUsers()))
                .build();
    }
}
