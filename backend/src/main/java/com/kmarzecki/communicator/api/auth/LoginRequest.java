package com.kmarzecki.communicator.api.auth;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;

/**
 * Request containing login information
 */
@Setter
@Getter
public class LoginRequest {
    /**
     * Username of the user
     */
    @NotBlank
    private String username;
    /**
     * Password of the user
     */
    @NotBlank
    private String password;
}

