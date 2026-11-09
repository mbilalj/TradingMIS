package com.portside.trading.web;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.service.LedgerService;
import com.portside.trading.service.MasterDataService;
import com.portside.trading.service.StockService;
import com.portside.trading.web.dto.Req.ProductReq;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/** Masters: units, warehouses, products, customers, suppliers. */
@RestController
@RequestMapping("/api")
public class MasterController {

    private final UnitRepo unitRepo;
    private final WarehouseRepo warehouseRepo;
    private final ProductRepo productRepo;
    private final CustomerRepo customerRepo;
    private final SupplierRepo supplierRepo;
    private final MasterDataService master;
    private final StockService stock;
    private final LedgerService ledger;
    private final JdbcTemplate jdbc;

    public MasterController(UnitRepo unitRepo, WarehouseRepo warehouseRepo, ProductRepo productRepo, CustomerRepo customerRepo,
                            SupplierRepo supplierRepo, MasterDataService master, StockService stock, LedgerService ledger, JdbcTemplate jdbc) {
        this.unitRepo = unitRepo;
        this.warehouseRepo = warehouseRepo;
        this.productRepo = productRepo;
        this.customerRepo = customerRepo;
        this.supplierRepo = supplierRepo;
        this.master = master;
        this.stock = stock;
        this.ledger = ledger;
        this.jdbc = jdbc;
    }

    @GetMapping("/units")
    public List<Unit> units() {
        return unitRepo.findAll();
    }

    @PostMapping("/units")
    @PreAuthorize("@accessService.canEdit('products')")
    public Unit createUnit(@RequestBody Map<String, String> body) {
        String name = body.getOrDefault("name", "").trim();
        if (name.isEmpty()) throw new IllegalArgumentException("Unit name is required");
        if (unitRepo.findByNameIgnoreCase(name).isPresent()) throw new IllegalArgumentException("Unit already exists");
        return unitRepo.save(new Unit(name));
    }

    @GetMapping("/warehouses")
    public List<Warehouse> warehouses() {
        return warehouseRepo.findAll();
    }

    // ------------------------------------------------------------ products

    /** Product plus live stock figures, used by the product master and every product picker. */
    @GetMapping("/products")
    @PreAuthorize("@accessService.canView('products')")
    public List<Map<String, Object>> products() {
        Map<Long, BigDecimal> onHand = new LinkedHashMap<>();
        Map<Long, BigDecimal> value = new LinkedHashMap<>();
        jdbc.query("select mv.product_id, sum(mv.qty), sum(mv.qty * b.unit_cost) from mis_stock_movement mv join mis_batch b on b.id = mv.batch_id group by mv.product_id",
                rs -> {
                    onHand.put(rs.getLong(1), rs.getBigDecimal(2));
                    value.put(rs.getLong(1), rs.getBigDecimal(3));
                });
        Map<Long, BigDecimal> lastCost = new LinkedHashMap<>();
        jdbc.query("select b.product_id, b.unit_cost from mis_batch b join mis_shipment h on h.id = b.shipment_id order by h.arrival_date, b.id",
                rs -> {
                    lastCost.put(rs.getLong(1), rs.getBigDecimal(2));
                });
        List<Map<String, Object>> out = new ArrayList<>();
        for (Product p : productRepo.findAll()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("product", p);
            BigDecimal q = onHand.getOrDefault(p.getId(), BigDecimal.ZERO);
            m.put("onHand", q);
            m.put("stockValue", value.getOrDefault(p.getId(), BigDecimal.ZERO));
            m.put("lastCost", lastCost.getOrDefault(p.getId(), BigDecimal.ZERO));
            m.put("lowStock", p.isActive() && q.compareTo(p.getMinStock()) <= 0);
            out.add(m);
        }
        return out;
    }

    /** Batches of a product that still have stock, oldest first, with their own cost -- for picking a batch while selling. */
    @GetMapping("/products/{id}/batches")
    @PreAuthorize("@accessService.canView('products')")
    public List<Map<String, Object>> productBatches(@PathVariable Long id) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (StockService.Allocation a : stock.availableBatches(id)) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("batchId", a.batch().getId());
            m.put("batchNo", a.batch().getBatchNo());
            m.put("shipmentNo", a.batch().getShipment().getShipmentNo());
            m.put("containerNo", a.batch().getShipment().getContainerNo());
            m.put("arrivalDate", a.batch().getShipment().getArrivalDate());
            m.put("unitCost", a.batch().getUnitCost());
            m.put("available", a.baseQty());
            out.add(m);
        }
        return out;
    }

    @PostMapping("/products")
    @PreAuthorize("@accessService.canEdit('products')")
    public Product createProduct(@RequestBody ProductReq r) {
        return master.saveProduct(null, r);
    }

    @PutMapping("/products/{id}")
    @PreAuthorize("@accessService.canEdit('products')")
    public Product updateProduct(@PathVariable Long id, @RequestBody ProductReq r) {
        return master.saveProduct(id, r);
    }

    // ------------------------------------------------------------ customers

    @GetMapping("/customers")
    @PreAuthorize("@accessService.canView('customers') or @accessService.canView('sales')")
    public List<Map<String, Object>> customers() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Customer c : customerRepo.findAll()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("customer", c);
            m.put("balance", ledger.customerBalance(c.getId()));
            out.add(m);
        }
        return out;
    }

    @PostMapping("/customers")
    @PreAuthorize("@accessService.canEdit('customers')")
    public Customer createCustomer(@RequestBody Customer c) {
        return master.saveCustomer(null, c);
    }

    @PutMapping("/customers/{id}")
    @PreAuthorize("@accessService.canEdit('customers')")
    public Customer updateCustomer(@PathVariable Long id, @RequestBody Customer c) {
        return master.saveCustomer(id, c);
    }

    // ------------------------------------------------------------ suppliers

    @GetMapping("/suppliers")
    @PreAuthorize("@accessService.canView('suppliers') or @accessService.canView('receiving')")
    public List<Map<String, Object>> suppliers() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Supplier s : supplierRepo.findAll()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("supplier", s);
            m.put("balance", ledger.supplierBalance(s.getId()));
            out.add(m);
        }
        return out;
    }

    @PostMapping("/suppliers")
    @PreAuthorize("@accessService.canEdit('suppliers')")
    public Supplier createSupplier(@RequestBody Supplier s) {
        return master.saveSupplier(null, s);
    }

    @PutMapping("/suppliers/{id}")
    @PreAuthorize("@accessService.canEdit('suppliers')")
    public Supplier updateSupplier(@PathVariable Long id, @RequestBody Supplier s) {
        return master.saveSupplier(id, s);
    }

    @GetMapping("/suppliers/{id}")
    @PreAuthorize("@accessService.canView('suppliers')")
    public Supplier supplier(@PathVariable Long id) {
        return supplierRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }
}
