package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.api.conversation.MessageRequest;

import java.security.Principal;
import java.time.LocalDateTime;
import java.util.Set;

public interface ConversationService {

    void getUserChannels(Principal principal);

    void createChannel(String name, Set<String> usernames, Principal creator);

    void message(String from, MessageRequest request);

    void getMessages(String user, Integer channelId);

    void getPreviousMessages(String name, Integer channelId, LocalDateTime time);
}
