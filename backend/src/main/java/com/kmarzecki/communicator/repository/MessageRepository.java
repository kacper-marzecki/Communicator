package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.conversation.MessageEntity;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Message repository
 */
public interface MessageRepository extends JpaRepository<MessageEntity, Integer> {
    /**
     * Find paginated messages in a channel
     * @param channelId id of the channel
     * @param pageable pagination information
     * @return list of messages
     */
    List<MessageEntity> findAllByChannelId(Integer channelId, Pageable pageable);

    /**
     * Find paginated messages in a channel sent before a specified time
     * @param channelId id of the channel
     * @param time time before they are sent
     * @param pageable pagination information
     * @return list of messages
     */
    List<MessageEntity> findAllByChannelIdAndTimeBefore(Integer channelId, LocalDateTime time, Pageable pageable);
}
