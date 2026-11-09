package com.portside.trading.service;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.web.dto.Req.ProductReq;
import com.portside.trading.web.dto.Req.UnitConv;
import java.math.BigDecimal;
import java.util.HashSet;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/** Create/update for the product, customer and supplier masters (opening balances are journalled automatically). */
@Service
public class MasterDataService {

    private final ProductRepo productRepo;
    private final UnitRepo unitRepo;
    private final CustomerRepo customerRepo;
    private final SupplierRepo supplierRepo;
    private final NumberService numbers;
    private final AccountingService accounting;

    public MasterDataService(ProductRepo productRepo, UnitRepo unitRepo, CustomerRepo customerRepo,
                             SupplierRepo supplierRepo, NumberService numbers, AccountingService accounting) {
        this.productRepo = productRepo;
        this.unitRepo = unitRepo;
        this.customerRepo = customerRepo;
        this.supplierRepo = supplierRepo;
        this.numbers = numbers;
        this.accounting = accounting;
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }

    @Transactional
    public Product saveProduct(Long id, ProductReq r) {
        if (r.sku() == null || r.sku().isBlank()) throw new IllegalArgumentException("Product code / SKU is required");
        if (r.name() == null || r.name().isBlank()) throw new IllegalArgumentException("Product name is required");
        if (r.baseUnitId() == null) throw new IllegalArgumentException("Unit of measurement is required");
        Product p = id == null ? new Product()
                : productRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        String sku = r.sku().trim();
        productRepo.findBySku(sku).ifPresent(other -> {
            if (!other.getId().equals(p.getId())) throw new IllegalArgumentException("Product code " + sku + " already exists");
        });
        Unit base = unitRepo.findById(r.baseUnitId()).orElseThrow(() -> new IllegalArgumentException("Unknown unit"));
        if (p.getId() != null && !p.getBaseUnit().getId().equals(base.getId())) {
            throw new IllegalStateException("The base unit cannot be changed once the product exists; add a conversion instead");
        }
        p.setSku(sku);
        p.setName(r.name().trim());
        p.setCategory(blankToNull(r.category()));
        p.setBrand(blankToNull(r.brand()));
        p.setDescription(blankToNull(r.description()));
        p.setBaseUnit(base);
        p.setSellingPrice(nz(r.sellingPrice()));
        p.setWholesalePrice(nz(r.wholesalePrice()));
        p.setRetailPrice(nz(r.retailPrice()));
        p.setMinStock(nz(r.minStock()));
        p.setActive(r.active() == null || r.active());

        p.getUnits().clear();
        Set<Long> seen = new HashSet<>();
        if (r.units() != null) {
            for (UnitConv uc : r.units()) {
                if (uc.unitId() == null || uc.unitId().equals(base.getId()) || !seen.add(uc.unitId())) continue;
                if (uc.factor() == null || uc.factor().signum() <= 0) throw new IllegalArgumentException("Unit conversion factor must be greater than zero");
                ProductUnit pu = new ProductUnit();
                pu.setProduct(p);
                pu.setUnit(unitRepo.findById(uc.unitId()).orElseThrow(() -> new IllegalArgumentException("Unknown unit")));
                pu.setFactor(uc.factor());
                p.getUnits().add(pu);
            }
        }
        return productRepo.save(p);
    }

    @Transactional
    public Customer saveCustomer(Long id, Customer in) {
        if (in.getName() == null || in.getName().isBlank()) throw new IllegalArgumentException("Customer name is required");
        Customer c = id == null ? new Customer()
                : customerRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (id == null) c.setCode(in.getCode() == null || in.getCode().isBlank() ? numbers.next("CUSTOMER", "CUS") : in.getCode().trim());
        c.setName(in.getName().trim());
        c.setPhone(blankToNull(in.getPhone()));
        c.setAddress(blankToNull(in.getAddress()));
        c.setType(in.getType() == null ? SaleType.RETAIL : in.getType());
        c.setCreditLimit(nz(in.getCreditLimit()));
        c.setCreditDays(in.getCreditDays() < 0 ? 0 : in.getCreditDays());
        c.setNotes(blankToNull(in.getNotes()));
        c.setActive(in.isActive());
        c.setOpeningBalance(nz(in.getOpeningBalance()));
        Customer saved = customerRepo.save(c);
        accounting.postOpening("OPENING_CUSTOMER", saved.getCode(), "Opening balance - " + saved.getName(),
                Heads.AR, saved.getOpeningBalance(), true);
        return saved;
    }

    @Transactional
    public Supplier saveSupplier(Long id, Supplier in) {
        if (in.getName() == null || in.getName().isBlank()) throw new IllegalArgumentException("Supplier name is required");
        Supplier s = id == null ? new Supplier()
                : supplierRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        if (id == null) s.setCode(in.getCode() == null || in.getCode().isBlank() ? numbers.next("SUPPLIER", "SUP") : in.getCode().trim());
        s.setName(in.getName().trim());
        s.setCountry(blankToNull(in.getCountry()));
        s.setContact(blankToNull(in.getContact()));
        s.setAddress(blankToNull(in.getAddress()));
        s.setNotes(blankToNull(in.getNotes()));
        s.setActive(in.isActive());
        s.setOpeningBalance(nz(in.getOpeningBalance()));
        Supplier saved = supplierRepo.save(s);
        accounting.postOpening("OPENING_SUPPLIER", saved.getCode(), "Opening balance - " + saved.getName(),
                Heads.AP, saved.getOpeningBalance(), false);
        return saved;
    }

    private static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
