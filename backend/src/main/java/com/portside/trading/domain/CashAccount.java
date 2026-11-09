package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_account")
@Getter @Setter @NoArgsConstructor
public class CashAccount {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 128)
    private String name;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 8)
    private AccountType type;
    @Column(length = 64)
    private String accountNumber;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal openingBalance = BigDecimal.ZERO;
    @Column(unique = true, length = 16)
    private String headCode;
    @Column(nullable = false)
    private boolean active = true;
}
