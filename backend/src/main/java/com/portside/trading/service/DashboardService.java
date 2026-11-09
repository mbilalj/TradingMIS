package com.portside.trading.service;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Numbers for the owner's landing page. Money figures come from the journal so they always agree with the reports. */
@Service
@Transactional(readOnly = true)
public class DashboardService {

    private final JdbcTemplate jdbc;

    public DashboardService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    private BigDecimal one(String sql, Object... args) {
        BigDecimal v = jdbc.queryForObject(sql, BigDecimal.class, args);
        return v == null ? BigDecimal.ZERO : v;
    }

    /** debit-minus-credit of the given heads within a date range. */
    private BigDecimal net(String headFilter, LocalDate from, LocalDate to) {
        return one("select coalesce(sum(l.debit - l.credit), 0) from mis_journal_line l join mis_journal j on j.id = l.journal_id where "
                + headFilter + " and j.journal_date between ? and ?", Date.valueOf(from), Date.valueOf(to));
    }

    private BigDecimal grossProfit(LocalDate from, LocalDate to) {
        return net("l.head_code in ('4000','4100')", from, to).negate()
                .subtract(net("l.head_code in ('5000','5100')", from, to));
    }

    public Map<String, Object> summary() {
        LocalDate today = LocalDate.now();
        LocalDate monthStart = today.withDayOfMonth(1);
        Map<String, Object> m = new LinkedHashMap<>();

        BigDecimal todayNetSales = net("l.head_code in ('4000','4100')", today, today).negate();
        m.put("todaySales", todayNetSales);
        m.put("todayInvoices", jdbc.queryForObject("select count(*) from mis_sale where sale_date = ?", Long.class, Date.valueOf(today)));
        m.put("todayCollections", one("select coalesce(sum(x), 0) from (select paid_at_sale as x from mis_sale where sale_date = ? "
                + "union all select amount from mis_receipt where receipt_date = ?) t", Date.valueOf(today), Date.valueOf(today)));
        m.put("totalReceivables", one("select coalesce(sum(debit - credit), 0) from mis_journal_line where head_code = '1200'"));
        m.put("totalPayables", one("select coalesce(sum(credit - debit), 0) from mis_journal_line where head_code = '2100'"));
        m.put("stockValue", one("select coalesce(sum(mv.qty * b.unit_cost), 0) from mis_stock_movement mv join mis_batch b on b.id = mv.batch_id"));
        m.put("todayProfit", grossProfit(today, today));
        m.put("monthlySales", net("l.head_code in ('4000','4100')", monthStart, today).negate());
        m.put("monthlyGrossProfit", grossProfit(monthStart, today));
        BigDecimal opex = net("l.head_code in (select code from mis_head where type = 'EXPENSE')", monthStart, today);
        BigDecimal otherIncome = net("l.head_code = '4900'", monthStart, today).negate();
        m.put("monthlyProfit", grossProfit(monthStart, today).subtract(opex).add(otherIncome));
        m.put("monthlyExpenses", opex);
        m.put("cashBalance", one("select coalesce(sum(l.debit - l.credit), 0) from mis_journal_line l join mis_account a on a.head_code = l.head_code where a.type = 'CASH'"));
        m.put("bankBalance", one("select coalesce(sum(l.debit - l.credit), 0) from mis_journal_line l join mis_account a on a.head_code = l.head_code where a.type = 'BANK'"));

        List<Map<String, Object>> low = new ArrayList<>(jdbc.queryForList("""
                select pr.id as id, pr.sku as sku, pr.name as name, u.name as unit, coalesce(m.q, 0) as on_hand, pr.min_stock as min_stock
                from mis_product pr join mis_unit u on u.id = pr.base_unit_id
                left join (select product_id, sum(qty) as q from mis_stock_movement group by product_id) m on m.product_id = pr.id
                where pr.active = true and coalesce(m.q, 0) <= pr.min_stock order by coalesce(m.q, 0) - pr.min_stock limit 8"""));
        m.put("lowStock", lower(low));
        m.put("lowStockCount", jdbc.queryForObject("""
                select count(*) from mis_product pr
                left join (select product_id, sum(qty) as q from mis_stock_movement group by product_id) m on m.product_id = pr.id
                where pr.active = true and coalesce(m.q, 0) <= pr.min_stock""", Long.class));

        List<Map<String, Object>> recent = lower(jdbc.queryForList("""
                select j.journal_date as dt, j.source_type as type, j.source_no as ref, j.narration as narration,
                       (select coalesce(sum(l.debit), 0) from mis_journal_line l where l.journal_id = j.id) as amount
                from mis_journal j where j.source_type not like 'OPENING%' order by j.id desc limit 10"""));
        m.put("recent", recent);

        // Net sales per day for the last 14 days.
        List<Map<String, Object>> trend = new ArrayList<>();
        Map<LocalDate, BigDecimal> byDay = new LinkedHashMap<>();
        for (int i = 13; i >= 0; i--) byDay.put(today.minusDays(i), BigDecimal.ZERO);
        for (Map<String, Object> r : lower(jdbc.queryForList("""
                select j.journal_date as dt, sum(l.credit - l.debit) as v from mis_journal_line l join mis_journal j on j.id = l.journal_id
                where l.head_code in ('4000','4100') and j.journal_date between ? and ? group by j.journal_date""",
                Date.valueOf(today.minusDays(13)), Date.valueOf(today)))) {
            byDay.put((LocalDate) r.get("dt"), (BigDecimal) r.get("v"));
        }
        byDay.forEach((d, v) -> trend.add(Map.of("day", d.toString(), "sales", v)));
        m.put("salesTrend", trend);
        return m;
    }

    private static List<Map<String, Object>> lower(List<Map<String, Object>> rows) {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Map<String, Object> r : rows) {
            Map<String, Object> n = new LinkedHashMap<>();
            r.forEach((k, v) -> n.put(k.toLowerCase(), v instanceof Date d ? d.toLocalDate() : v));
            out.add(n);
        }
        return out;
    }
}
