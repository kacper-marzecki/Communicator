package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.conversation.MessageEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface MessageRepository extends JpaRepository<MessageEntity, Integer> {
    List<MessageEntity> findAllByChannelId(Integer channelId, Pageable pageable);
    List<MessageEntity> findAllByChannelIdAndTimeBefore(Integer channelId, LocalDateTime time, Pageable pageable);
}
