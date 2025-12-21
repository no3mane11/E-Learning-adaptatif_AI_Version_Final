package com.elearning.adaptive.dto;

import lombok.*;

import java.util.List;

@Getter
@Setter
public class CreateQuizRequest {
    private String question;
    private List<String> choices;
    private Integer correctAnswer;
}
