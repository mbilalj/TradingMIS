package com.portside.trading.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_sale_line")
@Getter @Setter @NoArgsConstructor
public class SaleLine {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @JsonIgnoreProperties("lines")
    @ManyToOne(optional = false)
    private Sale sale;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Product product;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Batch batch;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Unit unit;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal qty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal factor = BigDecimal.ONE;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal baseQty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal rate;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal discount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 9, scale = 3)
    private BigDecimal taxPct = BigDecimal.ZERO;
    /** qty x rate - discount, before tax. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal netAmount;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal lineTotal;
    /** Batch cost per base unit at the moment of sale. */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal unitCost;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal returnedBaseQty = BigDecimal.ZERO;
}
