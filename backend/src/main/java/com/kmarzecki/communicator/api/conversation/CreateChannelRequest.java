package com.kmarzecki.communicator.api.conversation;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import java.util.Set;

/**
 * Request containing data for channel creation
 */
@Getter
@Setter
public class CreateChannelRequest {
    /**
     * Name of the channel
     */
    @NotBlank
    private String name;
    /**
     * Usernames of users to be given access to the channel
     */
    @NotEmpty
    private Set<String> usernames;
}
