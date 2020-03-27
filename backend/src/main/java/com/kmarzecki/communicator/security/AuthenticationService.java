package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.model.auth.LoginDto;
import com.kmarzecki.communicator.model.auth.LoginResponse;
import com.kmarzecki.communicator.model.auth.RegisterDto;
import com.kmarzecki.communicator.model.auth.UserResponse;

import java.security.Principal;

/**
 * Authentication service
 */
public interface AuthenticationService {
    /**
     * Login user
     * @param dto dto containing login information
     * @param language
     * @return logged user response
     */
    LoginResponse login(LoginDto dto);

    /**
     * Register user
     * @param registerDto dto containing registration information
     * @param language
     */
    void register(RegisterDto registerDto, Language language);

    /**
     * Get user information
     * @param principal user principal
     * @return User information response
     */
    UserResponse getMe(Principal principal);
}
