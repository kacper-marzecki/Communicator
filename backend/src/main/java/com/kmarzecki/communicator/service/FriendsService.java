package com.kmarzecki.communicator.service;

import java.security.Principal;

/**
 * Service containing logic related to friends
 */
public interface FriendsService {
    /**
     * Get Friends of the requesting user
     * Pushes the response through a websocket connection
     * @param principal Principal of the requesting user
     */
    void getFriendsFor(Principal principal);

    /**
     * Add a friend
     * Pushes the response through a websocket connection
     * @param request Request containing data for a adding a friend
     * @param principal Principal of the requesting user
     */
    void addFriend(String requester, String target);

    /**
     * Respond to a friendship request
     * Pushes the response through a websocket connection
     * @param request Request containing data with a response to a friendship request
     * @param principal Principal of the requesting user
     * @param request_id id of the friendship request
     */
    void processFriendshipRequest(Integer id, boolean accept, Principal principal);
}
