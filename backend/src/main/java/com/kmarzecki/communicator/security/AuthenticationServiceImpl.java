package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.auth.LoginDto;
import com.kmarzecki.communicator.model.auth.LoginResponse;
import com.kmarzecki.communicator.model.auth.RegisterDto;
import com.kmarzecki.communicator.model.auth.UserResponse;
import com.kmarzecki.communicator.repository.UserRepository;
import lombok.AllArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

import java.security.Principal;

@Service
@AllArgsConstructor
public class AuthenticationServiceImpl implements AuthenticationService {
    private final UserRepository userRepository;
    private final JwtTokenService jwtTokenService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsServiceImpl userService;

    @Override
    public LoginResponse login(LoginDto dto) {
        String username = dto.getUsername();
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(username, dto.getPassword())
        );
        String token = jwtTokenService.createToken(username, userRepository.findByUsername(username).getRoles());
        return new LoginResponse(username, token);
    }

    @Override
    public void register(RegisterDto dto) {
        if (userService.existsByUsername(dto.getUsername())) {
            throw new OperationNotPermittedException("User: " + dto.getUsername() + " exists");
        }
        userService.saveUser(dto);
    }

    @Override
    public UserResponse getMe(Principal principal) {
        return new UserResponse(principal.getName());
    }
}
