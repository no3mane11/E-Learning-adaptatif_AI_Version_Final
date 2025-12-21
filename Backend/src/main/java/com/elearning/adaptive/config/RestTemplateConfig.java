package com.elearning.adaptive.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class RestTemplateConfig {

    /**
     * Déclare RestTemplate en tant que Bean Spring.
     * Cela permet de l'injecter n'est n'importe quel service (@Service).
     */
    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }
}