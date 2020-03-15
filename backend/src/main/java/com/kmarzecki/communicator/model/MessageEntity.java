package com.kmarzecki.communicator.model;

import lombok.*;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.ManyToOne;
import java.time.LocalDateTime;

@AllArgsConstructor
@Setter
@Getter
@Builder
@NoArgsConstructor
@Entity
public class MessageEntity {
    @Id
    @GeneratedValue
    private Integer id;
    private Integer channelId;
    private String payload;
    @ManyToOne
    private UserEntity user;
    private LocalDateTime time;
}
