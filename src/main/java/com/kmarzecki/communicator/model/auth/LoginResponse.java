package com.kmarzecki.communicator.model.auth;

import lombok.Value;

/**
 * Response indicating a successful login
 */
@Value
public class LoginResponse {
    /**
     * Username of the logged in user
     */
    String username;
    /**
     * An authentication token
     */
    String token;
}
