package com.campusrunner.backend;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * 鍚庣鏈嶅姟鍚姩鍏ュ彛銆? * 妗嗘灦浼氫粠褰撳墠鍖呭紑濮嬭繘琛岀粍浠舵壂鎻忋€? */
@SpringBootApplication
@EnableScheduling
@MapperScan({
        "com.campusrunner.backend.admin.dao",
        "com.campusrunner.backend.conversation.dao",
        "com.campusrunner.backend.order.dao",
        "com.campusrunner.backend.social.dao",
        "com.campusrunner.backend.user.dao"})
public class BackendApplication {

	public static void main(String[] args) {
		// Start the embedded server and bootstrap the application context.
		SpringApplication.run(BackendApplication.class, args);
	}
}

