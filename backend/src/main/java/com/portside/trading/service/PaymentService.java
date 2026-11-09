package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.PartyAdjReq;
import com.portside.trading.web.dto.Req.ReceiptReq;
import com.portside.trading.web.dto.Req.SupplierPaymentReq;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Customer receipts, supplier payments and manual balance adjustments. */
@Service
public class PaymentService {

    private final ReceiptRepo receiptRepo;
    private final SupplierPaymentRepo supplierPaymentRepo;
    private final PartyAdjustmentRepo adjustmentRepo;
    private final CustomerRepo customerRepo;
    private final SupplierRepo supplierRepo;
    private final SaleRepo saleRepo;
    private final CashService cash;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public PaymentService(ReceiptRepo receiptRepo, SupplierPaymentRepo supplierPaymentRepo, PartyAdjustmentRepo adjustmentRepo,
                          CustomerRepo customerRepo, SupplierRepo supplierRepo, SaleRepo saleRepo, CashService cash,
                          AccountingService accounting, NumberService numbers, CurrentUserService currentUser) {
        this.receiptRepo = receiptRepo;
        this.supplierPaymentRepo = supplierPaymentRepo;
        this.adjustmentRepo = adjustmentRepo;
        this.customerRepo = customerRepo;
        this.supplierRepo = supplierRepo;
        this.saleRepo = saleRepo;
        this.cash = cash;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public Receipt receivePayment(ReceiptReq r) {
        if (r.amount() == null || r.amount().signum() <= 0) throw new IllegalArgumentException("Amount must be greater than zero");
        if (r.customerId() == null) throw new IllegalArgumentException("Customer is required");
        Customer c = customerRepo.findById(r.customerId()).orElseThrow(() -> new IllegalArgumentException("Unknown customer"));
        CashAccount acc = cash.resolve(r.accountId(), r.method());
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();

        Receipt rc = new Receipt();
        rc.setReceiptNo(numbers.next("RECEIPT", "RCP"));
        rc.setReceiptDate(date);
        rc.setCustomer(c);
        rc.setAmount(r.amount());
        rc.setMethod(r.method());
        rc.setAccount(acc);
        rc.setReference(r.reference() == null || r.reference().isBlank() ? null : r.reference().trim());
        rc.setNotes(r.notes() == null || r.notes().isBlank() ? null : r.notes().trim());
        rc.setCreatedBy(currentUser.username());
        rc.setCreatedAt(LocalDateTime.now());
        receiptRepo.save(rc);

        // Settle the oldest unpaid invoices first so overdue ageing stays honest.
        BigDecimal left = r.amount();
        for (Sale s : saleRepo.findByCustomerIdOrderBySaleDateAscIdAsc(c.getId())) {
            if (left.signum() <= 0) break;
            BigDecimal open = s.outstanding();
            if (open.signum() <= 0) continue;
            BigDecimal apply = open.min(left);
            s.setPaidAmount(s.getPaidAmount().add(apply));
            saleRepo.save(s);
            left = left.subtract(apply);
        }
        accounting.post(date, "Payment received from " + c.getName(), "RECEIPT", rc.getReceiptNo(),
                dr(acc.getHeadCode(), r.amount()), cr(Heads.AR, r.amount()));
        return rc;
    }

    @Transactional
    public SupplierPayment paySupplier(SupplierPaymentReq r) {
        if (r.amount() == null || r.amount().signum() <= 0) throw new IllegalArgumentException("Amount must be greater than zero");
        if (r.supplierId() == null) throw new IllegalArgumentException("Supplier is required");
        Supplier s = supplierRepo.findById(r.supplierId()).orElseThrow(() -> new IllegalArgumentException("Unknown supplier"));
        CashAccount acc = cash.resolve(r.accountId(), r.method());
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();

        SupplierPayment p = new SupplierPayment();
        p.setPaymentNo(numbers.next("SUPPAY", "SPY"));
        p.setPaymentDate(date);
        p.setSupplier(s);
        p.setAmount(r.amount());
        p.setMethod(r.method());
        p.setAccount(acc);
        p.setReference(r.reference() == null || r.reference().isBlank() ? null : r.reference().trim());
        p.setNotes(r.notes() == null || r.notes().isBlank() ? null : r.notes().trim());
        p.setCreatedBy(currentUser.username());
        p.setCreatedAt(LocalDateTime.now());
        supplierPaymentRepo.save(p);
        accounting.post(date, "Payment to supplier " + s.getName(), "SUPPLIER_PAYMENT", p.getPaymentNo(),
                dr(Heads.AP, r.amount()), cr(acc.getHeadCode(), r.amount()));
        return p;
    }

    @Transactional
    public PartyAdjustment adjust(PartyAdjReq r) {
        if (r.partyType() == null || r.partyId() == null) throw new IllegalArgumentException("Party is required");
        if (r.amount() == null || r.amount().signum() == 0) throw new IllegalArgumentException("Adjustment amount cannot be zero");
        if (r.reason() == null || r.reason().isBlank()) throw new IllegalArgumentException("A reason is required for every adjustment");
        String name;
        if (r.partyType() == PartyType.CUSTOMER) {
            name = customerRepo.findById(r.partyId()).orElseThrow(() -> new IllegalArgumentException("Unknown customer")).getName();
        } else {
            name = supplierRepo.findById(r.partyId()).orElseThrow(() -> new IllegalArgumentException("Unknown supplier")).getName();
        }
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();
        PartyAdjustment a = new PartyAdjustment();
        a.setPartyType(r.partyType());
        a.setPartyId(r.partyId());
        a.setAdjDate(date);
        a.setAmount(r.amount());
        a.setReason(r.reason().trim());
        a.setCreatedBy(currentUser.username());
        a.setCreatedAt(LocalDateTime.now());
        adjustmentRepo.save(a);

        BigDecimal abs = r.amount().abs();
        boolean up = r.amount().signum() > 0;
        String src = "ADJ-" + a.getId();
        if (r.partyType() == PartyType.CUSTOMER) {
            accounting.post(date, "Customer adjustment - " + name + ": " + a.getReason(), "PARTY_ADJ", src,
                    up ? dr(Heads.AR, abs) : dr(Heads.OTHER_EXPENSE, abs),
                    up ? cr(Heads.OTHER_INCOME, abs) : cr(Heads.AR, abs));
        } else {
            accounting.post(date, "Supplier adjustment - " + name + ": " + a.getReason(), "PARTY_ADJ", src,
                    up ? dr(Heads.OTHER_EXPENSE, abs) : dr(Heads.AP, abs),
                    up ? cr(Heads.AP, abs) : cr(Heads.OTHER_INCOME, abs));
        }
        return a;
    }
}
