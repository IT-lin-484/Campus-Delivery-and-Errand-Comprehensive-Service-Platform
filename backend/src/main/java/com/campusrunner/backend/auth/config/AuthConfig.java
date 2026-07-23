package com.campusrunner.backend.auth.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.ArrayList;

/**
 * 璁よ瘉妯″潡鍩虹閰嶇疆銆?
 */
@Configuration
public class AuthConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt keeps passwords hashed instead of storing plain text.
        return new BCryptPasswordEncoder();
    }
}


