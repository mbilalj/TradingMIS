package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Manual +/- correction on a customer or supplier balance. Positive increases what the customer owes us
 * (or what we owe the supplier).
 */
@Entity
@Table(name = "mis_party_adjustment")
@Getter @Setter @NoArgsConstructor
public class PartyAdjustment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 12)
    private PartyType partyType;
    @Column(nullable = false)
    private Long partyId;
    @Column(nullable = false)
    private LocalDate adjDate;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    @Column(nullable = false, length = 500)
    private String reason;
    private String createdBy;
    private LocalDateTime createdAt;
}
