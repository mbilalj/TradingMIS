package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;
import static com.portside.trading.service.StockService.money;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.SaleLineReq;
import com.portside.trading.web.dto.Req.SaleReq;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Wholesale and retail invoicing in one flow: allocates stock to batches (batch-specific costing, oldest batch by
 * default), deducts it, records payment/credit and posts sales, receivable, cash and COGS in one transaction.
 */
@Service
public class SaleService {

    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private final SaleRepo saleRepo;
    private final CustomerRepo customerRepo;
    private final ProductRepo productRepo;
    private final UnitRepo unitRepo;
    private final StockService stock;
    private final LedgerService ledger;
    private final CashService cash;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public SaleService(SaleRepo saleRepo, CustomerRepo customerRepo, ProductRepo productRepo, UnitRepo unitRepo,
                       StockService stock, LedgerService ledger, CashService cash, AccountingService accounting,
                       NumberService numbers, CurrentUserService currentUser) {
        this.saleRepo = saleRepo;
        this.customerRepo = customerRepo;
        this.productRepo = productRepo;
        this.unitRepo = unitRepo;
        this.stock = stock;
        this.ledger = ledger;
        this.cash = cash;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public Sale create(SaleReq r) {
        if (r.lines() == null || r.lines().isEmpty()) throw new IllegalArgumentException("Add at least one product");
        SaleType type = r.type() == null ? SaleType.RETAIL : r.type();
        Customer customer = r.customerId() != null
                ? customerRepo.findById(r.customerId()).orElseThrow(() -> new IllegalArgumentException("Unknown customer"))
                : customerRepo.findFirstByWalkInTrue().orElseThrow(() -> new IllegalArgumentException("Select a customer"));
        if (!customer.isActive()) throw new IllegalArgumentException("Customer " + customer.getName() + " is inactive");
        LocalDate date = r.saleDate() == null ? LocalDate.now() : r.saleDate();

        Sale sale = new Sale();
        sale.setInvoiceNo(numbers.next("INVOICE", "INV"));
        sale.setSaleDate(date);
        sale.setType(type);
        sale.setCustomer(customer);
        sale.setRemarks(r.remarks() == null || r.remarks().isBlank() ? null : r.remarks().trim());
        sale.setCreatedBy(currentUser.username());
        sale.setCreatedAt(LocalDateTime.now());

        // Lock products in a fixed order so two concurrent sales cannot deadlock or both take the last unit.
        List<SaleLineReq> ordered = new ArrayList<>(r.lines());
        ordered.sort(Comparator.comparing(l -> l.productId() == null ? 0L : l.productId()));
        for (SaleLineReq l : ordered) {
            if (l.productId() != null) productRepo.lockById(l.productId());
        }

        BigDecimal gross = BigDecimal.ZERO, discount = BigDecimal.ZERO, tax = BigDecimal.ZERO, total = BigDecimal.ZERO, cogs = BigDecimal.ZERO;
        int idx = 0;
        for (SaleLineReq l : r.lines()) {
            idx++;
            if (l.productId() == null) throw new IllegalArgumentException("Line " + idx + ": product is required");
            Product p = productRepo.findById(l.productId()).orElseThrow(() -> new IllegalArgumentException("Unknown product"));
            if (!p.isActive()) throw new IllegalArgumentException("Product " + p.getSku() + " is inactive");
            Unit unit = l.unitId() == null ? p.getBaseUnit() : unitRepo.findById(l.unitId()).orElseThrow(() -> new IllegalArgumentException("Unknown unit"));
            if (l.qty() == null || l.qty().signum() <= 0) throw new IllegalArgumentException("Line " + idx + ": quantity must be greater than zero");
            BigDecimal factor = stock.factor(p, unit);
            BigDecimal baseQty = l.qty().multiply(factor);
            BigDecimal rate = l.rate();
            if (rate == null) {
                BigDecimal perBase = type == SaleType.WHOLESALE ? p.getWholesalePrice() : p.getRetailPrice();
                if (perBase == null || perBase.signum() == 0) perBase = p.getSellingPrice();
                rate = (perBase == null ? BigDecimal.ZERO : perBase).multiply(factor);
            }
            if (rate.signum() < 0) throw new IllegalArgumentException("Line " + idx + ": rate cannot be negative");
            BigDecimal lineGross = money(l.qty().multiply(rate));
            BigDecimal lineDiscount = l.discount() == null ? BigDecimal.ZERO : money(l.discount());
            if (lineDiscount.signum() < 0 || lineDiscount.compareTo(lineGross) > 0) {
                throw new IllegalArgumentException("Line " + idx + ": discount must be between 0 and the line amount");
            }
            BigDecimal taxPct = l.taxPct() == null ? BigDecimal.ZERO : l.taxPct();

            List<StockService.Allocation> parts = stock.allocate(p, baseQty, l.batchId());
            BigDecimal grossLeft = lineGross, discLeft = lineDiscount;
            for (int i = 0; i < parts.size(); i++) {
                StockService.Allocation a = parts.get(i);
                boolean last = i == parts.size() - 1;
                BigDecimal share = a.baseQty().divide(baseQty, 10, RoundingMode.HALF_UP);
                BigDecimal pg = last ? grossLeft : money(lineGross.multiply(share));
                BigDecimal pd = last ? discLeft : money(lineDiscount.multiply(share));
                grossLeft = grossLeft.subtract(pg);
                discLeft = discLeft.subtract(pd);
                BigDecimal net = pg.subtract(pd);
                BigDecimal pt = money(net.multiply(taxPct).divide(HUNDRED, 6, RoundingMode.HALF_UP));
                BigDecimal pieceQty = a.baseQty().divide(factor, 4, RoundingMode.HALF_UP);

                SaleLine line = new SaleLine();
                line.setSale(sale);
                line.setProduct(p);
                line.setBatch(a.batch());
                line.setUnit(unit);
                line.setQty(pieceQty);
                line.setFactor(factor);
                line.setBaseQty(a.baseQty());
                line.setRate(rate);
                line.setDiscount(pd);
                line.setTaxPct(taxPct);
                line.setNetAmount(net);
                line.setTaxAmount(pt);
                line.setLineTotal(net.add(pt));
                line.setUnitCost(a.batch().getUnitCost());
                sale.getLines().add(line);

                gross = gross.add(pg);
                discount = discount.add(pd);
                tax = tax.add(pt);
                total = total.add(net).add(pt);
                cogs = cogs.add(money(a.baseQty().multiply(a.batch().getUnitCost())));
            }
        }
        sale.setGrossAmount(gross);
        sale.setDiscountTotal(discount);
        sale.setTaxTotal(tax);
        sale.setTotal(total);
        sale.setCogsTotal(cogs);

        BigDecimal paid = r.paidAmount();
        if (paid == null) paid = customer.isWalkIn() ? total : BigDecimal.ZERO;
        paid = money(paid);
        if (paid.signum() < 0 || paid.compareTo(total) > 0) throw new IllegalArgumentException("Paid amount must be between 0 and the invoice total " + total);
        if (customer.isWalkIn() && paid.compareTo(total) < 0) {
            throw new IllegalArgumentException("Credit sales need a named customer - select or create the customer first");
        }
        if (!customer.isWalkIn() && customer.getCreditLimit().signum() > 0 && !Boolean.TRUE.equals(r.overrideCreditLimit())) {
            BigDecimal after = ledger.customerBalance(customer.getId()).add(total.subtract(paid));
            if (after.compareTo(customer.getCreditLimit()) > 0) {
                throw new IllegalStateException("Credit limit exceeded for " + customer.getName() + ": balance would be " + after
                        + " against a limit of " + customer.getCreditLimit());
            }
        }
        CashAccount account = null;
        if (paid.signum() > 0) {
            account = cash.resolve(r.accountId(), r.paymentMethod());
            sale.setAccount(account);
        }
        sale.setPaymentMethod(r.paymentMethod() == null || r.paymentMethod().isBlank() ? (paid.signum() > 0 ? "CASH" : "CREDIT") : r.paymentMethod());
        sale.setPaidAtSale(paid);
        sale.setPaidAmount(paid);
        saleRepo.save(sale);

        for (SaleLine line : sale.getLines()) {
            stock.record(date, line.getBatch(), null, MovementType.SALE, line.getBaseQty().negate(), "SALE", sale.getInvoiceNo(),
                    "Sold to " + customer.getName());
        }
        BigDecimal netSales = gross.subtract(discount);
        accounting.post(date, "Sale " + sale.getInvoiceNo() + " - " + customer.getName(), "SALE", sale.getInvoiceNo(),
                account == null ? dr(Heads.AR, BigDecimal.ZERO) : dr(account.getHeadCode(), paid),
                dr(Heads.AR, total.subtract(paid)),
                cr(Heads.SALES, netSales),
                cr(Heads.SALES_TAX, tax),
                dr(Heads.COGS, cogs),
                cr(Heads.INVENTORY, cogs));
        return sale;
    }
}
