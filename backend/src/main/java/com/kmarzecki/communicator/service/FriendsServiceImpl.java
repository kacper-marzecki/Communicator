package com.kmarzecki.communicator.service;

import com.kmarzecki.communicator.exception.OperationNotPermittedException;
import com.kmarzecki.communicator.model.Language;
import com.kmarzecki.communicator.model.friends.FriendshipEntity;
import com.kmarzecki.communicator.model.friends.FriendshipResponse;
import com.kmarzecki.communicator.repository.FriendshipRepository;
import com.kmarzecki.communicator.security.UserDetailsServiceImpl;
import lombok.AllArgsConstructor;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.Principal;

import static com.kmarzecki.communicator.util.InternationalizationUtil.*;
import static com.kmarzecki.communicator.util.MessageUtils.*;

@Service
@AllArgsConstructor
class FriendsServiceImpl implements FriendsService {
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
    public void addFriend(String requester, String target, Language language) {
        if (!userService.existsByUsername(target)) {
            sendError(messagingTemplate, requester, cannotFindRequestedUsers(language));
            return;
        }
        if (isFriendOrInProgress(target, requester)
                || isFriendOrInProgress(requester, target)) {
            sendError(messagingTemplate, requester, alreadyAFriendOrInProgress(language));
            return;
        }
        if (requester.equals(target)) {
            sendError(messagingTemplate, requester, cannotBeYourOwnFriend(language));
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
    public void processFriendshipRequest(Integer requestId, boolean accept, Principal principal, Language language) {
        if (accept) {
            acceptFriendshipRequest(principal, requestId, language);
        } else {
            declineFriendshipRequest(principal, requestId, language);
        }
    }

    private void declineFriendshipRequest(Principal principal, Integer id, Language language) {
        FriendshipEntity request = getFriendShipRequestOrThrow(id, language);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException(cannotRespondToSomeoneElsesRequest(language));
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

    private FriendshipEntity getFriendShipRequestOrThrow(Integer requestId, Language language) {
        return friendshipRepository.findById(requestId)
                .orElseThrow(() -> new OperationNotPermittedException(cannotFindRequestedRequest(language)));
    }

    private void acceptFriendshipRequest(Principal principal, Integer requestId, Language language) {
        FriendshipEntity request = getFriendShipRequestOrThrow(requestId, language);
        if (!principal.getName().equals(request.getTarget())) {
            throw new OperationNotPermittedException(cannotRespondToSomeoneElsesRequest(language));
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