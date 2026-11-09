package com.portside.trading.security;

import com.portside.trading.domain.Role;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

/** Reads the authenticated user's identity/role out of the JWT-derived SecurityContext. */
@Service
public class CurrentUserService {

    public String username() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth == null ? null : auth.getName();
    }

    public Role role() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) return null;
        return auth.getAuthorities().stream()
                .map(a -> a.getAuthority().replaceFirst("^ROLE_", ""))
                .map(Role::valueOf)
                .findFirst()
                .orElse(null);
    }
}
