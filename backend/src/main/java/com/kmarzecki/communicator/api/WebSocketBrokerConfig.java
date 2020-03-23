package com.kmarzecki.communicator.api;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Web socket broker configuration
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketBrokerConfig implements WebSocketMessageBrokerConfigurer {

    /**
     * Configuration method called by Spring
     * Enables a broker for a destination to which a client can subscribe
     * Sets a prefix to which clients can send messages to
     * @param config MessageBrokerRegistry object
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic/");
        config.setApplicationDestinationPrefixes("/app");
    }

    /**
     * Configuration method called by Spring
     * Adds a STOMP endpoint to which clients can connect
     * @param registry StompEndpointRegistry object
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws_endpoint")
                .setAllowedOrigins("*")
                .withSockJS();
    }
}