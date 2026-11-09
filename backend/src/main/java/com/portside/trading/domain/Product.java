package com.portside.trading.domain;

import jakarta.persistence.*;
import org.hibernate.annotations.Fetch;
import org.hibernate.annotations.FetchMode;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "mis_product")
@Getter @Setter @NoArgsConstructor
public class Product {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 48)
    private String sku;
    @Column(nullable = false, length = 200)
    private String name;
    @Column(length = 96)
    private String category;
    @Column(length = 96)
    private String brand;
    @Column(length = 500)
    private String description;
    /** All stock quantities are stored in this unit; other units convert through ProductUnit.factor. */
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Unit baseUnit;
    @Column(precision = 18, scale = 2)
    private BigDecimal sellingPrice = BigDecimal.ZERO;
    @Column(precision = 18, scale = 2)
    private BigDecimal wholesalePrice = BigDecimal.ZERO;
    @Column(precision = 18, scale = 2)
    private BigDecimal retailPrice = BigDecimal.ZERO;
    @Column(precision = 18, scale = 4)
    private BigDecimal minStock = BigDecimal.ZERO;
    @Column(nullable = false)
    private boolean active = true;
    @Fetch(FetchMode.SUBSELECT)
    @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    private List<ProductUnit> units = new ArrayList<>();
}
