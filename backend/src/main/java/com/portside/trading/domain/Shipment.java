package com.portside.trading.domain;

import jakarta.persistence.*;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Header of a goods-arrival record in the Lahore warehouse. One batch per product line. */
@Entity
@Table(name = "mis_shipment")
@Getter @Setter @NoArgsConstructor
public class Shipment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 48)
    private String shipmentNo;
    /** The physical container this receiving record covers; every batch (and so every sale line) traces back to one. */
    @Column(length = 32)
    private String containerNo;
    @Column(nullable = false)
    private LocalDate arrivalDate;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Supplier supplier;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Warehouse warehouse;
    @Column(length = 1000)
    private String notes;
    /** Part of the shipment value still owed to the supplier (credited to payables). */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal payableAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal totalCost = BigDecimal.ZERO;
    private String createdBy;
    private LocalDateTime createdAt;
    @Fetch(FetchMode.SUBSELECT)
    @OneToMany(mappedBy = "shipment", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @OrderBy("id")
    private List<Batch> batches = new ArrayList<>();
}
