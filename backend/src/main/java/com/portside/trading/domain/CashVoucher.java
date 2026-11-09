package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_cash_voucher")
@Getter @Setter @NoArgsConstructor
public class CashVoucher {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String voucherNo;
    @Column(nullable = false)
    private LocalDate voucherDate;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 12)
    private VoucherKind kind;
    /** RECEIPT: OTHER_INCOME | CAPITAL_INTRODUCED. PAYMENT: DRAWINGS | OTHER_EXPENSE. TRANSFER: null. */
    @Column(length = 24)
    private String purpose;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private CashAccount account;
    /** Destination account, TRANSFER only. */
    @ManyToOne(fetch = FetchType.EAGER)
    private CashAccount toAccount;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    @Column(length = 500)
    private String description;
    private String createdBy;
    private LocalDateTime createdAt;
}
