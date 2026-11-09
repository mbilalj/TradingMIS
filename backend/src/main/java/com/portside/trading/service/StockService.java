package com.portside.trading.service;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Stock ledger operations: unit conversion, batch availability, FIFO suggestion and movement recording. */
@Service
public class StockService {

    public record Allocation(Batch batch, BigDecimal baseQty) {}

    private final MovementRepo movementRepo;
    private final BatchRepo batchRepo;
    private final WarehouseRepo warehouseRepo;
    private final CurrentUserService currentUser;

    public StockService(MovementRepo movementRepo, BatchRepo batchRepo, WarehouseRepo warehouseRepo, CurrentUserService currentUser) {
        this.movementRepo = movementRepo;
        this.batchRepo = batchRepo;
        this.warehouseRepo = warehouseRepo;
        this.currentUser = currentUser;
    }

    /** How many base units one [unit] of this product contains. */
    public BigDecimal factor(Product product, Unit unit) {
        if (unit.getId().equals(product.getBaseUnit().getId())) return BigDecimal.ONE;
        return product.getUnits().stream()
                .filter(pu -> pu.getUnit().getId().equals(unit.getId()))
                .map(ProductUnit::getFactor)
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Unit " + unit.getName() + " is not configured for product " + product.getSku()));
    }

    public BigDecimal onHand(Long batchId) {
        return movementRepo.onHandForBatch(batchId);
    }

    public BigDecimal onHandForProduct(Long productId) {
        return movementRepo.onHandForProduct(productId);
    }

    /** Batches of a product that still have stock, oldest arrival first, with the available base quantity. */
    public List<Allocation> availableBatches(Long productId) {
        Map<Long, BigDecimal> onHand = new HashMap<>();
        for (Object[] row : movementRepo.onHandByBatch(productId)) onHand.put((Long) row[0], (BigDecimal) row[1]);
        List<Allocation> out = new ArrayList<>();
        for (Batch b : batchRepo.findByProductIdOrderByShipmentArrivalDateAscIdAsc(productId)) {
            BigDecimal q = onHand.getOrDefault(b.getId(), BigDecimal.ZERO);
            if (q.signum() > 0) out.add(new Allocation(b, q));
        }
        return out;
    }

    /** Splits [baseQty] across the oldest batches (FIFO) unless a specific batch is requested. */
    public List<Allocation> allocate(Product product, BigDecimal baseQty, Long preferredBatchId) {
        List<Allocation> available = availableBatches(product.getId());
        List<Allocation> out = new ArrayList<>();
        if (preferredBatchId != null) {
            Allocation a = available.stream().filter(x -> x.batch().getId().equals(preferredBatchId)).findFirst()
                    .orElseThrow(() -> new IllegalStateException("Batch has no stock left for " + product.getSku()));
            if (a.baseQty().compareTo(baseQty) < 0) {
                throw new IllegalStateException("Only " + a.baseQty().stripTrailingZeros().toPlainString() + " "
                        + product.getBaseUnit().getName() + " left in batch " + a.batch().getBatchNo());
            }
            out.add(new Allocation(a.batch(), baseQty));
            return out;
        }
        BigDecimal remaining = baseQty;
        for (Allocation a : available) {
            if (remaining.signum() <= 0) break;
            BigDecimal take = a.baseQty().min(remaining);
            out.add(new Allocation(a.batch(), take));
            remaining = remaining.subtract(take);
        }
        if (remaining.signum() > 0) {
            BigDecimal have = baseQty.subtract(remaining);
            throw new IllegalStateException("Insufficient stock for " + product.getSku() + " - " + product.getName()
                    + ": requested " + baseQty.stripTrailingZeros().toPlainString() + ", available "
                    + have.stripTrailingZeros().toPlainString() + " " + product.getBaseUnit().getName());
        }
        return out;
    }

    @Transactional
    public StockMovement record(LocalDate date, Batch batch, Warehouse warehouse, MovementType type, BigDecimal qty,
                                String refType, String refNo, String reason) {
        StockMovement m = new StockMovement();
        m.setMoveDate(date);
        m.setProduct(batch.getProduct());
        m.setBatch(batch);
        m.setWarehouse(warehouse != null ? warehouse : batch.getShipment().getWarehouse());
        m.setType(type);
        m.setQty(qty);
        m.setUnitCost(batch.getUnitCost());
        m.setRefType(refType);
        m.setRefNo(refNo);
        m.setReason(reason);
        m.setCreatedBy(currentUser.username());
        m.setCreatedAt(LocalDateTime.now());
        return movementRepo.save(m);
    }

    public static BigDecimal money(BigDecimal v) {
        return v.setScale(2, RoundingMode.HALF_UP);
    }
}
