package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.web.dto.Req.StockAdjReq;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Damaged / missing / correction adjustments. Every one needs a reason and leaves a movement + journal trail. */
@Service
public class StockAdjustmentService {

    private final BatchRepo batchRepo;
    private final ProductRepo productRepo;
    private final UnitRepo unitRepo;
    private final StockService stock;
    private final AccountingService accounting;
    private final NumberService numbers;

    public StockAdjustmentService(BatchRepo batchRepo, ProductRepo productRepo, UnitRepo unitRepo, StockService stock,
                                  AccountingService accounting, NumberService numbers) {
        this.batchRepo = batchRepo;
        this.productRepo = productRepo;
        this.unitRepo = unitRepo;
        this.stock = stock;
        this.accounting = accounting;
        this.numbers = numbers;
    }

    @Transactional
    public StockMovement adjust(StockAdjReq r) {
        if (r.batchId() == null) throw new IllegalArgumentException("Select the batch to adjust");
        if (r.type() == null || r.type() == MovementType.RECEIPT || r.type() == MovementType.SALE || r.type() == MovementType.SALE_RETURN) {
            throw new IllegalArgumentException("Adjustment type must be DAMAGED, MISSING, CORRECTION or OTHER_ADJUSTMENT");
        }
        if (r.reason() == null || r.reason().isBlank()) throw new IllegalArgumentException("A reason is required for every adjustment");
        if (r.qty() == null || r.qty().signum() <= 0) throw new IllegalArgumentException("Quantity must be greater than zero");
        Batch batch = batchRepo.findById(r.batchId()).orElseThrow(() -> new IllegalArgumentException("Unknown batch"));
        Product p = productRepo.lockById(batch.getProduct().getId()).orElseThrow();
        Unit unit = r.unitId() == null ? p.getBaseUnit() : unitRepo.findById(r.unitId()).orElseThrow(() -> new IllegalArgumentException("Unknown unit"));
        BigDecimal base = r.qty().multiply(stock.factor(p, unit));
        boolean increase = (r.type() == MovementType.CORRECTION || r.type() == MovementType.OTHER_ADJUSTMENT)
                && Boolean.TRUE.equals(r.increase());
        if (!increase && stock.onHand(batch.getId()).compareTo(base) < 0) {
            throw new IllegalStateException("Batch " + batch.getBatchNo() + " only has "
                    + stock.onHand(batch.getId()).stripTrailingZeros().toPlainString() + " " + p.getBaseUnit().getName() + " on hand");
        }
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();
        String no = numbers.next("STOCKADJ", "ADJ");
        StockMovement m = stock.record(date, batch, null, r.type(), increase ? base : base.negate(), "ADJUSTMENT", no, r.reason().trim());
        BigDecimal value = StockService.money(base.multiply(batch.getUnitCost()));
        accounting.post(date, "Stock adjustment (" + r.type().name().toLowerCase().replace('_', ' ') + ") " + batch.getBatchNo()
                        + ": " + r.reason().trim(), "STOCK_ADJ", no,
                increase ? dr(Heads.INVENTORY, value) : dr(Heads.STOCK_LOSS, value),
                increase ? cr(Heads.STOCK_LOSS, value) : cr(Heads.INVENTORY, value));
        return m;
    }
}
