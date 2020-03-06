package com.kmarzecki.communicator.api.conversation;

import com.kmarzecki.communicator.service.ConversationService;
import com.kmarzecki.communicator.service.FriendsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;

@RestController
@RequestMapping("/conversation")
public class ConversationController {

    /**
     * get my conversations
     * non paginated
     */
    @Autowired
    private SimpMessageSendingOperations messagingTemplate;
    @Autowired
    private ConversationService conversationService;
    @Autowired
    private FriendsService friendsService;
    @MessageMapping("/get_channels")
    public void getChannels(Principal principal) {
        conversationService.getUserChannels(principal)
                .forEach(c -> {
                    messagingTemplate.convertAndSendToUser(
                            principal.getName(),
                            "/topic/channels",
                            c);
                });
    }

    @MessageMapping("/get_friends")
    public void getFriends(Principal principal) {
        friendsService.getFriendsFor(principal)
                .forEach(f -> messagingTemplate.convertAndSendToUser(
                        principal.getName(),
                        "/topic/friends",
                        f));
    }


    /**    create conversation
     *  with one person
     *  with multiple people
     *?  adding a person to a conversation is verboten/enabled
     */

    //?? hide Conversation
}
