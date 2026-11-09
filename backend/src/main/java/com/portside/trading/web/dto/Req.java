package com.portside.trading.web.dto;

import com.portside.trading.domain.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/** Request bodies for the post-arrival MIS endpoints. */
public final class Req {
    private Req() {}

    public record UnitConv(Long unitId, BigDecimal factor) {}

    public record ProductReq(String sku, String name, String category, String brand, String description,
                             Long baseUnitId, BigDecimal sellingPrice, BigDecimal wholesalePrice,
                             BigDecimal retailPrice, BigDecimal minStock, Boolean active, List<UnitConv> units) {}

    public record ShipmentLineReq(Long productId, String batchNo, Long unitId, BigDecimal qty, BigDecimal unitCost) {}

    public record ShipmentReq(String shipmentNo, String containerNo, LocalDate arrivalDate, Long supplierId, Long warehouseId,
                              String notes, BigDecimal payableAmount, List<ShipmentLineReq> lines) {}

    public record SaleLineReq(Long productId, Long batchId, Long unitId, BigDecimal qty, BigDecimal rate,
                              BigDecimal discount, BigDecimal taxPct) {}

    public record SaleReq(LocalDate saleDate, SaleType type, Long customerId, String paymentMethod, Long accountId,
                          BigDecimal paidAmount, String remarks, Boolean overrideCreditLimit, List<SaleLineReq> lines) {}

    public record ReturnLineReq(Long saleLineId, BigDecimal qty) {}

    public record ReturnReq(Long saleId, LocalDate returnDate, String notes, BigDecimal refundAmount,
                            Long refundAccountId, List<ReturnLineReq> lines) {}

    public record ReceiptReq(Long customerId, LocalDate date, BigDecimal amount, String method, Long accountId,
                             String reference, String notes) {}

    public record SupplierPaymentReq(Long supplierId, LocalDate date, BigDecimal amount, String method, Long accountId,
                                     String reference, String notes) {}

    public record PartyAdjReq(PartyType partyType, Long partyId, LocalDate date, BigDecimal amount, String reason) {}

    public record StockAdjReq(LocalDate date, Long batchId, MovementType type, Boolean increase, Long unitId,
                              BigDecimal qty, String reason) {}

    public record ExpenseReq(LocalDate date, ExpenseNature nature, Long categoryId, BigDecimal amount, Long accountId,
                             String method, Long shipmentId, String description) {}

    public record CategoryReq(String name, ExpenseNature nature) {}

    public record VoucherReq(LocalDate date, VoucherKind kind, String purpose, Long accountId, Long toAccountId,
                             BigDecimal amount, String description) {}

    public record AccountReq(String name, AccountType type, String accountNumber, BigDecimal openingBalance,
                             Boolean active) {}
}
