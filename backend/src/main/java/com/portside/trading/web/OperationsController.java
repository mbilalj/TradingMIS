package com.portside.trading.web;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.service.*;
import com.portside.trading.web.dto.Req.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** Day-to-day transactions: receiving, sales, returns, payments, adjustments, expenses and cash/bank. */
@RestController
@RequestMapping("/api")
public class OperationsController {

    private final ShipmentService shipmentService;
    private final ShipmentRepo shipmentRepo;
    private final SaleService saleService;
    private final SaleRepo saleRepo;
    private final SaleReturnService returnService;
    private final SaleReturnRepo returnRepo;
    private final PaymentService paymentService;
    private final ReceiptRepo receiptRepo;
    private final SupplierPaymentRepo supplierPaymentRepo;
    private final PartyAdjustmentRepo adjustmentRepo;
    private final StockAdjustmentService adjustmentService;
    private final ExpenseService expenseService;
    private final ExpenseRepo expenseRepo;
    private final ExpenseCategoryRepo categoryRepo;
    private final CashService cashService;
    private final AccountRepo accountRepo;
    private final VoucherRepo voucherRepo;
    private final AccountingService accounting;
    private final MovementRepo movementRepo;

    public OperationsController(ShipmentService shipmentService, ShipmentRepo shipmentRepo, SaleService saleService, SaleRepo saleRepo,
                                SaleReturnService returnService, SaleReturnRepo returnRepo, PaymentService paymentService,
                                ReceiptRepo receiptRepo, SupplierPaymentRepo supplierPaymentRepo, PartyAdjustmentRepo adjustmentRepo,
                                StockAdjustmentService adjustmentService, ExpenseService expenseService, ExpenseRepo expenseRepo,
                                ExpenseCategoryRepo categoryRepo, CashService cashService, AccountRepo accountRepo, VoucherRepo voucherRepo,
                                AccountingService accounting, MovementRepo movementRepo) {
        this.shipmentService = shipmentService;
        this.shipmentRepo = shipmentRepo;
        this.saleService = saleService;
        this.saleRepo = saleRepo;
        this.returnService = returnService;
        this.returnRepo = returnRepo;
        this.paymentService = paymentService;
        this.receiptRepo = receiptRepo;
        this.supplierPaymentRepo = supplierPaymentRepo;
        this.adjustmentRepo = adjustmentRepo;
        this.adjustmentService = adjustmentService;
        this.expenseService = expenseService;
        this.expenseRepo = expenseRepo;
        this.categoryRepo = categoryRepo;
        this.cashService = cashService;
        this.accountRepo = accountRepo;
        this.voucherRepo = voucherRepo;
        this.accounting = accounting;
        this.movementRepo = movementRepo;
    }

    // ------------------------------------------------------------ receiving

    @GetMapping("/shipments")
    @PreAuthorize("@accessService.canView('receiving')")
    public List<Shipment> shipments() {
        List<Shipment> list = new ArrayList<>(shipmentRepo.findAll());
        list.sort(Comparator.comparing(Shipment::getArrivalDate).thenComparing(Shipment::getId).reversed());
        return list;
    }

    @GetMapping("/shipments/{id}")
    @PreAuthorize("@accessService.canView('receiving')")
    public Map<String, Object> shipment(@PathVariable Long id) {
        Shipment s = shipmentRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        List<Expense> payments = expenseRepo.findAll().stream()
                .filter(e -> e.getShipment() != null && e.getShipment().getId().equals(id)).toList();
        List<Map<String, Object>> batches = new ArrayList<>();
        for (Batch b : s.getBatches()) {
            batches.add(Map.of("batch", b, "onHand", movementRepo.onHandForBatch(b.getId())));
        }
        return Map.of("shipment", s, "batches", batches, "payments", payments);
    }

    @PostMapping("/shipments")
    @PreAuthorize("@accessService.canEdit('receiving')")
    public Shipment receive(@RequestBody ShipmentReq r) {
        return shipmentService.create(r);
    }

    // ------------------------------------------------------------ stock adjustments

    @PostMapping("/stock-adjustments")
    @PreAuthorize("@accessService.canEdit('adjustments')")
    public StockMovement adjustStock(@RequestBody StockAdjReq r) {
        return adjustmentService.adjust(r);
    }

    // ------------------------------------------------------------ sales

    @GetMapping("/sales")
    @PreAuthorize("@accessService.canView('sales')")
    public List<Sale> sales(@RequestParam(required = false) LocalDate from, @RequestParam(required = false) LocalDate to,
                            @RequestParam(required = false) SaleType type, @RequestParam(required = false) String q,
                            @RequestParam(required = false) Long customerId) {
        String needle = q == null ? null : q.trim().toLowerCase();
        return saleRepo.findAll().stream()
                .filter(s -> from == null || !s.getSaleDate().isBefore(from))
                .filter(s -> to == null || !s.getSaleDate().isAfter(to))
                .filter(s -> type == null || s.getType() == type)
                .filter(s -> customerId == null || s.getCustomer().getId().equals(customerId))
                .filter(s -> needle == null || needle.isEmpty() || s.getInvoiceNo().toLowerCase().contains(needle)
                        || s.getCustomer().getName().toLowerCase().contains(needle))
                .sorted(Comparator.comparing(Sale::getSaleDate).thenComparing(Sale::getId).reversed())
                .limit(500)
                .toList();
    }

    @GetMapping("/sales/{id}")
    @PreAuthorize("@accessService.canView('sales')")
    public Sale sale(@PathVariable Long id) {
        return saleRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @PostMapping("/sales")
    @PreAuthorize("@accessService.canEdit('sales')")
    public Sale createSale(@RequestBody SaleReq r) {
        return saleService.create(r);
    }

    @GetMapping("/sale-returns")
    @PreAuthorize("@accessService.canView('returns')")
    public List<SaleReturn> returns() {
        return returnRepo.findAll().stream().sorted(Comparator.comparing(SaleReturn::getReturnDate).thenComparing(SaleReturn::getId).reversed()).toList();
    }

    @GetMapping("/sales/{id}/returns")
    @PreAuthorize("@accessService.canView('returns')")
    public List<SaleReturn> returnsFor(@PathVariable Long id) {
        return returnRepo.findBySaleIdOrderByIdAsc(id);
    }

    @PostMapping("/sale-returns")
    @PreAuthorize("@accessService.canEdit('returns')")
    public SaleReturn createReturn(@RequestBody ReturnReq r) {
        return returnService.create(r);
    }

    // ------------------------------------------------------------ payments & adjustments

    @GetMapping("/receipts")
    @PreAuthorize("@accessService.canView('receipts')")
    public List<Receipt> receipts() {
        return receiptRepo.findAll().stream().sorted(Comparator.comparing(Receipt::getReceiptDate).thenComparing(Receipt::getId).reversed()).limit(500).toList();
    }

    @PostMapping("/receipts")
    @PreAuthorize("@accessService.canEdit('receipts')")
    public Receipt createReceipt(@RequestBody ReceiptReq r) {
        return paymentService.receivePayment(r);
    }

    @GetMapping("/supplier-payments")
    @PreAuthorize("@accessService.canView('supplierpay')")
    public List<SupplierPayment> supplierPayments() {
        return supplierPaymentRepo.findAll().stream().sorted(Comparator.comparing(SupplierPayment::getPaymentDate).thenComparing(SupplierPayment::getId).reversed()).limit(500).toList();
    }

    @PostMapping("/supplier-payments")
    @PreAuthorize("@accessService.canEdit('supplierpay')")
    public SupplierPayment createSupplierPayment(@RequestBody SupplierPaymentReq r) {
        return paymentService.paySupplier(r);
    }

    @GetMapping("/party-adjustments")
    @PreAuthorize("@accessService.canView('customers') or @accessService.canView('suppliers')")
    public List<PartyAdjustment> adjustments(@RequestParam PartyType type, @RequestParam Long id) {
        return adjustmentRepo.findByPartyTypeAndPartyIdOrderByAdjDateAscIdAsc(type, id);
    }

    @PostMapping("/party-adjustments")
    @PreAuthorize("@accessService.canEdit('receipts') or @accessService.canEdit('supplierpay')")
    public PartyAdjustment createAdjustment(@RequestBody PartyAdjReq r) {
        return paymentService.adjust(r);
    }

    // ------------------------------------------------------------ expenses

    @GetMapping("/expense-categories")
    @PreAuthorize("@accessService.canView('expenses')")
    public List<ExpenseCategory> categories() {
        return categoryRepo.findAll();
    }

    @PostMapping("/expense-categories")
    @PreAuthorize("@accessService.canEdit('expenses')")
    public ExpenseCategory createCategory(@RequestBody CategoryReq r) {
        return expenseService.createCategory(r);
    }

    @GetMapping("/expenses")
    @PreAuthorize("@accessService.canView('expenses')")
    public List<Expense> expenses(@RequestParam(required = false) LocalDate from, @RequestParam(required = false) LocalDate to,
                                  @RequestParam(required = false) ExpenseNature nature) {
        return expenseRepo.findAll().stream()
                .filter(e -> from == null || !e.getExpenseDate().isBefore(from))
                .filter(e -> to == null || !e.getExpenseDate().isAfter(to))
                .filter(e -> nature == null || e.getNature() == nature)
                .sorted(Comparator.comparing(Expense::getExpenseDate).thenComparing(Expense::getId).reversed())
                .limit(500).toList();
    }

    @PostMapping("/expenses")
    @PreAuthorize("@accessService.canEdit('expenses')")
    public Expense createExpense(@RequestBody ExpenseReq r) {
        return expenseService.create(r);
    }

    @DeleteMapping("/expenses/{id}")
    @PreAuthorize("@accessService.isOwner()")
    public void deleteExpense(@PathVariable Long id) {
        expenseService.delete(id);
    }

    // ------------------------------------------------------------ cash & bank

    @GetMapping("/accounts")
    @PreAuthorize("@accessService.canView('cash') or @accessService.canView('sales') or @accessService.canView('receipts') or @accessService.canView('expenses')")
    public List<Map<String, Object>> accounts() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (CashAccount a : accountRepo.findAll()) {
            out.add(Map.of("account", a, "balance", accounting.balance(a.getHeadCode(), null)));
        }
        return out;
    }

    @PostMapping("/accounts")
    @PreAuthorize("@accessService.canEdit('cash')")
    public CashAccount createAccount(@RequestBody AccountReq r) {
        return cashService.saveAccount(null, r);
    }

    @PutMapping("/accounts/{id}")
    @PreAuthorize("@accessService.canEdit('cash')")
    public CashAccount updateAccount(@PathVariable Long id, @RequestBody AccountReq r) {
        return cashService.saveAccount(id, r);
    }

    @GetMapping("/vouchers")
    @PreAuthorize("@accessService.canView('cash')")
    public List<CashVoucher> vouchers() {
        return voucherRepo.findAll().stream().sorted(Comparator.comparing(CashVoucher::getVoucherDate).thenComparing(CashVoucher::getId).reversed()).limit(500).toList();
    }

    @PostMapping("/vouchers")
    @PreAuthorize("@accessService.canEdit('cash')")
    public CashVoucher createVoucher(@RequestBody VoucherReq r) {
        return cashService.createVoucher(r);
    }

    @DeleteMapping("/vouchers/{id}")
    @PreAuthorize("@accessService.isOwner()")
    public void deleteVoucher(@PathVariable Long id) {
        cashService.deleteVoucher(id);
    }
}
