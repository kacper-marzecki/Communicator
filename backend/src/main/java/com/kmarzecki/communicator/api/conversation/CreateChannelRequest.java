package com.kmarzecki.communicator.api.conversation;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotEmpty;
import java.util.Set;

@Getter
@Setter
public class CreateChannelRequest {
    @NotBlank
    private String name;
    @NotEmpty
    private Set<String> usernames;
}
