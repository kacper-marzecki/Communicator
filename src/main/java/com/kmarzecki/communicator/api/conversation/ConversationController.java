package com.kmarzecki.communicator.api.conversation;

import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.service.ConversationService;
import lombok.AllArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.security.Principal;

/**
 * Controller for operations concerning Conversations
 */
@RestController
@RequestMapping("/conversation")
@CrossOrigin(origins = {"*"},allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor
public class ConversationController {
    private final ConversationService conversationService;

    /**
     * Get conversation channels available to the user
     * @param principal Principal of the user
     */
    @MessageMapping("/get_channels")
    public void getChannels(Principal principal) {
        conversationService.getUserChannels(principal);
    }

    /**
     * Create a conversation channel
     * @param request Information about the new conversation channel
     * @param language User language
     * @param principal Principal of the requesting user
     */
    @PostMapping
    public void createChannel(
            @Valid @RequestBody CreateChannelRequest request,
            @RequestParam(name = "language") Language language,
            Principal principal
    ) {
        conversationService.createChannel(request.getName(), request.getUsernames(),language,  principal);
    }

    /**
     * Send a message
     * @param request Information about the sent message
     * @param principal Principal of the requesting user
     */
    @PostMapping("/message")
    public void message(
            @Valid @RequestBody MessageRequest request,
            Principal principal
    ) {
        conversationService.message(principal.getName(), request);
    }

    /**
     * Get messages from a channel
     * @param channelId Id of the channel
     * @param principal Principal of the requesting user
     */
    @GetMapping("/message")
    public void getMessages(
            @RequestParam(name = "channelId") Integer channelId,
            Principal principal
    ) {
        conversationService.getMessages(principal.getName(), channelId);
    }

    /**
     * Get messages from a channel, before a specific time
     * @param channelId Id of the channel
     * @param before UNIX timestamp time boundary
     * @param principal Principal of the requesting user
     */
    @GetMapping(path = "previous_messages")
    public void getPreviousMessages (
            @RequestParam(name = "channelId") Integer channelId,
            @RequestParam(name = "before") Long before,
            Principal principal
    ) {
        conversationService.getPreviousMessages(principal, channelId, before);
    }
}
