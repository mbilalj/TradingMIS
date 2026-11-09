package com.portside.trading.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_sequence")
@Getter @Setter @NoArgsConstructor
public class DocSequence {
    @Id @Column(length = 24)
    private String name;
    @Column(nullable = false)
    private long nextVal = 1;

    public DocSequence(String name) {
        this.name = name;
    }
}
