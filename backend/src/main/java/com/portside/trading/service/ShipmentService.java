package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.ShipmentLineReq;
import com.portside.trading.web.dto.Req.ShipmentReq;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Stock receiving: one shipment record, one batch per product line, stock and books updated together. */
@Service
public class ShipmentService {

    private final ShipmentRepo shipmentRepo;
    private final BatchRepo batchRepo;
    private final ProductRepo productRepo;
    private final UnitRepo unitRepo;
    private final SupplierRepo supplierRepo;
    private final WarehouseRepo warehouseRepo;
    private final StockService stock;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public ShipmentService(ShipmentRepo shipmentRepo, BatchRepo batchRepo, ProductRepo productRepo, UnitRepo unitRepo,
                           SupplierRepo supplierRepo, WarehouseRepo warehouseRepo, StockService stock,
                           AccountingService accounting, NumberService numbers, CurrentUserService currentUser) {
        this.shipmentRepo = shipmentRepo;
        this.batchRepo = batchRepo;
        this.productRepo = productRepo;
        this.unitRepo = unitRepo;
        this.supplierRepo = supplierRepo;
        this.warehouseRepo = warehouseRepo;
        this.stock = stock;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public Shipment create(ShipmentReq r) {
        if (r.lines() == null || r.lines().isEmpty()) throw new IllegalArgumentException("Add at least one product line");
        if (r.supplierId() == null) throw new IllegalArgumentException("Supplier is required");
        Supplier supplier = supplierRepo.findById(r.supplierId()).orElseThrow(() -> new IllegalArgumentException("Unknown supplier"));
        Warehouse warehouse = r.warehouseId() != null
                ? warehouseRepo.findById(r.warehouseId()).orElseThrow(() -> new IllegalArgumentException("Unknown warehouse"))
                : warehouseRepo.findAll().stream().filter(Warehouse::isActive).findFirst()
                        .orElseThrow(() -> new IllegalStateException("No warehouse configured"));

        String shipmentNo = r.shipmentNo() == null || r.shipmentNo().isBlank() ? numbers.next("SHIPMENT", "SHP") : r.shipmentNo().trim();
        if (shipmentRepo.findByShipmentNo(shipmentNo).isPresent()) throw new IllegalArgumentException("Shipment number " + shipmentNo + " already exists");
        String containerNo = r.containerNo() == null ? "" : r.containerNo().trim();
        if (containerNo.isEmpty()) throw new IllegalArgumentException("Container number is required - every batch belongs to a container");
        LocalDate date = r.arrivalDate() == null ? LocalDate.now() : r.arrivalDate();

        Shipment sh = new Shipment();
        sh.setShipmentNo(shipmentNo);
        sh.setContainerNo(containerNo);
        sh.setArrivalDate(date);
        sh.setSupplier(supplier);
        sh.setWarehouse(warehouse);
        sh.setNotes(r.notes() == null || r.notes().isBlank() ? null : r.notes().trim());
        sh.setCreatedBy(currentUser.username());
        sh.setCreatedAt(LocalDateTime.now());

        BigDecimal total = BigDecimal.ZERO;
        Set<String> usedBatchNos = new HashSet<>();
        int idx = 0;
        for (ShipmentLineReq l : r.lines()) {
            idx++;
            if (l.productId() == null) throw new IllegalArgumentException("Line " + idx + ": product is required");
            Product p = productRepo.findById(l.productId()).orElseThrow(() -> new IllegalArgumentException("Unknown product"));
            Unit unit = l.unitId() == null ? p.getBaseUnit()
                    : unitRepo.findById(l.unitId()).orElseThrow(() -> new IllegalArgumentException("Unknown unit"));
            if (l.qty() == null || l.qty().signum() <= 0) throw new IllegalArgumentException("Line " + idx + ": quantity must be greater than zero");
            if (l.unitCost() == null || l.unitCost().signum() < 0) throw new IllegalArgumentException("Line " + idx + ": final product cost is required");
            BigDecimal factor = stock.factor(p, unit);
            Batch b = new Batch();
            b.setShipment(sh);
            b.setProduct(p);
            b.setEnteredUnit(unit);
            b.setEnteredQty(l.qty());
            b.setEnteredUnitCost(l.unitCost());
            b.setReceivedQty(l.qty().multiply(factor));
            b.setUnitCost(l.unitCost().divide(factor, 4, RoundingMode.HALF_UP));
            String batchNo = l.batchNo() == null || l.batchNo().isBlank()
                    ? containerNo + "-" + String.format("%02d", idx) : l.batchNo().trim();
            if (!usedBatchNos.add(batchNo) || batchRepo.existsByBatchNo(batchNo)) {
                throw new IllegalArgumentException("Batch number " + batchNo + " already exists");
            }
            b.setBatchNo(batchNo);
            sh.getBatches().add(b);
            total = total.add(StockService.money(l.qty().multiply(l.unitCost())));
        }
        BigDecimal payable = r.payableAmount() == null ? BigDecimal.ZERO : r.payableAmount();
        if (payable.signum() < 0 || payable.compareTo(total) > 0) {
            throw new IllegalArgumentException("Payable to supplier must be between 0 and the shipment value " + total);
        }
        sh.setTotalCost(total);
        sh.setPayableAmount(payable);
        Shipment saved = shipmentRepo.save(sh);

        for (Batch b : saved.getBatches()) {
            stock.record(date, b, warehouse, MovementType.RECEIPT, b.getReceivedQty(), "SHIPMENT", shipmentNo, "Stock received");
        }
        accounting.post(date, "Stock received " + shipmentNo + " from " + supplier.getName(), "SHIPMENT", shipmentNo,
                dr(Heads.INVENTORY, total),
                cr(Heads.AP, payable),
                cr(Heads.IMPORT_CLEARING, total.subtract(payable)));
        return saved;
    }
}
