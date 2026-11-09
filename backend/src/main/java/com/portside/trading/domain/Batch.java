package com.portside.trading.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** One product received in one shipment at one manually-entered cost -- the unit of cost tracking. */
@Entity
@Table(name = "mis_batch")
@Getter @Setter @NoArgsConstructor
public class Batch {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @JsonIgnoreProperties("batches")
    @ManyToOne(optional = false)
    private Shipment shipment;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Product product;
    @Column(nullable = false, unique = true, length = 64)
    private String batchNo;
    /** Quantity and cost as typed on the receiving screen, in [enteredUnit]. */
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Unit enteredUnit;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal enteredQty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal enteredUnitCost;
    /** Normalised to the product base unit. */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal receivedQty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal unitCost;
}
