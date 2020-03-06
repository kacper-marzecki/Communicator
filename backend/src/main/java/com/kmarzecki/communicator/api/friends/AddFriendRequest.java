package com.kmarzecki.communicator.api.friends;

import com.sun.istack.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import javax.validation.constraints.NotBlank;

@Getter
@Setter
@NoArgsConstructor
public class AddFriendRequest {
    @NotBlank
    private String target;
}
