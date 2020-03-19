package com.kmarzecki.communicator.api.auth;

import com.kmarzecki.communicator.model.auth.LoginDto;
import com.kmarzecki.communicator.model.auth.LoginResponse;
import com.kmarzecki.communicator.model.auth.RegisterDto;
import com.kmarzecki.communicator.model.auth.UserResponse;
import com.kmarzecki.communicator.security.AuthService;
import lombok.AllArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;


@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:3000",allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/login")
    public LoginResponse login(@RequestBody @Validated
                                       LoginRequest request) {
        return authService.login(new LoginDto(request.getUsername(), request.getPassword()));
    }

    @PostMapping("/register")
    public void register(@RequestBody RegisterRequest request) {
        authService.register(new RegisterDto(request.getUsername(), request.getPassword()));
    }

    @GetMapping("/me")
    public UserResponse getMe(Principal principal) {
        return authService.getMe(principal);
    }
}
