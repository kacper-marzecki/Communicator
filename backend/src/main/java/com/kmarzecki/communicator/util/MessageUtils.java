package com.kmarzecki.communicator.util;

import org.springframework.messaging.simp.SimpMessageSendingOperations;

public class MessageUtils {
    public static final String FRIENDS_TOPIC = "/topic/friends";
    public static final String CHANNELS_TOPIC = "/topic/channels";
    public static final String MESSAGES_TOPIC = "/topic/messages";
    public static final String DELETED_FRIENDS_TOPIC = "/topic/deleted_friends";
    public static final String NOTIFICATION_TOPIC = "/topic/notification";

    public static <T> void sendError(SimpMessageSendingOperations template, String user, String error) {
        template.convertAndSendToUser(user, NOTIFICATION_TOPIC, error);
    }
}
