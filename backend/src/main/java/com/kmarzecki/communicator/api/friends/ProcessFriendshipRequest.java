package com.kmarzecki.communicator.api.friends;

import lombok.Value;

import javax.validation.constraints.NotNull;

@Value
public class ProcessFriendshipRequest {
    boolean accept;
}
