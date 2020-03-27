package com.kmarzecki.communicator.model.auth;

import lombok.Value;

/**
 * Data required for registration
 */
@Value
public class RegisterDto {
    /**
     * User username
     */
    String username;
    /**
     * User password
     */
    String password;
}
