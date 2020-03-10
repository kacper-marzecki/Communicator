package com.kmarzecki.communicator.security;


import com.kmarzecki.communicator.model.RegisterDto;
import com.kmarzecki.communicator.model.UserEntity;
import com.kmarzecki.communicator.repository.RoleRepository;
import com.kmarzecki.communicator.repository.UserRepository;
import lombok.AllArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
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

@Service
@AllArgsConstructor(onConstructor = @__(@Autowired))
public class CustomUserDetailsService implements UserDetailsService  {
    private UserRepository userRepository;
    private RoleRepository roleRepository;

    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    public void saveUser(RegisterDto dto) {
        var user = UserEntity.builder()
                .password(new BCryptPasswordEncoder().encode(dto.getPassword()))
                .username(dto.getUsername())
                .roles(asSet(roleRepository.findByRole("ADMIN")))
                .build();
        userRepository.save(user);
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        UserEntity user = userRepository.findByUsername(username);
        if (user != null) {
            List<GrantedAuthority> authorities = mapList(
                    role -> new SimpleGrantedAuthority(role.getRole()), user.getRoles()
            );
            return new User(user.getUsername(), user.getPassword(), authorities);
        } else {
            throw new UsernameNotFoundException("Not found");
        }
    }
}
