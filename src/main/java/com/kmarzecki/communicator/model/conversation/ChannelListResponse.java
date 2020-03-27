package com.kmarzecki.communicator.model.conversation;

import lombok.Builder;
import lombok.Value;

import java.util.List;

@Value
@Builder
public class ChannelListResponse {
    Integer id;
    String name;
    List<String> users;
    Long createTime;
}
