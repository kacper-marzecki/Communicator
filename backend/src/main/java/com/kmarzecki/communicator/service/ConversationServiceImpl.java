package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.model.ChannelListResponse;
import com.kmarzecki.communicator.model.UserEntity;
import com.kmarzecki.communicator.repository.ChannelRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ConversationServiceImpl implements ConversationService {
    @Autowired
    ChannelRepository channelRepository;

    @Override
    public List<ChannelListResponse> getUserChannels(Principal principal) {
        return channelRepository.findAllByUsers_Username(principal.getName())
                .stream()
                .map(c -> ChannelListResponse.builder()
                        .id(c.getId())
                        .name(c.getName())
                        .oneOnOne(c.isOneOnOne())
                        .users(c.getUsers().stream().map(UserEntity::getUsername).collect(Collectors.toList()))
                        .build())
                .collect(Collectors.toList());
    }
}
