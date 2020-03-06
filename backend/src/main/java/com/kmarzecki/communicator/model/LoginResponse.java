package com.kmarzecki.communicator.model;

import lombok.Value;

@Value
public class LoginResponse {
    String username;
    String token;
}
