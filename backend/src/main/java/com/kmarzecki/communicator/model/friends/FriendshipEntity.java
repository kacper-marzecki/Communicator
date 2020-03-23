package com.kmarzecki.communicator.model.friends;

import lombok.*;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

/**
 * Entity representing a friendship connection between users
 */
@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FriendshipEntity {
    /**
     * Friendship id
     */
    @Id
    @GeneratedValue
    private Integer id;
    /**
     * User that initiated the friendship
     */
    private String requester;
    /**
     * The second user in the friendship
     */
    private String target;
    /**
     * Flag indicating that this friendship is one sided, and not yet confirmed
     */
    private boolean pending;
}
