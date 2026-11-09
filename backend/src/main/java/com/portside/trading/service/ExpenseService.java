package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.CategoryReq;
import com.portside.trading.web.dto.Req.ExpenseReq;
import java.time.LocalDate;
import java.time.LocalDateTime;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Payments out. OPERATING payments debit an expense head (reduces profit); NON_OPERATING ones debit the
 * non-operating asset head (customs duty etc.), so only cash/bank moves and the P&L is untouched.
 */
@Service
public class ExpenseService {

    private final ExpenseRepo expenseRepo;
    private final ExpenseCategoryRepo categoryRepo;
    private final ShipmentRepo shipmentRepo;
    private final CashService cash;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public ExpenseService(ExpenseRepo expenseRepo, ExpenseCategoryRepo categoryRepo, ShipmentRepo shipmentRepo,
                          CashService cash, AccountingService accounting, NumberService numbers, CurrentUserService currentUser) {
        this.expenseRepo = expenseRepo;
        this.categoryRepo = categoryRepo;
        this.shipmentRepo = shipmentRepo;
        this.cash = cash;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public ExpenseCategory createCategory(CategoryReq r) {
        if (r.name() == null || r.name().isBlank()) throw new IllegalArgumentException("Category name is required");
        ExpenseNature nature = r.nature() == null ? ExpenseNature.OPERATING : r.nature();
        categoryRepo.findByNameAndNature(r.name().trim(), nature).ifPresent(x -> { throw new IllegalArgumentException("Category already exists"); });
        ExpenseCategory c = new ExpenseCategory();
        c.setName(r.name().trim());
        c.setNature(nature);
        c = categoryRepo.save(c);
        if (nature == ExpenseNature.OPERATING) {
            c.setHeadCode("EXP-" + c.getId());
            c = categoryRepo.save(c);
            accounting.ensureHead(c.getHeadCode(), c.getName(), HeadType.EXPENSE);
        }
        return c;
    }

    @Transactional
    public Expense create(ExpenseReq r) {
        if (r.amount() == null || r.amount().signum() <= 0) throw new IllegalArgumentException("Amount must be greater than zero");
        if (r.categoryId() == null) throw new IllegalArgumentException("Category is required");
        ExpenseCategory cat = categoryRepo.findById(r.categoryId()).orElseThrow(() -> new IllegalArgumentException("Unknown category"));
        ExpenseNature nature = r.nature() == null ? cat.getNature() : r.nature();
        if (cat.getNature() != nature) throw new IllegalArgumentException("Category " + cat.getName() + " is a " + cat.getNature() + " category");
        CashAccount acc = cash.resolve(r.accountId(), r.method());
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();

        Expense e = new Expense();
        e.setExpenseNo(numbers.next("EXPENSE", nature == ExpenseNature.OPERATING ? "EXP" : "NOP"));
        e.setExpenseDate(date);
        e.setNature(nature);
        e.setCategory(cat);
        e.setAmount(r.amount());
        e.setAccount(acc);
        e.setMethod(r.method());
        e.setDescription(r.description() == null || r.description().isBlank() ? null : r.description().trim());
        if (r.shipmentId() != null) {
            if (nature == ExpenseNature.OPERATING) throw new IllegalArgumentException("Only non-operating payments can be linked to a shipment");
            e.setShipment(shipmentRepo.findById(r.shipmentId()).orElseThrow(() -> new IllegalArgumentException("Unknown shipment")));
        }
        e.setCreatedBy(currentUser.username());
        e.setCreatedAt(LocalDateTime.now());
        expenseRepo.save(e);

        String head = nature == ExpenseNature.OPERATING ? cat.getHeadCode() : Heads.NON_OPERATING;
        String narration = (nature == ExpenseNature.OPERATING ? "Expense - " : "Non-operating payment - ") + cat.getName()
                + (e.getShipment() != null ? " (" + e.getShipment().getShipmentNo() + ")" : "");
        accounting.post(date, narration, "EXPENSE", e.getExpenseNo(), dr(head, r.amount()), cr(acc.getHeadCode(), r.amount()));
        return e;
    }

    @Transactional
    public void delete(Long id) {
        Expense e = expenseRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        accounting.removeSource("EXPENSE", e.getExpenseNo());
        expenseRepo.delete(e);
    }
}
