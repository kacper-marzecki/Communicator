package com.kmarzecki.communicator.api.friends;

import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.service.FriendsService;
import lombok.AllArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;

/**
 * Controller for operations concerning friends and friendships
 */
@RestController
@RequestMapping("/friends")
@CrossOrigin(origins = {"*"},allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor
public class FriendController {
    private final FriendsService friendsService;
    private final SimpMessageSendingOperations messagingTemplate;

    /**
     * Get Friends of the requesting user
     * @param principal Principal of the requesting user
     */
    @MessageMapping("/get_friends")
    public void getFriends(Principal principal) {
        friendsService.getFriendsFor(principal);
    }

    /**
     * Add a friend
     * @param request Request containing data for a adding a friend
     * @param principal Principal of the requesting user
     * @param language user language
     */
    @PostMapping
    public void addFriend(
            @Valid @RequestBody AddFriendRequest request,
            @RequestParam(name = "language") Language language,
            Principal principal
    ) {
        friendsService.addFriend(principal.getName(), request.getTarget(), language);
    }

    /**
     * Respond to a friendship request
     * @param request Request containing data with a response to a friendship request
     * @param principal Principal of the requesting user
     * @param request_id id of the friendship request
     * @param language user language
     */
    @PostMapping("/process_request/{id}")
    public void processRequest(
            @Valid @RequestBody ProcessFriendshipRequest request,
            @PathVariable(name = "id") Integer request_id,
            @RequestParam(name = "language")Language language,
            Principal principal
            ) {
        friendsService.processFriendshipRequest(request_id, request.isAcceptRequest(), principal, language );
    }
}
