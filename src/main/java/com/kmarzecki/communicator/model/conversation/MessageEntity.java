package com.kmarzecki.communicator.model.conversation;

import com.kmarzecki.communicator.model.auth.UserEntity;
import lombok.*;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import java.time.LocalDateTime;

/**
 * Entity representing a sent message
 */
@AllArgsConstructor
@Setter
@Getter
@Builder
@NoArgsConstructor
@Entity
public class MessageEntity {
    /**
     * Message id
     */
    @Id
    @GeneratedValue
    private Integer id;
    /**
     * Id of a conversation channel this message has been sent to
     */
    private Integer channelId;
    /**
     * Message payload
     */
    private String payload;
    /**
     * User that sent the message
     */
    @ManyToOne
    private UserEntity user;
    /**
     * Time at which the message has been sent
     */
    private LocalDateTime time;
}
