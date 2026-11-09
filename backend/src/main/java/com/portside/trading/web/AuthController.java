package com.portside.trading.web;

import com.portside.trading.domain.AppUser;
import com.portside.trading.repo.AppUserRepository;
import com.portside.trading.security.JwtService;
import com.portside.trading.web.dto.LoginRequest;
import com.portside.trading.web.dto.LoginResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final AppUserRepository userRepository;
    private final JwtService jwtService;

    public AuthController(AuthenticationManager authenticationManager, AppUserRepository userRepository, JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest req) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.username(), req.password()));
        } catch (BadCredentialsException e) {
            return ResponseEntity.status(401).build();
        }
        AppUser user = userRepository.findByUsername(req.username()).orElseThrow();
        String token = jwtService.issue(user.getUsername(), user.getRole().name());
        return ResponseEntity.ok(new LoginResponse(token, user.getUsername(), user.getFullName(), user.getRole().name()));
    }

    @GetMapping("/me")
    public ResponseEntity<LoginResponse> me(org.springframework.security.core.Authentication auth) {
        if (auth == null) return ResponseEntity.status(401).build();
        AppUser user = userRepository.findByUsername(auth.getName()).orElseThrow();
        return ResponseEntity.ok(new LoginResponse(null, user.getUsername(), user.getFullName(), user.getRole().name()));
    }
}
