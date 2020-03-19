package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.model.friends.FriendshipResponse;

import java.security.Principal;
import java.util.List;

public interface FriendsService {
    List<FriendshipResponse> getFriendsFor(Principal principal);

    void  addFriend(String requester, String target);

    void processFriendshipRequest(Integer id, boolean accept, Principal principal);
}
