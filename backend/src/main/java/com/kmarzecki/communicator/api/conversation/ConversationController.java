package com.kmarzecki.communicator.api.conversation;

import com.kmarzecki.communicator.service.ConversationService;
import com.kmarzecki.communicator.service.FriendsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;

import static com.kmarzecki.communicator.util.MessageUtils.CHANNELS_TOPIC;
import static com.kmarzecki.communicator.util.MessageUtils.FRIENDS_TOPIC;

@RestController
@RequestMapping("/conversation")
@CrossOrigin(origins = "http://localhost:3000",allowCredentials = "true", allowedHeaders = "*")
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
        conversationService.getUserChannels(principal);
    }

    @MessageMapping("/get_friends")
    public void getFriends(Principal principal) {
        friendsService.getFriendsFor(principal)
                .forEach(f -> messagingTemplate.convertAndSendToUser(
                        principal.getName(),
                        FRIENDS_TOPIC,
                        f));
    }


    @PostMapping
    public void createChannel(
            @Valid
            @RequestBody
            CreateChannelRequest request,
            Principal principal
    ) {
        conversationService.createChannel(request.getName(), request.getUsernames(), principal);
    }
    /**    create conversation
     *  with one person
     *  with multiple people
     *?  adding a person to a conversation is verboten/enabled
     */

    //?? hide Conversation
}
