package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.model.ChannelListResponse;

import java.security.Principal;
import java.util.List;

public interface ConversationService {

    List<ChannelListResponse> getUserChannels(Principal principal);
}
