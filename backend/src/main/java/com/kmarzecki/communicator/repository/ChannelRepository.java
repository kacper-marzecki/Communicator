package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.ChannelEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Set;

public interface ChannelRepository extends JpaRepository<ChannelEntity, Integer> {
    List<ChannelEntity> findAllByUsers_Username(String username);
    boolean existsByNameAndUsers_UsernameIn(String name, Set<String> usernames);
}
