package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.auth.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Set;

/**
 * User repository
 */
@Repository
public interface UserRepository extends JpaRepository<UserEntity, Integer> {
    /**
     * Check if a user with username exists
     * @param username user username
     * @return whether a user exists
     */
    boolean existsByUsername(String username);

    /**
     * Find user bu username
     * @param username user username
     * @return User
     */
    UserEntity findByUsername(String username);

    /**
     * Find all users with usernames
     * @param usernames usernames
     * @return Set of users
     */
    Set<UserEntity> findAllByUsernameIn(Set<String> usernames);
}
