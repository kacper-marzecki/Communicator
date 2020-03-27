package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.friends.FriendshipEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Friendship repository
 */
public interface FriendshipRepository extends JpaRepository<FriendshipEntity, Integer> {
    /**
     * Find all firendships that match requester or the targeter
     * @param requester requester of the friendship
     * @param target target of the friendship
     * @return List of friendships
     */
    List<FriendshipEntity> findAllByRequesterEqualsOrTargetEquals(String requester,String target);

    /**
     * Checks if a friendship that matches the requester and target exists
     * @param requester requester of the friendship
     * @param target target of the friendship
     * @return if such friendship exists
     */
    boolean existsByRequesterEqualsAndTargetEquals(String requester, String target);
}
