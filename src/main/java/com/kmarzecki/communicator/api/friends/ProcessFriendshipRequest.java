package com.kmarzecki.communicator.api.friends;

import lombok.Getter;
import lombok.Setter;

/**
 * Data for responding to a friendship request
 */
@Getter
@Setter
public class ProcessFriendshipRequest {
    private boolean acceptRequest;
}
