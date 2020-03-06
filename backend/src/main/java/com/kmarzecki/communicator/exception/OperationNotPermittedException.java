package com.kmarzecki.communicator.exception;

import lombok.Getter;

import java.util.Optional;

@Getter
public class OperationNotPermittedException extends RuntimeException {
    private Optional<String> user = Optional.empty();
    public OperationNotPermittedException(String message, String user) {
        super(message);
        this.user = Optional.ofNullable(user);
    }

    public OperationNotPermittedException(String message) {
        super(message);
    }
}
