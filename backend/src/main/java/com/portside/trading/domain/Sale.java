package com.portside.trading.domain;

import com.fasterxml.jackson.annotation.JsonProperty;
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
@Table(name = "mis_sale")
@Getter @Setter @NoArgsConstructor
public class Sale {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 32)
    private String invoiceNo;
    @Column(nullable = false)
    private LocalDate saleDate;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16)
    private SaleType type;
    @ManyToOne(optional = false, fetch = FetchType.EAGER)
    private Customer customer;
    /** Sum of qty x rate before discount and tax. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal grossAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal discountTotal = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal taxTotal = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal total = BigDecimal.ZERO;
    /** Paid at the time of sale; never changes afterwards. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal paidAtSale = BigDecimal.ZERO;
    /** paidAtSale plus later receipts allocated to this invoice. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal paidAmount = BigDecimal.ZERO;
    /** Credit given for sales returns against this invoice. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal returnedAmount = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal cogsTotal = BigDecimal.ZERO;
    /** Net (pre-tax) sales value and cost reversed by returns, so profit stays correct after a return. */
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal returnedNet = BigDecimal.ZERO;
    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal returnedCogs = BigDecimal.ZERO;
    @Column(length = 32)
    private String paymentMethod;
    @ManyToOne(fetch = FetchType.EAGER)
    private CashAccount account;
    @Column(length = 1000)
    private String remarks;
    private String createdBy;
    private LocalDateTime createdAt;
    @Fetch(FetchMode.SUBSELECT)
    @OneToMany(mappedBy = "sale", cascade = CascadeType.ALL, fetch = FetchType.EAGER)
    @OrderBy("id")
    private List<SaleLine> lines = new ArrayList<>();

    @JsonProperty("outstanding")
    public BigDecimal outstanding() {
        return total.subtract(paidAmount).subtract(returnedAmount);
    }

    /** Net sales minus cost of goods, after returns. */
    @JsonProperty("profit")
    public BigDecimal profit() {
        return grossAmount.subtract(discountTotal).subtract(returnedNet).subtract(cogsTotal.subtract(returnedCogs));
    }
}
