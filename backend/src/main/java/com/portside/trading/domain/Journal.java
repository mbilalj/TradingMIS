package com.portside.trading.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_journal", indexes = {@Index(columnList = "sourceType,sourceNo"), @Index(columnList = "journalDate")})
@Getter @Setter @NoArgsConstructor
public class Journal {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private LocalDate journalDate;
    @Column(nullable = false, length = 255)
    private String narration;
    @Column(nullable = false, length = 32)
    private String sourceType;
    @Column(nullable = false, length = 48)
    private String sourceNo;
    @OneToMany(mappedBy = "journal", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<JournalLine> lines = new ArrayList<>();
}
