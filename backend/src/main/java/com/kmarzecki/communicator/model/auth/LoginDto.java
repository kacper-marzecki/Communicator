package com.kmarzecki.communicator.model.auth;

import lombok.Value;

@Value
public class LoginDto {
    String username;
    String password;
}
