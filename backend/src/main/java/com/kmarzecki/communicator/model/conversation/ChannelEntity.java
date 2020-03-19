package com.kmarzecki.communicator.model.conversation;

import com.kmarzecki.communicator.model.auth.UserEntity;
import lombok.*;

import javax.persistence.*;
import java.util.Set;

@Entity
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Builder
public class ChannelEntity {
    @Id
    @GeneratedValue
    private Integer id;
    private String name;
    private boolean oneOnOne;
    @ManyToMany(fetch = FetchType.EAGER)
    private Set<UserEntity> users;
}
