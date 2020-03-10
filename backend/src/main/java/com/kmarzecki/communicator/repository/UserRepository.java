package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Set;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, Integer> {
    boolean existsByUsername(String username);
    UserEntity findByUsername(String username);
    Set<UserEntity> findAllByUsernameIn(Set<String> usernames);
}
