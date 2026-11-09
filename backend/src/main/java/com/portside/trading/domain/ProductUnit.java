package com.portside.trading.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import java.math.BigDecimal;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Per-product unit conversion: 1 of [unit] = [factor] base units (e.g. 1 Carton = 200 Piece). */
@Entity
@Table(name = "mis_product_unit", uniqueConstraints = @UniqueConstraint(columnNames = {"product_id", "unit_id"}))
@Getter @Setter @NoArgsConstructor
public class ProductUnit {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @JsonIgnoreProperties("units")
    @ManyToOne(optional = false)
    private Product product;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Unit unit;
    @Column(nullable = false, precision = 18, scale = 4)
    private BigDecimal factor = BigDecimal.ONE;
}
