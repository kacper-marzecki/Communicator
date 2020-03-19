package com.kmarzecki.communicator.model.conversation;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
@AllArgsConstructor
public class MessageResponse {
    Integer id;
    Integer channelId;
    String payload;
    String username;
    Long time;
}

