package com.portside.trading.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_sale_return_line")
@Getter @Setter @NoArgsConstructor
public class SaleReturnLine {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @JsonIgnoreProperties("lines")
    @ManyToOne(optional = false)
    private SaleReturn saleReturn;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private SaleLine saleLine;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Product product;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Batch batch;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal qty;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal baseQty;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal netAmount;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal taxAmount;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal total;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal unitCost;
}
