package com.kmarzecki.communicator.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.NoArgsConstructor;
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

