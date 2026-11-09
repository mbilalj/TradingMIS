package com.portside.trading.domain;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_expense_category")
@Getter @Setter @NoArgsConstructor
public class ExpenseCategory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 96)
    private String name;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private ExpenseNature nature;
    @Column(unique = true, length = 16)
    private String headCode;
    @Column(nullable = false)
    private boolean active = true;
}
