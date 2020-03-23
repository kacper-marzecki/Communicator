package com.kmarzecki.communicator.model.auth;

import lombok.Getter;
import lombok.Setter;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

/**
 * Entity representing user role
 */
@Entity
@Getter
@Setter
public class Role {
    /**
     * Role id
     */
    @Id
    @GeneratedValue
    private String id;
    /**
     * Role name
     */
    private String name;
}

