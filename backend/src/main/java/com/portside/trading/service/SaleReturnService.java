package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;
import static com.portside.trading.service.StockService.money;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.ReturnLineReq;
import com.portside.trading.web.dto.Req.ReturnReq;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Sales returns: stock goes back to the original batch at its original cost; sales, balance and profit are reversed. */
@Service
public class SaleReturnService {

    private final SaleRepo saleRepo;
    private final SaleLineRepo saleLineRepo;
    private final SaleReturnRepo returnRepo;
    private final StockService stock;
    private final CashService cash;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public SaleReturnService(SaleRepo saleRepo, SaleLineRepo saleLineRepo, SaleReturnRepo returnRepo, StockService stock,
                             CashService cash, AccountingService accounting, NumberService numbers, CurrentUserService currentUser) {
        this.saleRepo = saleRepo;
        this.saleLineRepo = saleLineRepo;
        this.returnRepo = returnRepo;
        this.stock = stock;
        this.cash = cash;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public SaleReturn create(ReturnReq r) {
        if (r.saleId() == null) throw new IllegalArgumentException("Select the invoice being returned against");
        if (r.lines() == null || r.lines().isEmpty()) throw new IllegalArgumentException("Select at least one item to return");
        Sale sale = saleRepo.findById(r.saleId()).orElseThrow(() -> new IllegalArgumentException("Unknown invoice"));
        LocalDate date = r.returnDate() == null ? LocalDate.now() : r.returnDate();

        SaleReturn ret = new SaleReturn();
        ret.setReturnNo(numbers.next("RETURN", "SRN"));
        ret.setReturnDate(date);
        ret.setSale(sale);
        ret.setCustomer(sale.getCustomer());
        ret.setNotes(r.notes() == null || r.notes().isBlank() ? null : r.notes().trim());
        ret.setCreatedBy(currentUser.username());
        ret.setCreatedAt(LocalDateTime.now());

        BigDecimal net = BigDecimal.ZERO, tax = BigDecimal.ZERO, cost = BigDecimal.ZERO;
        for (ReturnLineReq lr : r.lines()) {
            if (lr.qty() == null || lr.qty().signum() <= 0) continue;
            SaleLine sl = saleLineRepo.findById(lr.saleLineId()).orElseThrow(() -> new IllegalArgumentException("Unknown invoice line"));
            if (!sl.getSale().getId().equals(sale.getId())) throw new IllegalArgumentException("Line does not belong to invoice " + sale.getInvoiceNo());
            BigDecimal baseQty = lr.qty().multiply(sl.getFactor());
            BigDecimal remaining = sl.getBaseQty().subtract(sl.getReturnedBaseQty());
            if (baseQty.compareTo(remaining) > 0) {
                throw new IllegalArgumentException("Cannot return " + lr.qty().stripTrailingZeros().toPlainString() + " of "
                        + sl.getProduct().getName() + ": only "
                        + remaining.divide(sl.getFactor(), 4, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString() + " left to return");
            }
            BigDecimal share = baseQty.divide(sl.getBaseQty(), 10, RoundingMode.HALF_UP);
            boolean fullRest = baseQty.compareTo(remaining) == 0 && sl.getReturnedBaseQty().signum() == 0;
            BigDecimal lineNet = fullRest ? sl.getNetAmount() : money(sl.getNetAmount().multiply(share));
            BigDecimal lineTax = fullRest ? sl.getTaxAmount() : money(sl.getTaxAmount().multiply(share));
            BigDecimal lineCost = money(baseQty.multiply(sl.getUnitCost()));

            SaleReturnLine rl = new SaleReturnLine();
            rl.setSaleReturn(ret);
            rl.setSaleLine(sl);
            rl.setProduct(sl.getProduct());
            rl.setBatch(sl.getBatch());
            rl.setQty(lr.qty());
            rl.setBaseQty(baseQty);
            rl.setNetAmount(lineNet);
            rl.setTaxAmount(lineTax);
            rl.setTotal(lineNet.add(lineTax));
            rl.setUnitCost(sl.getUnitCost());
            ret.getLines().add(rl);

            sl.setReturnedBaseQty(sl.getReturnedBaseQty().add(baseQty));
            net = net.add(lineNet);
            tax = tax.add(lineTax);
            cost = cost.add(lineCost);
        }
        if (ret.getLines().isEmpty()) throw new IllegalArgumentException("Enter a return quantity for at least one item");
        BigDecimal total = net.add(tax);
        ret.setNetAmount(net);
        ret.setTaxAmount(tax);
        ret.setTotal(total);
        ret.setCogsTotal(cost);

        BigDecimal refund = r.refundAmount() == null ? BigDecimal.ZERO : money(r.refundAmount());
        if (refund.signum() < 0 || refund.compareTo(total) > 0) throw new IllegalArgumentException("Refund must be between 0 and the return value " + total);
        CashAccount acc = null;
        if (refund.signum() > 0) {
            acc = cash.resolve(r.refundAccountId(), "CASH");
            ret.setRefundAccount(acc);
        }
        ret.setRefundAmount(refund);
        returnRepo.save(ret);

        for (SaleReturnLine rl : ret.getLines()) {
            stock.record(date, rl.getBatch(), null, MovementType.SALE_RETURN, rl.getBaseQty(), "RETURN", ret.getReturnNo(),
                    "Returned against " + sale.getInvoiceNo());
        }
        sale.setReturnedAmount(sale.getReturnedAmount().add(total));
        sale.setReturnedNet(sale.getReturnedNet().add(net));
        sale.setReturnedCogs(sale.getReturnedCogs().add(cost));
        saleRepo.save(sale);

        accounting.post(date, "Sales return " + ret.getReturnNo() + " against " + sale.getInvoiceNo(), "RETURN", ret.getReturnNo(),
                dr(Heads.SALES_RETURNS, net),
                dr(Heads.SALES_TAX, tax),
                cr(Heads.AR, total),
                dr(Heads.INVENTORY, cost),
                cr(Heads.COGS, cost),
                acc == null ? dr(Heads.AR, BigDecimal.ZERO) : dr(Heads.AR, refund),
                acc == null ? cr(Heads.AR, BigDecimal.ZERO) : cr(acc.getHeadCode(), refund));
        return ret;
    }
}
