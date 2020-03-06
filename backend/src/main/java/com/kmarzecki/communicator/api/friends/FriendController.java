package com.kmarzecki.communicator.api.friends;

import com.kmarzecki.communicator.service.FriendsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;

@RestController
@RequestMapping("/friends")
@CrossOrigin(origins = "http://localhost:3000",allowCredentials = "true", allowedHeaders = "*")
public class FriendController {
    @Autowired
    FriendsService friendsService;

    @PostMapping
    public void addFriend(
            @Valid
            @RequestBody AddFriendRequest request,
            Principal principal
    ) {
        friendsService.addFriend(principal.getName(), request.getTarget());
    }

    @PostMapping("/process_request/{id}")
    public void processRequest(
            @Valid
            @RequestBody
            ProcessFriendshipRequest request,
            Principal principal,
            @PathVariable(name = "id")
            Integer id
    ) {
        friendsService.processFriendshipRequest(id, request.isAccept(), principal );
    }
}
