package com.kmarzecki.communicator.model.auth;

import lombok.Value;

/**
 * Login data
 */
@Value
public class LoginDto {
    /**
     * User username
     */
    String username;
    /**
     * User password
     */
    String password;
}
