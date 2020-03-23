package com.kmarzecki.communicator.exception;

import lombok.Getter;

import java.util.Optional;

/**
 * Exception indicating that user attempted an operation which is not permitted
 */
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

    public OperationNotPermittedException() {
        super();
    }
}
