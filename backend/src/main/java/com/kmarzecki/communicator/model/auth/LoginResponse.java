package com.kmarzecki.communicator.model.auth;

import lombok.Value;

@Value
public class LoginResponse {
    String username;
    String token;
}
