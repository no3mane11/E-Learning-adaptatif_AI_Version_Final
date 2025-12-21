package com.elearning.adaptive.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.Instant;
import java.util.UUID;
import jakarta.validation.constraints.*;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class FrustrationMetricDTO {

    @NotNull(message = "L'ID de session ne peut pas être nul.")
    private UUID sessionId;

    @NotNull(message = "Le score de frustration ne peut pas être nul.")
    @Min(value = 0, message = "Le score minimal est 0.0")
    @Max(value = 1, message = "Le score maximal est 1.0")
    private Double score;

    @NotNull(message = "L'horodatage ne peut pas être nul.")
    // Accepte les formats ISO de Flutter (microsecondes + fuseau horaire)
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS[X]", timezone = "UTC")
    private Instant timestamp;
}