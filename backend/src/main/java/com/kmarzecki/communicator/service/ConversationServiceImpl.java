package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.ChannelEntity;
import com.kmarzecki.communicator.model.ChannelListResponse;
import com.kmarzecki.communicator.model.UserEntity;
import com.kmarzecki.communicator.repository.ChannelRepository;
import com.kmarzecki.communicator.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;
import java.util.Set;

import static com.kmarzecki.communicator.util.CollectionUtils.mapList;
import static com.kmarzecki.communicator.util.MessageUtils.CHANNELS_TOPIC;
import static com.kmarzecki.communicator.util.MessageUtils.sendError;

@Service
public class ConversationServiceImpl implements ConversationService {
    @Autowired
    ChannelRepository channelRepository;
    @Autowired
    UserRepository userRepository;
    @Autowired
    private SimpMessageSendingOperations messagingTemplate;

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

    private ChannelListResponse map(ChannelEntity c) {
        return ChannelListResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .oneOnOne(c.isOneOnOne())
                .users(mapList(UserEntity::getUsername, c.getUsers()))
                .build();
    }
}
