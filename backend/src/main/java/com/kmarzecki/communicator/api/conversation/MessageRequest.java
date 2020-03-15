package com.kmarzecki.communicator.api.conversation;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class MessageRequest {
    private int channelId;
    private String payload;
}
