package com.kmarzecki.communicator.model;

import lombok.*;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;

@Entity
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FriendshipEntity {
    @Id
    @GeneratedValue
    private Integer id;
    private String requester;
    private String target;
    private boolean pending;
}
