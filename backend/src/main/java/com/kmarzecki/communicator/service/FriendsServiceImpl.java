package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.friends.FriendshipEntity;
import com.kmarzecki.communicator.model.friends.FriendshipResponse;
import com.kmarzecki.communicator.repository.FriendshipRepository;
import com.kmarzecki.communicator.security.UserDetailsServiceImpl;
import lombok.AllArgsConstructor;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;

import static com.kmarzecki.communicator.util.MessageUtils.*;

@Service
@AllArgsConstructor
class FriendsServiceImpl implements FriendsService {
    private static final String CANNOT_RESPOND_TO_NOT_OWNED_REQUEST_ERROR = "Cannot respond to someone else's request";
    private static final String USER_DOESNT_EXIST_ERROR = "Such user does not exist";
    private static final String REQUEST_DOESNT_EXIST_ERROR = "Such request does not exist";
    private final FriendshipRepository friendshipRepository;
    private final UserDetailsServiceImpl userService;
    private final SimpMessageSendingOperations messagingTemplate;

    @Override
    public void getFriendsFor(Principal principal) {
        String user = principal.getName();
        friendshipRepository.findAllByRequesterEqualsOrTargetEquals(user, user)
                .stream()
                .map(this::map)
                .forEach(f -> messagingTemplate.convertAndSendToUser(
                        principal.getName(),
                        FRIENDS_TOPIC,
                        f));
    }

    @Override
    @Transactional
    public void addFriend(String requester, String target) {
        if (!userService.existsByUsername(target)) {
            sendError(messagingTemplate, requester, USER_DOESNT_EXIST_ERROR);
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
    public void processFriendshipRequest(Integer requestId, boolean accept, Principal principal) {
        if (accept) {
            acceptFriendshipRequest(principal, requestId);
        } else {
            declineFriendshipRequest(principal, requestId);
        }
    }

    private void declineFriendshipRequest(Principal principal, Integer id) {
        FriendshipEntity request = getFriendShipRequestOrThrow(id);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException(CANNOT_RESPOND_TO_NOT_OWNED_REQUEST_ERROR);
        }
        friendshipRepository.delete(request);
        sendFriendshipDeletedNotification(request.getId(), request.getRequester(), request.getTarget());
        sendError(messagingTemplate, request.getRequester(), request.getTarget() + " declined Your friend-request :(");
    }

    private void sendFriendshipDeletedNotification(Integer id, String... users) {
        for (String user : users) {
            messagingTemplate.convertAndSendToUser(user, DELETED_FRIENDS_TOPIC, id);
        }
    }

    private void sendFriendshipNotification(String user, FriendshipEntity entity) {
        messagingTemplate.convertAndSendToUser(user, FRIENDS_TOPIC, map(entity));
    }

    private FriendshipEntity getFriendShipRequestOrThrow(Integer requestId) {
        return friendshipRepository.findById(requestId)
                .orElseThrow(() -> new OperationNotPermittedException(REQUEST_DOESNT_EXIST_ERROR));
    }

    private void acceptFriendshipRequest(Principal principal, Integer requestId) {
        FriendshipEntity request = getFriendShipRequestOrThrow(requestId);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException(CANNOT_RESPOND_TO_NOT_OWNED_REQUEST_ERROR);
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