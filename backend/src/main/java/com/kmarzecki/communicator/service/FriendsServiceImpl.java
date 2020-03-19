package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.friends.FriendshipEntity;
import com.kmarzecki.communicator.model.friends.FriendshipResponse;
import com.kmarzecki.communicator.repository.FriendshipRepository;
import com.kmarzecki.communicator.security.CustomUserDetailsService;
import lombok.AllArgsConstructor;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;
import java.util.List;
import java.util.stream.Collectors;

import static com.kmarzecki.communicator.util.MessageUtils.*;

@Service
@AllArgsConstructor
class FriendsServiceImpl implements FriendsService {
    private final FriendshipRepository friendshipRepository;
    private final CustomUserDetailsService userService;
    private final SimpMessageSendingOperations messagingTemplate;


    @Override
    public List<FriendshipResponse> getFriendsFor(Principal principal) {
        String user = principal.getName();
        return friendshipRepository.findAllByRequesterEqualsOrTargetEquals(user, user)
                .stream()
                .map(this::map)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void addFriend(String requester, String target) {
        if (!userService.existsByUsername(target)) {
            sendError(messagingTemplate, requester, "Such user does not exist");
            return;
        }
        if (isFriendOrInProgress(target, requester)
                || isFriendOrInProgress(requester, target)) {
            sendError(messagingTemplate, requester, "Already a friend or in progress of becoming one");
            return;
        }
        if (requester.equals(target)) {
            sendError(messagingTemplate, requester, "How would You like to be Your own best friend ? :)");
            return;
        }
        FriendshipEntity saved = friendshipRepository.save(FriendshipEntity.builder()
                .requester(requester)
                .target(target)
                .pending(true)
                .build()
        );
        sendFriendshipNotification(requester, saved);
        sendFriendshipNotification(target, saved);
    }

    @Override
    public void processFriendshipRequest(Integer id, boolean accept, Principal principal) {
        if (accept) {
            acceptFriendshipRequest(principal, id);
        } else {
            declineFriendshipRequest(principal, id);
        }
    }

    private void declineFriendshipRequest(Principal principal, Integer id) {
        FriendshipEntity request = getFriendShipRequestOrThrow(id);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException("Cannot decline someone else's request");
        }
        friendshipRepository.delete(request);
        sendFriendshipDeletedNotification(request.getId(), request.getRequester(), request.getTarget());
        sendError(messagingTemplate, request.getRequester(), request.getTarget() + " declined Your friend-request :(");
    }

    private void sendFriendshipDeletedNotification(Integer id, String... users) {
        for (String user : users) {
            messagingTemplate.convertAndSendToUser(user , DELETED_FRIENDS_TOPIC , id);
        }
    }

    private void sendFriendshipNotification(String user, FriendshipEntity entity) {
        messagingTemplate.convertAndSendToUser(user, FRIENDS_TOPIC, map(entity));
    }

    private FriendshipEntity getFriendShipRequestOrThrow(Integer id) {
        return friendshipRepository.findById(id)
                .orElseThrow(() -> new OperationNotPermittedException("No such request"));
    }

    private void acceptFriendshipRequest(Principal principal, Integer id) {
        FriendshipEntity request = getFriendShipRequestOrThrow(id);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException("Cannot Accept someone else's request");
        }
        request.setPending(false);
        friendshipRepository.save(request);
        sendFriendshipDeletedNotification(request.getId(), request.getTarget(), request.getRequester());
        sendFriendshipNotification(request.getRequester(), request);
        sendFriendshipNotification(request.getTarget(), request);
    }

    private boolean isFriendOrInProgress(String requester, String target) {
        return friendshipRepository.existsByRequesterEqualsAndTargetEquals(requester, target);
    }

    private FriendshipResponse map(FriendshipEntity it) {
        return FriendshipResponse.builder()
                .pending(it.isPending())
                .requester(it.getRequester())
                .target(it.getTarget())
                .id(it.getId())
                .build();
    }
}
