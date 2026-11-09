package com.portside.trading.service;

import static com.portside.trading.service.AccountingService.cr;
import static com.portside.trading.service.AccountingService.dr;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.security.CurrentUserService;
import com.portside.trading.web.dto.Req.AccountReq;
import com.portside.trading.web.dto.Req.VoucherReq;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/** Cash and bank accounts, manual receipts/payments and cash<->bank transfers. */
@Service
public class CashService {

    private final AccountRepo accountRepo;
    private final VoucherRepo voucherRepo;
    private final AccountingService accounting;
    private final NumberService numbers;
    private final CurrentUserService currentUser;

    public CashService(AccountRepo accountRepo, VoucherRepo voucherRepo, AccountingService accounting,
                       NumberService numbers, CurrentUserService currentUser) {
        this.accountRepo = accountRepo;
        this.voucherRepo = voucherRepo;
        this.accounting = accounting;
        this.numbers = numbers;
        this.currentUser = currentUser;
    }

    @Transactional
    public CashAccount saveAccount(Long id, AccountReq r) {
        if (r.name() == null || r.name().isBlank()) throw new IllegalArgumentException("Account name is required");
        CashAccount a = id == null ? new CashAccount()
                : accountRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        a.setName(r.name().trim());
        if (id == null) a.setType(r.type() == null ? AccountType.BANK : r.type());
        a.setAccountNumber(r.accountNumber() == null || r.accountNumber().isBlank() ? null : r.accountNumber().trim());
        a.setOpeningBalance(r.openingBalance() == null ? BigDecimal.ZERO : r.openingBalance());
        a.setActive(r.active() == null || r.active());
        CashAccount saved = accountRepo.save(a);
        if (saved.getHeadCode() == null) {
            saved.setHeadCode("ACC-" + saved.getId());
            saved = accountRepo.save(saved);
        }
        accounting.ensureHead(saved.getHeadCode(), (saved.getType() == AccountType.CASH ? "Cash - " : "Bank - ") + saved.getName(), HeadType.ASSET);
        accounting.postOpening("OPENING_ACCOUNT", saved.getHeadCode(), "Opening balance - " + saved.getName(),
                saved.getHeadCode(), saved.getOpeningBalance(), true);
        return saved;
    }

    /** Picks the account a payment goes through: the chosen one, else a sensible default for the method. */
    public CashAccount resolve(Long accountId, String method) {
        if (accountId != null) {
            CashAccount a = accountRepo.findById(accountId).orElseThrow(() -> new IllegalArgumentException("Unknown cash/bank account"));
            if (!a.isActive()) throw new IllegalArgumentException("Account " + a.getName() + " is inactive");
            return a;
        }
        AccountType wanted = method != null && method.equalsIgnoreCase("CASH") ? AccountType.CASH : AccountType.BANK;
        return accountRepo.findAll().stream().filter(x -> x.isActive() && x.getType() == wanted).findFirst()
                .or(() -> accountRepo.findAll().stream().filter(CashAccount::isActive).findFirst())
                .orElseThrow(() -> new IllegalStateException("No cash/bank account available"));
    }

    @Transactional
    public CashVoucher createVoucher(VoucherReq r) {
        if (r.kind() == null) throw new IllegalArgumentException("Voucher type is required");
        if (r.amount() == null || r.amount().signum() <= 0) throw new IllegalArgumentException("Amount must be greater than zero");
        CashAccount acc = resolve(r.accountId(), null);
        LocalDate date = r.date() == null ? LocalDate.now() : r.date();
        CashVoucher v = new CashVoucher();
        v.setVoucherNo(numbers.next("VOUCHER", r.kind() == VoucherKind.RECEIPT ? "CR" : r.kind() == VoucherKind.PAYMENT ? "CP" : "TRF"));
        v.setVoucherDate(date);
        v.setKind(r.kind());
        v.setAccount(acc);
        v.setAmount(r.amount());
        v.setDescription(r.description());
        String narration;
        switch (r.kind()) {
            case RECEIPT -> {
                String purpose = r.purpose() == null ? "OTHER_INCOME" : r.purpose();
                if (!Set.of("OTHER_INCOME", "CAPITAL_INTRODUCED").contains(purpose)) throw new IllegalArgumentException("Unknown receipt purpose");
                v.setPurpose(purpose);
                narration = "Cash/bank received - " + purpose.replace('_', ' ').toLowerCase();
                v.setCreatedAt(LocalDateTime.now());
                v.setCreatedBy(currentUser.username());
                voucherRepo.save(v);
                accounting.post(date, narration + (r.description() == null ? "" : ": " + r.description()), "VOUCHER", v.getVoucherNo(),
                        dr(acc.getHeadCode(), r.amount()),
                        cr(purpose.equals("OTHER_INCOME") ? Heads.OTHER_INCOME : Heads.CAPITAL, r.amount()));
            }
            case PAYMENT -> {
                String purpose = r.purpose() == null ? "OTHER_EXPENSE" : r.purpose();
                if (!Set.of("DRAWINGS", "OTHER_EXPENSE").contains(purpose)) throw new IllegalArgumentException("Unknown payment purpose");
                v.setPurpose(purpose);
                narration = "Cash/bank paid - " + purpose.replace('_', ' ').toLowerCase();
                v.setCreatedAt(LocalDateTime.now());
                v.setCreatedBy(currentUser.username());
                voucherRepo.save(v);
                accounting.post(date, narration + (r.description() == null ? "" : ": " + r.description()), "VOUCHER", v.getVoucherNo(),
                        dr(purpose.equals("DRAWINGS") ? Heads.DRAWINGS : Heads.OTHER_EXPENSE, r.amount()),
                        cr(acc.getHeadCode(), r.amount()));
            }
            case TRANSFER -> {
                if (r.toAccountId() == null || r.toAccountId().equals(acc.getId())) throw new IllegalArgumentException("Pick a different destination account");
                CashAccount to = resolve(r.toAccountId(), null);
                v.setToAccount(to);
                v.setCreatedAt(LocalDateTime.now());
                v.setCreatedBy(currentUser.username());
                voucherRepo.save(v);
                accounting.post(date, "Transfer " + acc.getName() + " to " + to.getName(), "VOUCHER", v.getVoucherNo(),
                        dr(to.getHeadCode(), r.amount()), cr(acc.getHeadCode(), r.amount()));
            }
        }
        return v;
    }

    @Transactional
    public void deleteVoucher(Long id) {
        CashVoucher v = voucherRepo.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
        accounting.removeSource("VOUCHER", v.getVoucherNo());
        voucherRepo.delete(v);
    }
}
