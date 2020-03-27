package com.kmarzecki.communicator.api.auth;

import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.model.auth.LoginDto;
import com.kmarzecki.communicator.model.auth.LoginResponse;
import com.kmarzecki.communicator.model.auth.RegisterDto;
import com.kmarzecki.communicator.model.auth.UserResponse;
import com.kmarzecki.communicator.security.AuthenticationService;
import lombok.AllArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;


/**
 *  Controller for operations concerning User registration and login processes
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:3000",allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor
public class AuthController {
    private final AuthenticationService authenticationService;

    /**
     * Login a user
     * @param request Request containing login information
     * @return
     */
    @PostMapping("/login")
    public LoginResponse login(
            @RequestBody @Validated LoginRequest request
    ) {
        return authenticationService.login(new LoginDto(request.getUsername(), request.getPassword()));
    }

    /**
     * Register a user
     * @param request Request containing registration information
     */
    @PostMapping("/register")
    public void register(@RequestBody RegisterRequest request,
                         @RequestParam(name = "language") Language language
    ) {
        authenticationService.register(new RegisterDto(request.getUsername(), request.getPassword()), language);
    }

    /**
     * Get information about the logged-in user
     * @param principal Principal of the asking user
     * @return Use information
     */
    @GetMapping("/me")
    public UserResponse getMe(Principal principal) {
        return authenticationService.getMe(principal);
    }
}
