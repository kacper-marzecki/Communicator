package com.kmarzecki.communicator.api.auth;


import lombok.Getter;
import lombok.Setter;

/**
 * Request containing user registration information
 */
@Getter
@Setter
public class RegisterRequest {
    /**
     * Username of the user
     */
    private String username;
    /**
     * Password of the user
     */
    private String password;
}
