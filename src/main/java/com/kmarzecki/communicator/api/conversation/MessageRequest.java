package com.kmarzecki.communicator.api.conversation;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;

/**
 * User request containing the message
 */
@Getter
@Setter
public class MessageRequest {
    /**
     * Id of the channel the message is sent to
     */
    @NotNull
    private Integer channelId;
    /**
     * Message payload
     */
    @NotBlank
    private String payload;
}
