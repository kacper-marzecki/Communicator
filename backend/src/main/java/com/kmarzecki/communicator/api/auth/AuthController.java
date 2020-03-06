package com.kmarzecki.communicator.api.auth;

import com.kmarzecki.communicator.model.*;
import com.kmarzecki.communicator.security.AuthService;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;

import static org.springframework.http.ResponseEntity.ok;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "http://localhost:3000",allowCredentials = "true", allowedHeaders = "*")
@AllArgsConstructor(onConstructor = @__(@Autowired))
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
        return new UserResponse(principal.getName());
    }

    // TODO sign out api
}
