package com.kmarzecki.communicator.api;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.util.MessageUtils;
import org.springframework.beans.factory.annotation.Autowired;
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

@ControllerAdvice
public class ApiConfiguration {
    @Autowired
    private SimpMessageSendingOperations messagingTemplate;

    @ExceptionHandler({BadCredentialsException.class, AuthenticationException.class})
    public ResponseEntity<?> handleAuthentictionException(Throwable t){
        System.out.println(t.getMessage());
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }

    @ExceptionHandler(OperationNotPermittedException.class)
    public ResponseEntity<?> handleOperationNotPermittedException(OperationNotPermittedException t){
        t.getUser()
                .ifPresent(user -> MessageUtils.sendError(messagingTemplate, user, t.getMessage()));
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(t.getMessage());
    }

    @MessageMapping
    @MessageExceptionHandler
    @SendToUser("/queue/errors")
    public String handleException(Throwable exception) {
        return exception.getMessage();
    }
}
