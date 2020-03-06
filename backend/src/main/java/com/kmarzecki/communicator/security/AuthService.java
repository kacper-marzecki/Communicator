package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.model.LoginDto;
import com.kmarzecki.communicator.model.LoginResponse;
import com.kmarzecki.communicator.model.RegisterDto;

public interface AuthService {
    LoginResponse login(LoginDto dto);

    void register(RegisterDto registerDto);
}
