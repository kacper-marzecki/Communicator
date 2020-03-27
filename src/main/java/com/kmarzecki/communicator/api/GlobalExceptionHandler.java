package com.kmarzecki.communicator.api;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.util.MessageUtils;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageExceptionHandler;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

/**
 * Global exception handler
 */
@ControllerAdvice
@AllArgsConstructor
public class GlobalExceptionHandler {
    private final SimpMessageSendingOperations messagingTemplate;

    /**
     * Handler for exceptions related to authentication
     * @param t Thrown exception
     * @return Error response
     */
    @ExceptionHandler({BadCredentialsException.class, AuthenticationException.class})
    public ResponseEntity<?> handleAuthenticationException(Throwable t){
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }

    /**
     * Handler for exceptions related to forbidden operations attempted by a user
     * @param t Thrown exception
     * @return Error Response
     */
    @ExceptionHandler(OperationNotPermittedException.class)
    public ResponseEntity<?> handleOperationNotPermittedException(OperationNotPermittedException t){
        t.getUser()
                .ifPresent(user -> MessageUtils.sendError(messagingTemplate, user, t.getMessage()));
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(t.getMessage());
    }


    /**
     * Handler for exceptions thrown during handling by a message-handling code
     * @param t Thrown exception
     * @return Message string
     */
    @MessageMapping
    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Throwable t) {
        return t.getMessage();
    }
}
