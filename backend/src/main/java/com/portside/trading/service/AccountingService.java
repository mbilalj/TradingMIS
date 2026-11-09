package com.portside.trading.service;

import com.portside.trading.domain.AccountHead;
import com.portside.trading.domain.HeadType;
import com.portside.trading.domain.Journal;
import com.portside.trading.domain.JournalLine;
import com.portside.trading.repo.Repos.HeadRepo;
import com.portside.trading.repo.Repos.JournalRepo;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Double-entry core. Every business transaction posts a balanced journal here, so the cash book, receivables,
 * payables, P&L and balance sheet all come from one ledger and nothing is keyed twice.
 */
@Service
public class AccountingService {

    public record Line(String head, BigDecimal debit, BigDecimal credit) {}

    public static Line dr(String head, BigDecimal amount) { return new Line(head, amount, BigDecimal.ZERO); }
    public static Line cr(String head, BigDecimal amount) { return new Line(head, BigDecimal.ZERO, amount); }

    private final JournalRepo journalRepo;
    private final HeadRepo headRepo;
    private final JdbcTemplate jdbc;
    private final SettingsService settings;

    public AccountingService(JournalRepo journalRepo, HeadRepo headRepo, JdbcTemplate jdbc, SettingsService settings) {
        this.journalRepo = journalRepo;
        this.headRepo = headRepo;
        this.jdbc = jdbc;
        this.settings = settings;
    }

    @Transactional
    public void post(LocalDate date, String narration, String sourceType, String sourceNo, Line... lines) {
        BigDecimal debit = BigDecimal.ZERO;
        BigDecimal credit = BigDecimal.ZERO;
        Journal j = new Journal();
        j.setJournalDate(date);
        j.setNarration(narration.length() > 250 ? narration.substring(0, 250) : narration);
        j.setSourceType(sourceType);
        j.setSourceNo(sourceNo);
        List<JournalLine> out = new ArrayList<>();
        for (Line l : lines) {
            if (l.debit().signum() == 0 && l.credit().signum() == 0) continue;
            if (!headRepo.existsById(l.head())) throw new IllegalStateException("Unknown account head " + l.head());
            JournalLine jl = new JournalLine();
            jl.setJournal(j);
            jl.setHeadCode(l.head());
            jl.setDebit(l.debit());
            jl.setCredit(l.credit());
            out.add(jl);
            debit = debit.add(l.debit());
            credit = credit.add(l.credit());
        }
        if (debit.compareTo(credit) != 0) {
            throw new IllegalStateException("Unbalanced journal for " + sourceType + " " + sourceNo + ": " + debit + " vs " + credit);
        }
        if (out.isEmpty()) return;
        j.setLines(out);
        journalRepo.save(j);
    }

    @Transactional
    public void removeSource(String sourceType, String sourceNo) {
        journalRepo.deleteAll(journalRepo.findBySourceTypeAndSourceNo(sourceType, sourceNo));
    }

    @Transactional
    public AccountHead ensureHead(String code, String name, HeadType type) {
        return headRepo.findById(code).map(h -> {
            if (!h.getName().equals(name)) { h.setName(name); headRepo.save(h); }
            return h;
        }).orElseGet(() -> headRepo.save(new AccountHead(code, name, type)));
    }

    /** Date the books start; opening balances are dated here so they never fall inside a later P&L period. */
    public LocalDate booksStart() {
        String v = settings.get("books.startDate");
        return v == null || v.isBlank() ? LocalDate.now() : LocalDate.parse(v);
    }

    /** (Re)posts the opening balance of a party/account. amount>0 means a normal-side balance. */
    @Transactional
    public void postOpening(String sourceType, String sourceNo, String narration, String head, BigDecimal amount, boolean headIsDebitNormal) {
        removeSource(sourceType, sourceNo);
        if (amount == null || amount.signum() == 0) return;
        boolean debitHead = headIsDebitNormal == (amount.signum() > 0);
        BigDecimal abs = amount.abs();
        post(booksStart(), narration, sourceType, sourceNo,
                debitHead ? dr(head, abs) : cr(head, abs),
                debitHead ? cr(Heads.OPENING, abs) : dr(Heads.OPENING, abs));
    }

    /** Debit-minus-credit balance of a head up to and including [asOf] (null = all time). */
    public BigDecimal balance(String head, LocalDate asOf) {
        String sql = "select coalesce(sum(l.debit - l.credit), 0) from mis_journal_line l join mis_journal j on j.id = l.journal_id where l.head_code = ?"
                + (asOf != null ? " and j.journal_date <= ?" : "");
        Object[] args = asOf != null ? new Object[]{head, java.sql.Date.valueOf(asOf)} : new Object[]{head};
        BigDecimal b = jdbc.queryForObject(sql, BigDecimal.class, args);
        return b == null ? BigDecimal.ZERO : b;
    }
}
