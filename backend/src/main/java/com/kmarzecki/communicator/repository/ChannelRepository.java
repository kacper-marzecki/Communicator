package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.ChannelEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChannelRepository extends JpaRepository<ChannelEntity, Integer> {
    List<ChannelEntity> findAllByUsers_Username(String username);
}
