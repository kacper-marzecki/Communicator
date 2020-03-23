package com.kmarzecki.communicator.security;

import com.kmarzecki.communicator.model.auth.Role;
import com.kmarzecki.communicator.util.DateTimeProvider;
import io.jsonwebtoken.*;
import lombok.AllArgsConstructor;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.servlet.http.HttpServletRequest;
import java.util.Base64;
import java.util.Date;
import java.util.Objects;
import java.util.Set;

@Component
@AllArgsConstructor
public class JwtTokenService {
    private static final String ROLES = "BASIC_ROLE";
    private static final String SECRET_KEY = "NON_SAFE_SECRET";
    private static final String ENCODED_SECRET_KEY = Base64.getEncoder().encodeToString(SECRET_KEY.getBytes());
    private static final String TOKEN_HEADER_NAME = "token";
    private static final int VALID_TIME_MS = 3600000;
    private final UserDetailsServiceImpl userDetailsService;
    private final DateTimeProvider dateProvider;

    public String createToken(String username, Set<Role> set) {
        Claims claims = Jwts.claims().setSubject(username);
        claims.put(ROLES, set);
        Date now = dateProvider.currentDate();
        Date validity = new Date(now.getTime() + VALID_TIME_MS);
        return Jwts.builder()
                .setClaims(claims)
                .setIssuedAt(now)
                .setExpiration(validity)
                .signWith(SignatureAlgorithm.HS256, ENCODED_SECRET_KEY)
                .compact();
    }

    public Authentication getAuthentication(String token) {
        UserDetails userDetails = userDetailsService.loadUserByUsername(getUsername(token));
        return new UsernamePasswordAuthenticationToken(userDetails, "", userDetails.getAuthorities());
    }

    public String getUsername(String token) {
        return Jwts.parser().setSigningKey(ENCODED_SECRET_KEY).parseClaimsJws(token).getBody().getSubject();
    }

    public String extractToken(HttpServletRequest req) {
        return req.getHeader(TOKEN_HEADER_NAME);
    }

    public String extractToken(StompHeaderAccessor accessor) {
        return Objects.requireNonNull(accessor.getNativeHeader(TOKEN_HEADER_NAME)).get(0);
    }

    public boolean validateToken(String token) {
        try {
            Jws<Claims> claims = Jwts.parser().setSigningKey(ENCODED_SECRET_KEY).parseClaimsJws(token);
            return !claims.getBody().getExpiration().before(new Date());
        } catch (JwtException | IllegalArgumentException e) {
            throw new JwtException("Expired or invalid JWT token");
        }
    }
}
