package com.kmarzecki.communicator.api.friends;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import javax.validation.constraints.NotBlank;

/**
 * Request containing data for requesting a friendship
 */
@Getter
@Setter
@NoArgsConstructor
public class AddFriendRequest {
    /**
     * Username of the User asked for a friendship
     */
    @NotBlank
    private String target;
}
