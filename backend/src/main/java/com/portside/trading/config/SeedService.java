package com.portside.trading.config;

import com.portside.trading.domain.*;
import com.portside.trading.repo.AppUserRepository;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.service.AccountingService;
import com.portside.trading.service.CashService;
import com.portside.trading.service.ExpenseService;
import com.portside.trading.service.Heads;
import com.portside.trading.service.SettingsService;
import com.portside.trading.web.dto.Req.AccountReq;
import com.portside.trading.web.dto.Req.CategoryReq;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Idempotent first-run setup: demo logins, units, the Lahore warehouse, fixed accounting heads, cash/bank accounts,
 * the walk-in customer and the expense categories. Dev password for every seed account: "Portside@123".
 */
@Component
@Order(1)
public class SeedService implements ApplicationRunner {

    private static final String DEV_PASSWORD = "Portside@123";

    private final AppUserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final UnitRepo unitRepo;
    private final WarehouseRepo warehouseRepo;
    private final CustomerRepo customerRepo;
    private final AccountRepo accountRepo;
    private final ExpenseCategoryRepo categoryRepo;
    private final AccountingService accounting;
    private final CashService cash;
    private final ExpenseService expenses;
    private final SettingsService settings;

    public SeedService(AppUserRepository userRepository, PasswordEncoder passwordEncoder, UnitRepo unitRepo,
                       WarehouseRepo warehouseRepo, CustomerRepo customerRepo, AccountRepo accountRepo,
                       ExpenseCategoryRepo categoryRepo, AccountingService accounting, CashService cash,
                       ExpenseService expenses, SettingsService settings) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.unitRepo = unitRepo;
        this.warehouseRepo = warehouseRepo;
        this.customerRepo = customerRepo;
        this.accountRepo = accountRepo;
        this.categoryRepo = categoryRepo;
        this.accounting = accounting;
        this.cash = cash;
        this.expenses = expenses;
        this.settings = settings;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.count() == 0) {
            user("owner", "Shahzad Rauf", Role.OWNER);
            user("accountant", "Bilal Sheikh", Role.ACCOUNTANT);
            user("sales", "Imran Qadri", Role.SALES_OFFICER);
            user("storekeeper", "Rashid Mehmood", Role.STORE_KEEPER);
            user("importdesk", "Faisal Rana", Role.IMPORT_DESK);
        }
        for (String u : List.of("Piece", "Box", "Carton", "Kg", "Dozen", "Pack", "Set", "Meter", "Litre")) {
            if (unitRepo.findByNameIgnoreCase(u).isEmpty()) unitRepo.save(new Unit(u));
        }
        if (warehouseRepo.count() == 0) {
            Warehouse w = new Warehouse();
            w.setCode("LHR-01");
            w.setName("Lahore Main Warehouse");
            w.setAddress("Lahore, Pakistan");
            warehouseRepo.save(w);
        }
        heads();
        if (customerRepo.findFirstByWalkInTrue().isEmpty()) {
            Customer c = new Customer();
            c.setCode("WALKIN");
            c.setName("Walk-in Customer");
            c.setType(SaleType.RETAIL);
            c.setWalkIn(true);
            c.setCreditDays(0);
            customerRepo.save(c);
        }
        if (accountRepo.count() == 0) {
            cash.saveAccount(null, new AccountReq("Cash in Hand", AccountType.CASH, null, BigDecimal.ZERO, true));
            cash.saveAccount(null, new AccountReq("Main Bank Account", AccountType.BANK, null, BigDecimal.ZERO, true));
        }
        if (categoryRepo.count() == 0) {
            for (String n : List.of("Warehouse expenses", "Salaries", "Electricity", "Rent", "Transport", "Packing", "Loading / unloading",
                    "Office expenses", "Repairs", "Commission", "Bank charges", "Other expenses")) {
                expenses.createCategory(new CategoryReq(n, ExpenseNature.OPERATING));
            }
            for (String n : List.of("Customs duty", "Port & clearing charges", "Freight / shipping", "Other shipment payment", "Capital / non-operating payment")) {
                expenses.createCategory(new CategoryReq(n, ExpenseNature.NON_OPERATING));
            }
        }
        settings.setIfAbsent("books.startDate", LocalDate.now().toString());
    }

    private void heads() {
        accounting.ensureHead(Heads.AR, "Accounts receivable (customers)", HeadType.ASSET);
        accounting.ensureHead(Heads.INVENTORY, "Inventory", HeadType.ASSET);
        accounting.ensureHead(Heads.NON_OPERATING, "Shipment / non-operating payments (not in P&L)", HeadType.ASSET);
        accounting.ensureHead(Heads.AP, "Accounts payable (suppliers)", HeadType.LIABILITY);
        accounting.ensureHead(Heads.SALES_TAX, "Sales tax payable", HeadType.LIABILITY);
        accounting.ensureHead(Heads.IMPORT_CLEARING, "Imported stock introduced (import settled outside system)", HeadType.EQUITY);
        accounting.ensureHead(Heads.CAPITAL, "Owner capital", HeadType.EQUITY);
        accounting.ensureHead(Heads.DRAWINGS, "Owner drawings", HeadType.EQUITY);
        accounting.ensureHead(Heads.OPENING, "Opening balance equity", HeadType.EQUITY);
        accounting.ensureHead(Heads.SALES, "Sales", HeadType.INCOME);
        accounting.ensureHead(Heads.SALES_RETURNS, "Sales returns", HeadType.INCOME);
        accounting.ensureHead(Heads.OTHER_INCOME, "Other income", HeadType.INCOME);
        accounting.ensureHead(Heads.COGS, "Cost of goods sold", HeadType.COST_OF_SALES);
        accounting.ensureHead(Heads.STOCK_LOSS, "Stock losses & adjustments", HeadType.COST_OF_SALES);
        accounting.ensureHead(Heads.OTHER_EXPENSE, "Other expenses", HeadType.EXPENSE);
    }

    private void user(String username, String fullName, Role role) {
        AppUser u = new AppUser();
        u.setUsername(username);
        u.setPasswordHash(passwordEncoder.encode(DEV_PASSWORD));
        u.setFullName(fullName);
        u.setRole(role);
        u.setActive(true);
        userRepository.save(u);
    }
}
