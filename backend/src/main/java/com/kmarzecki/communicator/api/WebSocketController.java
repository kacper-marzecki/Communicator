package com.kmarzecki.communicator.api;


import lombok.AllArgsConstructor;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@AllArgsConstructor
public class WebSocketController {

    @MessageMapping("/message")
    @SendToUser("/queue/reply")
    public String processMessageFromClient(Principal principal) {
        System.out.println(principal.getName());
        return principal.getName();
    }

}
