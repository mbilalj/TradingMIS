package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * A payment out of cash/bank. nature decides whether it reaches the P&L (OPERATING) or only reduces
 * cash/bank (NON_OPERATING).
 */
@Entity
@Table(name = "mis_expense")
@Getter @Setter @NoArgsConstructor
public class Expense {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String expenseNo;
    @Column(nullable = false)
    private LocalDate expenseDate;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private ExpenseNature nature;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private ExpenseCategory category;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private CashAccount account;
    @Column(length = 32)
    private String method;
    /** Only for NON_OPERATING payments tied to a specific shipment (e.g. customs duty). */
    @ManyToOne(fetch = FetchType.EAGER)
    private Shipment shipment;
    @Column(length = 500)
    private String description;
    private String createdBy;
    private LocalDateTime createdAt;
}
