package com.portside.trading.repo;

import com.portside.trading.domain.*;
import jakarta.persistence.LockModeType;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** All Spring Data repositories for the post-arrival MIS, grouped to keep the package small. */
public final class Repos {
    private Repos() {}

    public interface WarehouseRepo extends JpaRepository<Warehouse, Long> {
        Optional<Warehouse> findByCode(String code);
    }

    public interface UnitRepo extends JpaRepository<Unit, Long> {
        Optional<Unit> findByNameIgnoreCase(String name);
    }

    public interface ProductRepo extends JpaRepository<Product, Long> {
        Optional<Product> findBySku(String sku);

        @Lock(LockModeType.PESSIMISTIC_WRITE)
        @Query("select p from Product p where p.id = :id")
        Optional<Product> lockById(@Param("id") Long id);
    }

    public interface SupplierRepo extends JpaRepository<Supplier, Long> {
        Optional<Supplier> findByCode(String code);
    }

    public interface CustomerRepo extends JpaRepository<Customer, Long> {
        Optional<Customer> findByCode(String code);
        Optional<Customer> findFirstByWalkInTrue();
    }

    public interface ShipmentRepo extends JpaRepository<Shipment, Long> {
        Optional<Shipment> findByShipmentNo(String shipmentNo);
    }

    public interface BatchRepo extends JpaRepository<Batch, Long> {
        boolean existsByBatchNo(String batchNo);
        List<Batch> findByProductIdOrderByShipmentArrivalDateAscIdAsc(Long productId);
    }

    public interface MovementRepo extends JpaRepository<StockMovement, Long> {
        @Query("select coalesce(sum(m.qty), 0) from StockMovement m where m.batch.id = :batchId")
        BigDecimal onHandForBatch(@Param("batchId") Long batchId);

        @Query("select coalesce(sum(m.qty), 0) from StockMovement m where m.product.id = :productId")
        BigDecimal onHandForProduct(@Param("productId") Long productId);

        @Query("select m.batch.id, coalesce(sum(m.qty), 0) from StockMovement m where m.product.id = :productId group by m.batch.id")
        List<Object[]> onHandByBatch(@Param("productId") Long productId);

        List<StockMovement> findByBatchIdOrderByIdAsc(Long batchId);
    }

    public interface SaleRepo extends JpaRepository<Sale, Long> {
        Optional<Sale> findByInvoiceNo(String invoiceNo);
        List<Sale> findByCustomerIdOrderBySaleDateAscIdAsc(Long customerId);
    }

    public interface SaleLineRepo extends JpaRepository<SaleLine, Long> {}

    public interface SaleReturnRepo extends JpaRepository<SaleReturn, Long> {
        List<SaleReturn> findBySaleIdOrderByIdAsc(Long saleId);
    }

    public interface AccountRepo extends JpaRepository<CashAccount, Long> {}

    public interface ReceiptRepo extends JpaRepository<Receipt, Long> {}

    public interface SupplierPaymentRepo extends JpaRepository<SupplierPayment, Long> {}

    public interface PartyAdjustmentRepo extends JpaRepository<PartyAdjustment, Long> {
        List<PartyAdjustment> findByPartyTypeAndPartyIdOrderByAdjDateAscIdAsc(PartyType type, Long partyId);
    }

    public interface ExpenseCategoryRepo extends JpaRepository<ExpenseCategory, Long> {
        Optional<ExpenseCategory> findByNameAndNature(String name, ExpenseNature nature);
    }

    public interface ExpenseRepo extends JpaRepository<Expense, Long> {}

    public interface VoucherRepo extends JpaRepository<CashVoucher, Long> {}

    public interface HeadRepo extends JpaRepository<AccountHead, String> {}

    public interface JournalRepo extends JpaRepository<Journal, Long> {
        List<Journal> findBySourceTypeAndSourceNo(String sourceType, String sourceNo);
    }

    public interface AttachmentRepo extends JpaRepository<Attachment, Long> {
        List<Attachment> findByOwnerTypeAndOwnerIdOrderByIdAsc(String ownerType, Long ownerId);
    }

    public interface SequenceRepo extends JpaRepository<DocSequence, String> {
        @Lock(LockModeType.PESSIMISTIC_WRITE)
        @Query("select s from DocSequence s where s.name = :name")
        Optional<DocSequence> lockByName(@Param("name") String name);
    }
}
