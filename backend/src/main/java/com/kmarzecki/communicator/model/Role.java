package com.kmarzecki.communicator.model;

import lombok.Getter;
import lombok.Setter;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

@Entity
@Getter
@Setter
public class Role {
    @Id
    @GeneratedValue
    private String id;
    private String role;
}

