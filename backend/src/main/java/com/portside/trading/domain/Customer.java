package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_customer")
@Getter @Setter @NoArgsConstructor
public class Customer {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String code;
    @Column(nullable = false, length = 200)
    private String name;
    @Column(length = 64)
    private String phone;
    @Column(length = 255)
    private String address;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal openingBalance = BigDecimal.ZERO;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private SaleType type = SaleType.RETAIL;
    /** 0 = no limit. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal creditLimit = BigDecimal.ZERO;
    /** Days after invoice date before an unpaid invoice is overdue. */
    @Column(nullable = false)
    private int creditDays = 30;
    @Column(length = 500)
    private String notes;
    @Column(nullable = false)
    private boolean active = true;
    /** The built-in cash-sale customer; cannot buy on credit. */
    @Column(nullable = false)
    private boolean walkIn = false;
}
