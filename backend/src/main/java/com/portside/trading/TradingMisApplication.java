package com.portside.trading;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
// The post-arrival repositories are grouped as nested interfaces in Repos.
@EnableJpaRepositories(considerNestedRepositories = true)
public class TradingMisApplication {

	public static void main(String[] args) {
		SpringApplication.run(TradingMisApplication.class, args);
	}

}
