package com.kmarzecki.communicator.model.auth;

import lombok.Value;

@Value
public class RegisterDto {
    String username;
    String password;
}
