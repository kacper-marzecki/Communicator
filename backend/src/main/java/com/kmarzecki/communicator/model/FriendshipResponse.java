package com.kmarzecki.communicator.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Value;

@Value
@AllArgsConstructor
@Builder
public class FriendshipResponse {
    Integer id;
    String requester;
    String target;
    boolean pending;
}
