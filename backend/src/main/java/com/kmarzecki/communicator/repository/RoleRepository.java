package com.kmarzecki.communicator.repository;

import com.kmarzecki.communicator.model.auth.Role;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoleRepository extends JpaRepository<Role, Integer> {
    Role findByRole(String admin);
}
