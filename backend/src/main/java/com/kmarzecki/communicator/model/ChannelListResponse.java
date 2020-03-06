package com.kmarzecki.communicator.model;

import lombok.Builder;
import lombok.Value;

import java.util.List;
import java.util.Set;

@Value
@Builder
public class ChannelListResponse {
    Integer id;
    String name;
    List<String> users;
    boolean oneOnOne;
}
