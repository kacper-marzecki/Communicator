package com.kmarzecki.communicator.api.conversation;

import lombok.Getter;
import lombok.Setter;

/**
 * Request użytkownika zawierający wysłaną wiadomość
 */
@Getter
@Setter
public class MessageRequest {
    /**
     * Id klanału do którego kierowana jest ta wiadomość
     */
    private int channelId;
    /**
     * Zawartość wiadomości
     */
    private String payload;
}
