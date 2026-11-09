package com.portside.trading.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_stock_movement", indexes = {
        @Index(columnList = "product_id"), @Index(columnList = "batch_id"), @Index(columnList = "moveDate")})
@Getter @Setter @NoArgsConstructor
public class StockMovement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false)
    private LocalDate moveDate;
    @ManyToOne(optional = false)
    private Product product;
    @ManyToOne(optional = false)
    private Batch batch;
    @ManyToOne(optional = false)
    private Warehouse warehouse;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 24)
    private MovementType type;
    /** Base-unit quantity; positive adds to stock, negative removes. */
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal qty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal unitCost;
    @Column(length = 32)
    private String refType;
    @Column(length = 48)
    private String refNo;
    @Column(length = 500)
    private String reason;
    private String createdBy;
    private LocalDateTime createdAt;
}
