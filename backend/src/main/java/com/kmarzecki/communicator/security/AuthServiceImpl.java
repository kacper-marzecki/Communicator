package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.*;
import com.kmarzecki.communicator.repository.UserRepository;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

import static org.springframework.http.ResponseEntity.ok;

@Service
@AllArgsConstructor(onConstructor = @__(@Autowired) )
public class AuthServiceImpl implements AuthService {
    private final UserRepository userRepository;
    private CustomUserDetailsService userService;
    JwtTokenService jwtTokenService;
    AuthenticationManager authenticationManager;

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
}
