package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_supplier_payment")
@Getter @Setter @NoArgsConstructor
public class SupplierPayment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String paymentNo;
    @Column(nullable = false)
    private LocalDate paymentDate;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Supplier supplier;
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
