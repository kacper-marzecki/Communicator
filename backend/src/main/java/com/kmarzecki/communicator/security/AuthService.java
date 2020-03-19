package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.model.auth.UserResponse;
import com.kmarzecki.communicator.model.auth.LoginDto;
import com.kmarzecki.communicator.model.auth.LoginResponse;
import com.kmarzecki.communicator.model.auth.RegisterDto;

import java.security.Principal;

public interface AuthService {
    LoginResponse login(LoginDto dto);

    void register(RegisterDto registerDto);

    UserResponse getMe(Principal principal);
}
