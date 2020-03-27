package com.kmarzecki.communicator.model.auth;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * Response containing User information
 */
@AllArgsConstructor
@Getter
public class UserResponse {
    private String username;
}
