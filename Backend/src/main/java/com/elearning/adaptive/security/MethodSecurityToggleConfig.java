package com.elearning.adaptive.security;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@Configuration
@ConditionalOnProperty(prefix = "app.jwt", name = "enabled", havingValue = "true", matchIfMissing = true)
@EnableMethodSecurity(prePostEnabled = true, securedEnabled = true)
public class MethodSecurityToggleConfig {
    // empty - presence of this config enables method security; absence disables it
}
