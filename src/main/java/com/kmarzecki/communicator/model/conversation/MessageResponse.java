package com.kmarzecki.communicator.model.conversation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Value;

/**
 * Response containing data about a message
 */
@Value
@Builder
@AllArgsConstructor
public class MessageResponse {
    /**
     * Message Id
     */
    Integer id;
    /**
     * Channel this message has been sent to
     */
    Integer channelId;
    /**
     * Message payload
     */
    String payload;
    /**
     * Username of the user this message has been sent by
     */
    String username;
    /**
     * Time at which this message has been sent, as a UNIX timestamp
     */
    Long time;
}

