package com.kmarzecki.communicator.model.friends;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Value;

/**
 * Response containing data about a friendship connection between users
 */
@Value
@AllArgsConstructor
@Builder
public class FriendshipResponse {
    /**
     * Friendship id
     */
    Integer id;
    /**
     * User that initiated the friendship
     */
    String requester;
    /**
     * The second user in the friendship
     */
    String target;
    /**
     * Flag indicating that this friendship is one sided, and not yet confirmed
     */
    boolean pending;
}
