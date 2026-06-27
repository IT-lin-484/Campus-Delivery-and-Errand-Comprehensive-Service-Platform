package com.campusrunner.backend.auth.jwt;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import com.auth0.jwt.JWT;
import com.auth0.jwt.JWTVerifier;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.campusrunner.backend.user.entity.User;

/**
 * JWT token provider.
 */
@Component
public class JwtTokenProvider {

    private final long expireHours;
    private final Algorithm algorithm;
    private final JWTVerifier verifier;

    public JwtTokenProvider(
            @Value("${app.auth.jwt-secret}") String secret,
            @Value("${app.auth.jwt-expire-hours:72}") long expireHours) {
        this.expireHours = expireHours;
        this.algorithm = Algorithm.HMAC256(secret);
        this.verifier = JWT.require(this.algorithm).build();
    }

    public String createToken(User user) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(expireHours, ChronoUnit.HOURS);

        return JWT.create()
                .withSubject(String.valueOf(user.getId()))
                .withClaim("username", user.getUsername())
                .withClaim("role", user.getRole().name())
                .withIssuedAt(Date.from(now))
                .withExpiresAt(Date.from(expiresAt))
                .sign(algorithm);
    }

    public long getExpiresInSeconds() {
        return expireHours * 3600;
    }

    public Long parseUserId(String token) {
        try {
            DecodedJWT jwt = verifier.verify(token);
            return Long.parseLong(jwt.getSubject());
        } catch (JWTVerificationException | NumberFormatException exception) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "登录状态无效或已过期");
        }
    }
}
