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

@Entity
@Table(name = "mis_sale_return")
@Getter @Setter @NoArgsConstructor
public class SaleReturn {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String returnNo;
    @Column(nullable = false)
    private LocalDate returnDate;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Sale sale;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Customer customer;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal netAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal total = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal cogsTotal = BigDecimal.ZERO;
    /** Cash/bank actually handed back to the customer. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal refundAmount = BigDecimal.ZERO;
    @ManyToOne(fetch = FetchType.EAGER)
    private CashAccount refundAccount;
    @Column(length = 1000)
    private String notes;
    private String createdBy;
    private LocalDateTime createdAt;
    @Fetch(FetchMode.SUBSELECT)
    @OneToMany(mappedBy = "saleReturn", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @OrderBy("id")
    private List<SaleReturnLine> lines = new ArrayList<>();
}
