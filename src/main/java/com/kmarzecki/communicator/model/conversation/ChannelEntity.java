package com.kmarzecki.communicator.model.conversation;

import com.kmarzecki.communicator.model.auth.UserEntity;
import lombok.*;

import javax.persistence.*;
import java.util.Set;

/**
 * Entity representing a conversation channel
 */
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class ChannelEntity {
    /**
     * Channel Id
     */
    @Id
    @GeneratedValue
    private Integer id;
    /**
     * Channel name
     */
    private String name;
    /**
     * Users in the conversation channel
     */
    @ManyToMany(fetch = FetchType.EAGER)
    private Set<UserEntity> users;
}
