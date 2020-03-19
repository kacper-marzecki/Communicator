package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.friends.FriendshipEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FriendshipRepository extends JpaRepository<FriendshipEntity, Integer> {
    List<FriendshipEntity> findAllByRequesterEqualsOrTargetEquals(String requester,String target);
    boolean existsByRequesterEqualsAndTargetEquals(String requester, String target);
}
