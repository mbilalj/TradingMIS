package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Payment received from a customer against their running balance. */
@Entity
@Table(name = "mis_receipt")
@Getter @Setter @NoArgsConstructor
public class Receipt {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String receiptNo;
    @Column(nullable = false)
    private LocalDate receiptDate;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Customer customer;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    @Column(length = 32)
    private String method;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private CashAccount account;
    @Column(length = 96)
    private String reference;
    @Column(length = 500)
    private String notes;
    private String createdBy;
    private LocalDateTime createdAt;
}
