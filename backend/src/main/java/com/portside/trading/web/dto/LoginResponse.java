package com.portside.trading.web.dto;

public record LoginResponse(String token, String username, String fullName, String role) {
}
