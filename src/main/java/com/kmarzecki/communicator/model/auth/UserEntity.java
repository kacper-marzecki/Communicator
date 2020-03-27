package com.kmarzecki.communicator.model.auth;


import lombok.*;

import javax.persistence.*;
import java.util.Set;


/**
 * Entity representing the user
 */
@Entity
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserEntity {
    /**
     * User id
     */
    @Id
    @GeneratedValue
    private Integer id;
    /**
     * User username
     */
    private String username;
    /**
     * User password digest
     */
    private String password;
    /**
     * User roles
     */
    @ManyToMany(fetch = FetchType.EAGER)
    private Set<Role> roles;
}
