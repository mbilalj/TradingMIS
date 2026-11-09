package com.portside.trading.service;

import static com.portside.trading.web.dto.ReportResult.*;

import com.portside.trading.web.dto.ReportResult;
import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** Customer and supplier running balances and statement-style ledgers, computed straight from the transactions. */
@Service
public class LedgerService {

    private final JdbcTemplate jdbc;

    public LedgerService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private static final String CUSTOMER_BALANCE_SQL = """
            select c.opening_balance
              + coalesce((select sum(s.total) from mis_sale s where s.customer_id = c.id), 0)
              - coalesce((select sum(s.paid_at_sale) from mis_sale s where s.customer_id = c.id), 0)
              - coalesce((select sum(r.amount) from mis_receipt r where r.customer_id = c.id), 0)
              - coalesce((select sum(x.total) from mis_sale_return x where x.customer_id = c.id), 0)
              + coalesce((select sum(x.refund_amount) from mis_sale_return x where x.customer_id = c.id), 0)
              + coalesce((select sum(a.amount) from mis_party_adjustment a where a.party_type = 'CUSTOMER' and a.party_id = c.id), 0)
            from mis_customer c where c.id = ?""";

    private static final String SUPPLIER_BALANCE_SQL = """
            select s.opening_balance
              + coalesce((select sum(h.payable_amount) from mis_shipment h where h.supplier_id = s.id), 0)
              - coalesce((select sum(p.amount) from mis_supplier_payment p where p.supplier_id = s.id), 0)
              + coalesce((select sum(a.amount) from mis_party_adjustment a where a.party_type = 'SUPPLIER' and a.party_id = s.id), 0)
            from mis_supplier s where s.id = ?""";

    public BigDecimal customerBalance(Long id) {
        BigDecimal b = jdbc.queryForObject(CUSTOMER_BALANCE_SQL, BigDecimal.class, id);
        return b == null ? BigDecimal.ZERO : b;
    }

    public BigDecimal supplierBalance(Long id) {
        BigDecimal b = jdbc.queryForObject(SUPPLIER_BALANCE_SQL, BigDecimal.class, id);
        return b == null ? BigDecimal.ZERO : b;
    }

    private record Entry(LocalDate date, int order, long id, String type, String ref, String desc, BigDecimal debit, BigDecimal credit) {}

    private static LocalDate d(Object o) {
        return o instanceof Date sd ? sd.toLocalDate() : (LocalDate) o;
    }

    private static BigDecimal n(Object o) {
        return o == null ? BigDecimal.ZERO : (BigDecimal) o;
    }

    public ReportResult customerLedger(Long customerId, LocalDate from, LocalDate to) {
        Map<String, Object> cust = jdbc.queryForMap("select name, code, opening_balance from mis_customer where id = ?", customerId);
        BigDecimal opening = n(cust.get("opening_balance"));
        List<Entry> entries = new ArrayList<>();
        // Debit = customer owes more; credit = customer owes less.
        jdbc.query("select id, sale_date, invoice_no, type, total from mis_sale where customer_id = ?", rs -> {
            entries.add(new Entry(d(rs.getDate("sale_date")), 1, rs.getLong("id"), "Sale", rs.getString("invoice_no"),
                    rs.getString("type") + " sale", rs.getBigDecimal("total"), BigDecimal.ZERO));
        }, customerId);
        jdbc.query("select id, sale_date, invoice_no, paid_at_sale, payment_method from mis_sale where customer_id = ? and paid_at_sale > 0", rs -> {
            entries.add(new Entry(d(rs.getDate("sale_date")), 2, rs.getLong("id"), "Payment", rs.getString("invoice_no"),
                    "Paid at sale (" + rs.getString("payment_method") + ")", BigDecimal.ZERO, rs.getBigDecimal("paid_at_sale")));
        }, customerId);
        jdbc.query("select id, receipt_date, receipt_no, amount, method, reference from mis_receipt where customer_id = ?", rs -> {
            String ref = rs.getString("reference");
            entries.add(new Entry(d(rs.getDate("receipt_date")), 3, rs.getLong("id"), "Payment", rs.getString("receipt_no"),
                    "Payment received (" + rs.getString("method") + ")" + (ref == null || ref.isBlank() ? "" : " ref " + ref),
                    BigDecimal.ZERO, rs.getBigDecimal("amount")));
        }, customerId);
        jdbc.query("select id, return_date, return_no, total, refund_amount from mis_sale_return where customer_id = ?", rs -> {
            entries.add(new Entry(d(rs.getDate("return_date")), 4, rs.getLong("id"), "Return", rs.getString("return_no"),
                    "Sales return", BigDecimal.ZERO, rs.getBigDecimal("total")));
            if (rs.getBigDecimal("refund_amount").signum() > 0) {
                entries.add(new Entry(d(rs.getDate("return_date")), 5, rs.getLong("id"), "Refund", rs.getString("return_no"),
                        "Refund paid to customer", rs.getBigDecimal("refund_amount"), BigDecimal.ZERO));
            }
        }, customerId);
        jdbc.query("select id, adj_date, amount, reason from mis_party_adjustment where party_type = 'CUSTOMER' and party_id = ?", rs -> {
            BigDecimal amt = rs.getBigDecimal("amount");
            entries.add(new Entry(d(rs.getDate("adj_date")), 6, rs.getLong("id"), "Adjustment", "ADJ-" + rs.getLong("id"),
                    rs.getString("reason"), amt.signum() > 0 ? amt : BigDecimal.ZERO, amt.signum() < 0 ? amt.negate() : BigDecimal.ZERO));
        }, customerId);
        return buildLedger("customer-ledger", "Customer ledger - " + cust.get("name"), opening, entries, from, to);
    }

    public ReportResult supplierLedger(Long supplierId, LocalDate from, LocalDate to) {
        Map<String, Object> sup = jdbc.queryForMap("select name, opening_balance from mis_supplier where id = ?", supplierId);
        BigDecimal opening = n(sup.get("opening_balance"));
        List<Entry> entries = new ArrayList<>();
        // Debit = we owe less (payments); credit = we owe more (goods received on credit).
        jdbc.query("select id, arrival_date, shipment_no, payable_amount from mis_shipment where supplier_id = ? and payable_amount > 0", rs -> {
            entries.add(new Entry(d(rs.getDate("arrival_date")), 1, rs.getLong("id"), "Shipment", rs.getString("shipment_no"),
                    "Goods received - payable", BigDecimal.ZERO, rs.getBigDecimal("payable_amount")));
        }, supplierId);
        jdbc.query("select id, payment_date, payment_no, amount, method, reference from mis_supplier_payment where supplier_id = ?", rs -> {
            String ref = rs.getString("reference");
            entries.add(new Entry(d(rs.getDate("payment_date")), 2, rs.getLong("id"), "Payment", rs.getString("payment_no"),
                    "Payment made (" + rs.getString("method") + ")" + (ref == null || ref.isBlank() ? "" : " ref " + ref),
                    rs.getBigDecimal("amount"), BigDecimal.ZERO));
        }, supplierId);
        jdbc.query("select id, adj_date, amount, reason from mis_party_adjustment where party_type = 'SUPPLIER' and party_id = ?", rs -> {
            BigDecimal amt = rs.getBigDecimal("amount");
            entries.add(new Entry(d(rs.getDate("adj_date")), 3, rs.getLong("id"), "Adjustment", "ADJ-" + rs.getLong("id"),
                    rs.getString("reason"), amt.signum() < 0 ? amt.negate() : BigDecimal.ZERO, amt.signum() > 0 ? amt : BigDecimal.ZERO));
        }, supplierId);
        // Supplier balance = credits - debits; flip sign convention so positive means "we owe".
        return buildSupplierLedger("supplier-ledger", "Supplier ledger - " + sup.get("name"), opening, entries, from, to);
    }

    private ReportResult buildLedger(String code, String title, BigDecimal opening, List<Entry> all, LocalDate from, LocalDate to) {
        return build(code, title, opening, all, from, to, false);
    }

    private ReportResult buildSupplierLedger(String code, String title, BigDecimal opening, List<Entry> all, LocalDate from, LocalDate to) {
        return build(code, title, opening, all, from, to, true);
    }

    private ReportResult build(String code, String title, BigDecimal opening, List<Entry> all, LocalDate from, LocalDate to, boolean creditNormal) {
        all.sort(Comparator.comparing(Entry::date).thenComparingInt(Entry::order).thenComparingLong(Entry::id));
        BigDecimal running = opening;
        List<Entry> inRange = new ArrayList<>();
        for (Entry e : all) {
            if (from != null && e.date().isBefore(from)) {
                running = running.add(creditNormal ? e.credit().subtract(e.debit()) : e.debit().subtract(e.credit()));
            } else if (to == null || !e.date().isAfter(to)) {
                inRange.add(e);
            }
        }
        List<Map<String, Object>> rows = new ArrayList<>();
        rows.add(row().put("date", from).put("type", "Opening").put("ref", "").put("desc", "Opening balance")
                .put("debit", null).put("credit", null).put("balance", running).build());
        BigDecimal totDebit = BigDecimal.ZERO;
        BigDecimal totCredit = BigDecimal.ZERO;
        for (Entry e : inRange) {
            running = running.add(creditNormal ? e.credit().subtract(e.debit()) : e.debit().subtract(e.credit()));
            totDebit = totDebit.add(e.debit());
            totCredit = totCredit.add(e.credit());
            rows.add(row().put("date", e.date()).put("type", e.type()).put("ref", e.ref()).put("desc", e.desc())
                    .put("debit", e.debit().signum() == 0 ? null : e.debit())
                    .put("credit", e.credit().signum() == 0 ? null : e.credit()).put("balance", running).build());
        }
        Map<String, Object> totals = new LinkedHashMap<>();
        totals.put("debit", totDebit);
        totals.put("credit", totCredit);
        totals.put("balance", running);
        String sub = creditNormal ? "Positive balance = amount we owe the supplier" : "Positive balance = amount the customer owes us";
        return new ReportResult(code, title, sub,
                List.of(date("date", "Date"), text("type", "Type"), text("ref", "Reference"), text("desc", "Description"),
                        money("debit", "Debit"), money("credit", "Credit"), money("balance", "Balance")),
                rows, totals);
    }
}
