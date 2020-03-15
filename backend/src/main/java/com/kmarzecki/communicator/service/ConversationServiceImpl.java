package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.api.conversation.MessageRequest;
import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.*;
import com.kmarzecki.communicator.repository.ChannelRepository;
import com.kmarzecki.communicator.repository.MessageRepository;
import com.kmarzecki.communicator.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
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
import static com.kmarzecki.communicator.util.MessageUtils.*;

@Service
public class ConversationServiceImpl implements ConversationService {
    @Autowired
    ChannelRepository channelRepository;
    @Autowired
    UserRepository userRepository;
    @Autowired
    private SimpMessageSendingOperations messagingTemplate;
    @Autowired
    MessageRepository messageRepository;
    @Autowired
    private TimeProvider timeProvider;
    @Override
    public void getUserChannels(Principal principal) {
        mapList(this::map,
                channelRepository.findAllByUsers_Username(principal.getName())
        ).forEach(c -> {
            messagingTemplate.convertAndSendToUser(
                    principal.getName(),
                    CHANNELS_TOPIC,
                    c);
        });
    }

    @Override
    public void createChannel(String name, Set<String> usernames, Principal creator) {
        usernames.add(creator.getName());
        var users = userRepository.findAllByUsernameIn(usernames);
        if (users.size() != usernames.size()) {
            sendError(messagingTemplate, creator.getName(), "Cannot find all requested users");
            throw new OperationNotPermittedException();
        }
        if (channelRepository.existsByNameAndUsers_UsernameIn(name, usernames)){
            sendError(messagingTemplate, creator.getName(), "Conversation name is not unique");
            throw new OperationNotPermittedException();
        }

        var entity = channelRepository.save(ChannelEntity.builder()
                .name(name)
                .oneOnOne(usernames.size() == 2)
                .users(users)
                .build());
        messagingTemplate.convertAndSendToUser(
                creator.getName(),
                CHANNELS_TOPIC,
                map(entity));
    }

    @Override
    public void message(String from, MessageRequest request) {
        ChannelEntity channelEntity = channelRepository.getOne(request.getChannelId());
        UserEntity userEntity = userRepository.findByUsername(from);

        MessageEntity message = MessageEntity.builder()
                .channelId(request.getChannelId())
                .user(userEntity)
                .payload(request.getPayload())
                .time(timeProvider.now())
                .build();
        MessageResponse response = map(messageRepository.save(message));
        channelEntity.getUsers().forEach(user -> {
            messagingTemplate.convertAndSendToUser(
                    user.getUsername(),
                    MESSAGES_TOPIC,
                    response
                    );
        });
    }

    @Override
    public void getMessages(String user, Integer channelId) {
        ChannelEntity channelEntity = channelRepository.getOne(channelId);
        if(channelEntity.getUsers().stream().noneMatch(u -> u.getUsername().equals(user))) {
            throw new OperationNotPermittedException();
        }
        Pageable pageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "time"));
        List<MessageEntity> messages = messageRepository.findAllByChannelId(channelId, pageable);
        messages.forEach(m -> {
            messagingTemplate.convertAndSendToUser(
                    user,
                    MESSAGES_TOPIC,
                    map(m)
            );
        });
    }

    @Override
    public void getPreviousMessages(String user, Integer channelId, LocalDateTime time) {
        ChannelEntity channelEntity = channelRepository.getOne(channelId);
        if(channelEntity.getUsers().stream().noneMatch(u -> u.getUsername().equals(user))) {
            throw new OperationNotPermittedException();
        }
        Pageable pageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "time"));
        List<MessageEntity> messages = messageRepository.findAllByChannelIdAndTimeBefore(channelId, time, pageable);
        messages.forEach(m -> {
            messagingTemplate.convertAndSendToUser(
                    user,
                    PREVIOUS_MESSAGES_TOPIC,
                    map(m)
            );
        });
    }

    private MessageResponse map(MessageEntity entity) {
        return MessageResponse.builder()
                .id(entity.getId())
                .channelId(entity.getChannelId())
                .messageType(MessageType.TEXT_MESSAGE)
                .payload(entity.getPayload())
                .time(entity.getTime().toEpochSecond(ZoneOffset.ofTotalSeconds(0)))
                .username(entity.getUser().getUsername())
                .build();
    }

    private ChannelListResponse map(ChannelEntity c) {
        return ChannelListResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .oneOnOne(c.isOneOnOne())
                .users(mapList(UserEntity::getUsername, c.getUsers()))
                .build();
    }
}
