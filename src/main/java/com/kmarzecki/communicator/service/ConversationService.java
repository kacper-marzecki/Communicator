package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.api.conversation.MessageRequest;
import com.kmarzecki.communicator.model.Language;

import java.security.Principal;
import java.util.Set;

/**
 * Service containing logic related to conversation channels
 */
public interface ConversationService {

    /**
     * Get Channels available to user
     * Pushes the response through a websocket connection
     * @param principal User principal
     */
    void getUserChannels(Principal principal);

    /**
     * Create a new channel
     * Pushes the response through a websocket connection
     * @param channelName Channel name
     * @param usernames Usernames of users to add to the channel
     * @param language user language
     * @param creator Channel creator principal
     */
    void createChannel(String channelName, Set<String> usernames, Language language, Principal creator);

    /**
     * Message a channel
     * Pushes the response through a websocket connection
     * @param from User username that sent the message
     * @param request message request
     */
    void message(String from, MessageRequest request);

    /**
     * Get messages in a channel
     * Pushes the response through a websocket connection
     * @param user User requesting messages
     * @param channelId Channel id
     */
    void getMessages(String user, Integer channelId);

    /**
     * Get messages in a chennel before a specified time
     * Pushes the response through a websocket connection
     * @param requester Principal of the requesting user
     * @param channelId channel id
     * @param before Cutout point timestamp
     */
    void getPreviousMessages(Principal requester, Integer channelId, Long before);
}
