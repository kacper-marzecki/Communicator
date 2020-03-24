package com.kmarzecki.communicator.security;


import com.kmarzecki.communicator.model.auth.RegisterDto;
import com.kmarzecki.communicator.model.auth.UserEntity;
import com.kmarzecki.communicator.repository.RoleRepository;
import com.kmarzecki.communicator.repository.UserRepository;
import lombok.AllArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

import static com.kmarzecki.communicator.util.CollectionUtils.asSet;
import static com.kmarzecki.communicator.util.CollectionUtils.mapList;

/**
 * User details service implementation
 */
@Service
@AllArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService  {
    private final UserRepository userRepository;
    private final RoleRepository roleRepository;

    /** Check if user exists
     * @param username user username
     * @return whether a user exists
     */
    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    /**
     * Save a user
     * @param dto registration data
     */
    public void saveUser(RegisterDto dto) {
        UserEntity user = UserEntity.builder()
                .password(new BCryptPasswordEncoder().encode(dto.getPassword()))
                .username(dto.getUsername())
                .roles(asSet(roleRepository.findByName("USER_ROLE")))
                .build();
        userRepository.save(user);
    }

    /**
     * Load user by username
     * @param username username
     * @return User details
     * @throws UsernameNotFoundException
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        UserEntity user = userRepository.findByUsername(username);
        if (user != null) {
            List<GrantedAuthority> authorities = mapList(
                    role -> new SimpleGrantedAuthority(role.getName()),
                    user.getRoles()
            );
            return new User(user.getUsername(), user.getPassword(), authorities);
        } else {
            throw new UsernameNotFoundException("Not found");
        }
    }
}
