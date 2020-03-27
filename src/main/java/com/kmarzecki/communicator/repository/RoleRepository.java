package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.auth.Role;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Role repository
 */
public interface RoleRepository extends JpaRepository<Role, Integer> {
    /**
     * find role by name
     * @param roleName role name
     * @return Role
     */
    Role findByName(String roleName);
}
