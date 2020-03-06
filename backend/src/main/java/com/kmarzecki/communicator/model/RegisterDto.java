package com.kmarzecki.communicator.model;

import lombok.Value;

@Value
public class RegisterDto {
    private String username;
    private String password;
}
