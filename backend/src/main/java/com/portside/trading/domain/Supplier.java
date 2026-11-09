package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_supplier")
@Getter @Setter @NoArgsConstructor
public class Supplier {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String code;
    @Column(nullable = false, length = 200)
    private String name;
    @Column(length = 96)
    private String country;
    @Column(length = 200)
    private String contact;
    @Column(length = 255)
    private String address;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal openingBalance = BigDecimal.ZERO;
    @Column(length = 500)
    private String notes;
    @Column(nullable = false)
    private boolean active = true;
}
