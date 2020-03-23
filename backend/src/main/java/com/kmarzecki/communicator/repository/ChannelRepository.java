package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.conversation.ChannelEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Set;

/**
 * Conversation channel repository
 */
public interface ChannelRepository extends JpaRepository<ChannelEntity, Integer> {
    /**
     * Find all channels containing a user with given username
     * @param username username of the user
     * @return List of channels
     */
    List<ChannelEntity> findAllByUsers_Username(String username);

    /**
     * Check if a channel with name and users with specified usernames exists
     * @param name name of the channel
     * @param usernames set of user usernames
     * @return if channel exists
     */
    boolean existsByNameAndUsers_UsernameIn(String name, Set<String> usernames);
}
