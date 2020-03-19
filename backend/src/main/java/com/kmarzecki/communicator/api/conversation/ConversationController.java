package com.kmarzecki.communicator.api.conversation;

import com.kmarzecki.communicator.service.ConversationService;
import com.kmarzecki.communicator.service.FriendsService;
import lombok.AllArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

import static com.kmarzecki.communicator.util.MessageUtils.FRIENDS_TOPIC;

@RestController
@RequestMapping("/conversation")
@CrossOrigin(origins = "http://localhost:3000", allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor
public class ConversationController {
    private final SimpMessageSendingOperations messagingTemplate;
    private final ConversationService conversationService;
    private final FriendsService friendsService;

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

    @PostMapping("/message")
    public void message(
            @Valid
            @RequestBody MessageRequest request,
            Principal principal
    ) {
        conversationService.message(principal.getName(), request);
    }

    @GetMapping("/message")
    public void getMessages(
            @RequestParam(name = "channelId") Integer channelId
            , Principal principal
    ) {
        conversationService.getMessages(principal.getName(), channelId);

    }

    @GetMapping(path = "previous_messages")
    public void getPreviousMessages (
            @RequestParam(name = "channelId") Integer channelId
            ,@RequestParam(name = "before") Long before
            , Principal principal
    ) {
        conversationService.getPreviousMessages(principal.getName(), channelId, LocalDateTime.ofEpochSecond(before, 0, ZoneOffset.ofTotalSeconds(0)));
    }

    //?? hide Conversation
}
