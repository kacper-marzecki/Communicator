package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.model.ChannelListResponse;

import java.security.Principal;
import java.util.List;
import java.util.Set;

public interface ConversationService {

    void getUserChannels(Principal principal);

    void createChannel(String name, Set<String> usernames, Principal creator);
}
