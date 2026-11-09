package com.portside.trading.service;

import static com.portside.trading.web.dto.ReportResult.*;

import com.portside.trading.web.dto.ReportResult;
import com.portside.trading.web.dto.ReportResult.Col;
import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Every report in the system, built from the transaction tables and the journal. Inputs: date range, optional id/search. */
@Service
@Transactional(readOnly = true)
public class ReportService {

    /** Report codes that expose cost, profit or the books and therefore need the finance permission. */
    public static final java.util.Set<String> FINANCIAL = java.util.Set.of(
            "profit-loss", "gross-profit", "net-profit", "expense-report", "cash-book", "bank-book", "cash-flow",
            "trial-balance", "balance-sheet", "payables", "supplier-ledger", "supplier-transactions",
            "supplier-payment-history", "stock-valuation");

    private final JdbcTemplate jdbc;
    private final LedgerService ledger;

    public ReportService(JdbcTemplate jdbc, LedgerService ledger) {
        this.jdbc = jdbc;
        this.ledger = ledger;
    }

    public record Params(LocalDate from, LocalDate to, Long id, String q, String type) {
        LocalDate fromOrDefault() { return from != null ? from : LocalDate.now().withDayOfMonth(1); }
        LocalDate toOrDefault() { return to != null ? to : LocalDate.now(); }
        String like() { return q == null || q.isBlank() ? null : "%" + q.trim().toLowerCase() + "%"; }
    }

    public ReportResult run(String code, Params p) {
        return switch (code) {
            case "daily-sales" -> dailySales(p);
            case "monthly-sales" -> monthlySales(p);
            case "customer-wise-sales" -> customerWiseSales(p);
            case "product-wise-sales", "gross-profit" -> productWiseSales(p, code);
            case "wholesale-sales" -> invoiceReport(p, "wholesale-sales", "Wholesale sales", "WHOLESALE");
            case "retail-sales" -> invoiceReport(p, "retail-sales", "Retail sales", "RETAIL");
            case "sales-by-invoice", "invoice-profit" -> invoiceReport(p, code, "Sales by invoice (invoice-wise profit)", null);
            case "sales-by-range" -> salesDetail(p);
            case "sales-returns" -> salesReturns(p);
            case "container-wise-sales" -> containerSales(p);
            case "container-product-sales" -> containerProductSales(p);
            case "current-stock" -> currentStock(p, false, false);
            case "stock-valuation" -> currentStock(p, true, false);
            case "low-stock" -> currentStock(p, false, true);
            case "product-wise-stock" -> productWiseStock(p);
            case "batch-wise-stock" -> batchWiseStock(p);
            case "stock-received" -> stockReceived(p);
            case "stock-sold" -> movements(p, "stock-sold", "Stock sold", "'SALE'");
            case "stock-adjustments" -> movements(p, "stock-adjustments", "Stock adjustments", "'DAMAGED','MISSING','CORRECTION','OTHER_ADJUSTMENT'");
            case "damaged-stock" -> movements(p, "damaged-stock", "Damaged stock", "'DAMAGED'");
            case "stock-movement" -> movements(p, "stock-movement", "Stock movement / history", null);
            case "customer-ledger" -> ledger.customerLedger(req(p.id(), "customer"), p.from(), p.to());
            case "customer-balances" -> customerBalances(p);
            case "receivables" -> receivables(p);
            case "overdue" -> overdue(p);
            case "customer-payment-history" -> customerPayments(p);
            case "supplier-ledger" -> ledger.supplierLedger(req(p.id(), "supplier"), p.from(), p.to());
            case "payables" -> payables(p);
            case "supplier-transactions" -> supplierTransactions(p);
            case "supplier-payment-history" -> supplierPayments(p);
            case "profit-loss" -> profitLoss(p);
            case "net-profit" -> netProfitTrend(p);
            case "expense-report" -> expenseReport(p);
            case "cash-book" -> cashBook(p, "CASH", "cash-book", "Cash book");
            case "bank-book" -> cashBook(p, "BANK", "bank-book", "Bank book");
            case "cash-flow" -> cashFlow(p);
            case "trial-balance" -> trialBalance(p);
            case "balance-sheet" -> balanceSheet(p);
            default -> throw new IllegalArgumentException("Unknown report " + code);
        };
    }

    // ---------------------------------------------------------------- helpers

    private static Long req(Long id, String what) {
        if (id == null) throw new IllegalArgumentException("Select a " + what);
        return id;
    }

    private static Date sql(LocalDate d) {
        return Date.valueOf(d);
    }

    /** Runs a query and returns rows keyed by lower-case column label (H2 and MySQL differ in label case). */
    List<Map<String, Object>> q(String sql, Object... args) {
        List<Map<String, Object>> raw = jdbc.queryForList(sql, args);
        List<Map<String, Object>> out = new ArrayList<>(raw.size());
        for (Map<String, Object> r : raw) {
            Map<String, Object> m = new LinkedHashMap<>();
            r.forEach((k, v) -> m.put(k.toLowerCase(), v instanceof Date d ? d.toLocalDate() : v));
            out.add(m);
        }
        return out;
    }

    private static BigDecimal bd(Object o) {
        if (o == null) return BigDecimal.ZERO;
        if (o instanceof BigDecimal b) return b;
        if (o instanceof Number n) return new BigDecimal(n.toString());
        return new BigDecimal(o.toString());
    }

    private static BigDecimal sum(List<Map<String, Object>> rows, String key) {
        BigDecimal s = BigDecimal.ZERO;
        for (Map<String, Object> r : rows) s = s.add(bd(r.get(key)));
        return s;
    }

    private static Map<String, Object> totals(List<Map<String, Object>> rows, String... keys) {
        Map<String, Object> t = new LinkedHashMap<>();
        for (String k : keys) t.put(k, sum(rows, k));
        return t;
    }

    private static String period(Params p) {
        return p.fromOrDefault() + " to " + p.toOrDefault();
    }

    private static final String SALE_RANGE = " s.sale_date between ? and ? ";

    // ---------------------------------------------------------------- sales

    private ReportResult dailySales(Params p) {
        var rows = q("""
                select s.sale_date as dt, count(*) as invoices, sum(s.gross_amount) as gross, sum(s.discount_total) as discount,
                       sum(s.returned_net) as returns, sum(s.gross_amount - s.discount_total - s.returned_net) as net_sales,
                       sum(s.tax_total) as tax, sum(s.total) as total,
                       sum(s.cogs_total - s.returned_cogs) as cogs,
                       sum(s.gross_amount - s.discount_total - s.returned_net - (s.cogs_total - s.returned_cogs)) as profit
                from mis_sale s where""" + SALE_RANGE + "group by s.sale_date order by s.sale_date",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("daily-sales", "Daily sales", period(p),
                List.of(date("dt", "Date"), integer("invoices", "Invoices"), money("gross", "Gross"), money("discount", "Discount"),
                        money("returns", "Returns"), money("net_sales", "Net sales"), money("tax", "Tax"), money("total", "Invoice total"),
                        money("cogs", "Cost"), money("profit", "Profit")),
                rows, totals(rows, "invoices", "gross", "discount", "returns", "net_sales", "tax", "total", "cogs", "profit"));
    }

    private ReportResult monthlySales(Params p) {
        var raw = q("""
                select year(s.sale_date) as y, month(s.sale_date) as m, count(*) as invoices, sum(s.gross_amount) as gross,
                       sum(s.discount_total) as discount, sum(s.returned_net) as returns,
                       sum(s.gross_amount - s.discount_total - s.returned_net) as net_sales, sum(s.tax_total) as tax,
                       sum(s.cogs_total - s.returned_cogs) as cogs,
                       sum(s.gross_amount - s.discount_total - s.returned_net - (s.cogs_total - s.returned_cogs)) as profit
                from mis_sale s where""" + SALE_RANGE + "group by year(s.sale_date), month(s.sale_date) order by 1, 2",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        for (var r : raw) r.put("month", String.format("%04d-%02d", ((Number) r.get("y")).intValue(), ((Number) r.get("m")).intValue()));
        return new ReportResult("monthly-sales", "Monthly sales", period(p),
                List.of(text("month", "Month"), integer("invoices", "Invoices"), money("gross", "Gross"), money("discount", "Discount"),
                        money("returns", "Returns"), money("net_sales", "Net sales"), money("tax", "Tax"), money("cogs", "Cost"), money("profit", "Profit")),
                raw, totals(raw, "invoices", "gross", "discount", "returns", "net_sales", "tax", "cogs", "profit"));
    }

    private ReportResult customerWiseSales(Params p) {
        var rows = q("""
                select c.code as code, c.name as customer, c.type as type, count(*) as invoices, sum(s.gross_amount - s.discount_total) as sales,
                       sum(s.returned_net) as returns, sum(s.gross_amount - s.discount_total - s.returned_net) as net_sales,
                       sum(s.gross_amount - s.discount_total - s.returned_net - (s.cogs_total - s.returned_cogs)) as profit
                from mis_sale s join mis_customer c on c.id = s.customer_id where""" + SALE_RANGE
                + "group by c.id, c.code, c.name, c.type order by net_sales desc", sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("customer-wise-sales", "Customer-wise sales", period(p),
                List.of(text("code", "Code"), text("customer", "Customer"), text("type", "Type"), integer("invoices", "Invoices"),
                        money("sales", "Sales"), money("returns", "Returns"), money("net_sales", "Net sales"), money("profit", "Profit")),
                rows, totals(rows, "invoices", "sales", "returns", "net_sales", "profit"));
    }

    private ReportResult productWiseSales(Params p, String code) {
        var rows = q("""
                select pr.sku as sku, pr.name as product, u.name as unit, sum(l.base_qty - l.returned_base_qty) as qty,
                       sum(l.net_amount * (l.base_qty - l.returned_base_qty) / l.base_qty) as net_sales,
                       sum((l.base_qty - l.returned_base_qty) * l.unit_cost) as cost
                from mis_sale_line l join mis_sale s on s.id = l.sale_id join mis_product pr on pr.id = l.product_id
                     join mis_unit u on u.id = pr.base_unit_id
                where""" + SALE_RANGE + "group by pr.id, pr.sku, pr.name, u.name order by net_sales desc",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        for (var r : rows) {
            BigDecimal net = bd(r.get("net_sales")).setScale(2, java.math.RoundingMode.HALF_UP);
            BigDecimal cost = bd(r.get("cost")).setScale(2, java.math.RoundingMode.HALF_UP);
            r.put("net_sales", net);
            r.put("cost", cost);
            r.put("profit", net.subtract(cost));
            r.put("margin", net.signum() == 0 ? BigDecimal.ZERO : net.subtract(cost).divide(net, 4, java.math.RoundingMode.HALF_UP));
        }
        return new ReportResult(code, code.equals("gross-profit") ? "Gross profit by product" : "Product-wise sales & profit",
                period(p) + " - net of returns, at batch cost",
                List.of(text("sku", "Code"), text("product", "Product"), text("unit", "Unit"), qty("qty", "Qty sold"),
                        money("net_sales", "Net sales"), money("cost", "Cost"), money("profit", "Gross profit"), pct("margin", "Margin")),
                rows, totals(rows, "qty", "net_sales", "cost", "profit"));
    }

    private ReportResult invoiceReport(Params p, String code, String title, String type) {
        String like = p.like();
        var rows = q("""
                select s.sale_date as dt, s.invoice_no as invoice, c.name as customer, s.type as type, s.total as total,
                       s.paid_amount as paid, s.returned_amount as returned,
                       (s.total - s.paid_amount - s.returned_amount) as balance,
                       (s.gross_amount - s.discount_total - s.returned_net) as net_sales,
                       (s.cogs_total - s.returned_cogs) as cost,
                       (s.gross_amount - s.discount_total - s.returned_net - (s.cogs_total - s.returned_cogs)) as profit
                from mis_sale s join mis_customer c on c.id = s.customer_id
                where""" + SALE_RANGE
                + (type != null ? " and s.type = '" + type + "' " : "")
                + (like != null ? " and (lower(s.invoice_no) like ? or lower(c.name) like ?) " : "")
                + " order by s.sale_date desc, s.id desc",
                like != null ? new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault()), like, like}
                        : new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault())});
        for (var r : rows) {
            BigDecimal net = bd(r.get("net_sales"));
            r.put("margin", net.signum() == 0 ? BigDecimal.ZERO : bd(r.get("profit")).divide(net, 4, java.math.RoundingMode.HALF_UP));
            BigDecimal bal = bd(r.get("balance"));
            if (bal.signum() < 0) r.put("balance", BigDecimal.ZERO);
        }
        return new ReportResult(code, title, period(p),
                List.of(date("dt", "Date"), text("invoice", "Invoice"), text("customer", "Customer"), text("type", "Type"),
                        money("total", "Total"), money("returned", "Returned"), money("paid", "Paid"), money("balance", "Balance"),
                        money("net_sales", "Net sales"), money("cost", "Cost"), money("profit", "Profit"), pct("margin", "Margin")),
                rows, totals(rows, "total", "returned", "paid", "balance", "net_sales", "cost", "profit"));
    }

    private ReportResult salesDetail(Params p) {
        String like = p.like();
        var rows = q("""
                select s.sale_date as dt, s.invoice_no as invoice, c.name as customer, pr.sku as sku, pr.name as product,
                       b.batch_no as batch, l.qty as qty, u.name as unit, l.rate as rate, l.discount as discount,
                       l.net_amount as net, l.tax_amount as tax, l.line_total as total
                from mis_sale_line l join mis_sale s on s.id = l.sale_id join mis_customer c on c.id = s.customer_id
                     join mis_product pr on pr.id = l.product_id join mis_batch b on b.id = l.batch_id join mis_unit u on u.id = l.unit_id
                where""" + SALE_RANGE
                + (like != null ? " and (lower(s.invoice_no) like ? or lower(c.name) like ? or lower(pr.name) like ? or lower(pr.sku) like ?) " : "")
                + " order by s.sale_date desc, s.id desc, l.id",
                like != null ? new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault()), like, like, like, like}
                        : new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault())});
        return new ReportResult("sales-by-range", "Sales by date range", period(p),
                List.of(date("dt", "Date"), text("invoice", "Invoice"), text("customer", "Customer"), text("sku", "Code"), text("product", "Product"),
                        text("batch", "Batch"), qty("qty", "Qty"), text("unit", "Unit"), money("rate", "Rate"), money("discount", "Discount"),
                        money("net", "Net"), money("tax", "Tax"), money("total", "Total")),
                rows, totals(rows, "discount", "net", "tax", "total"));
    }

    private ReportResult salesReturns(Params p) {
        var rows = q("""
                select r.return_date as dt, r.return_no as ret, s.invoice_no as invoice, c.name as customer, r.net_amount as net,
                       r.tax_amount as tax, r.total as total, r.refund_amount as refund, r.cogs_total as cost, r.notes as notes
                from mis_sale_return r join mis_sale s on s.id = r.sale_id join mis_customer c on c.id = r.customer_id
                where r.return_date between ? and ? order by r.return_date desc, r.id desc""",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("sales-returns", "Sales returns", period(p),
                List.of(date("dt", "Date"), text("ret", "Return no"), text("invoice", "Invoice"), text("customer", "Customer"),
                        money("net", "Net"), money("tax", "Tax"), money("total", "Return value"), money("refund", "Refunded"),
                        money("cost", "Cost reversed"), text("notes", "Notes")),
                rows, totals(rows, "net", "tax", "total", "refund", "cost"));
    }

    /** Sales and returns grouped by the container the stock came from; sale/return dates fall in the chosen period. */
    private ReportResult containerSales(Params p) {
        Object[] range = {sql(p.fromOrDefault()), sql(p.toOrDefault())};
        var containers = q("""
                select h.id as hid, h.container_no as container, h.shipment_no as receiving, h.arrival_date as arrival, sp.name as supplier,
                       h.total_cost as stock_cost, coalesce(sum(mv.qty * b.unit_cost), 0) as on_hand_value
                from mis_shipment h join mis_supplier sp on sp.id = h.supplier_id join mis_batch b on b.shipment_id = h.id
                     left join mis_stock_movement mv on mv.batch_id = b.id
                group by h.id, h.container_no, h.shipment_no, h.arrival_date, sp.name, h.total_cost
                order by h.arrival_date desc, h.id desc""");
        Map<Object, Map<String, Object>> sold = new LinkedHashMap<>();
        for (var r : q("""
                select b.shipment_id as hid, count(distinct s.id) as invoices, sum(l.net_amount) as sales, sum(l.base_qty * l.unit_cost) as cost
                from mis_sale_line l join mis_sale s on s.id = l.sale_id join mis_batch b on b.id = l.batch_id
                where""" + SALE_RANGE + "group by b.shipment_id", range)) sold.put(r.get("hid"), r);
        Map<Object, Map<String, Object>> back = new LinkedHashMap<>();
        for (var r : q("""
                select b.shipment_id as hid, count(distinct sr.id) as returns_count, sum(rl.net_amount) as returns, sum(rl.base_qty * rl.unit_cost) as cost
                from mis_sale_return_line rl join mis_sale_return sr on sr.id = rl.sale_return_id join mis_batch b on b.id = rl.batch_id
                where sr.return_date between ? and ? group by b.shipment_id""", range)) back.put(r.get("hid"), r);
        for (var c : containers) {
            var s = sold.get(c.get("hid"));
            var b = back.get(c.get("hid"));
            BigDecimal sales = s == null ? BigDecimal.ZERO : bd(s.get("sales"));
            BigDecimal returns = b == null ? BigDecimal.ZERO : bd(b.get("returns"));
            BigDecimal cost = (s == null ? BigDecimal.ZERO : bd(s.get("cost"))).subtract(b == null ? BigDecimal.ZERO : bd(b.get("cost")));
            BigDecimal net = sales.subtract(returns);
            c.put("invoices", s == null ? 0 : s.get("invoices"));
            c.put("returns_count", b == null ? 0 : b.get("returns_count"));
            c.put("sales", sales);
            c.put("returns", returns);
            c.put("net_sales", net);
            c.put("cost", cost);
            c.put("profit", net.subtract(cost));
            c.put("margin", net.signum() == 0 ? BigDecimal.ZERO : net.subtract(cost).divide(net, 4, java.math.RoundingMode.HALF_UP));
            BigDecimal stockCost = bd(c.get("stock_cost"));
            c.put("sold_through", stockCost.signum() == 0 ? BigDecimal.ZERO : cost.divide(stockCost, 4, java.math.RoundingMode.HALF_UP));
        }
        return new ReportResult("container-wise-sales", "Container-wise sales & returns", period(p) + " - sales and returns booked in the period, at batch cost",
                List.of(text("container", "Container"), text("receiving", "Receiving"), date("arrival", "Arrived"), text("supplier", "Supplier"),
                        money("stock_cost", "Container cost"), integer("invoices", "Invoices"), money("sales", "Sales"), integer("returns_count", "Returns"),
                        money("returns", "Returned value"), money("net_sales", "Net sales"), money("cost", "Cost of sales"), money("profit", "Profit"),
                        pct("margin", "Margin"), pct("sold_through", "Sold through"), money("on_hand_value", "Stock left (cost)")),
                containers, totals(containers, "stock_cost", "invoices", "sales", "returns_count", "returns", "net_sales", "cost", "profit", "on_hand_value"));
    }

    /** One row per product batch inside each container: received, sold, returned, remaining and profit. */
    private ReportResult containerProductSales(Params p) {
        String like = p.like();
        Object[] range = {sql(p.fromOrDefault()), sql(p.toOrDefault())};
        var rows = q("""
                select b.id as bid, h.container_no as container, b.batch_no as batch, pr.sku as sku, pr.name as product, u.name as unit,
                       b.received_qty as received, coalesce(sum(mv.qty), 0) as on_hand
                from mis_batch b join mis_shipment h on h.id = b.shipment_id join mis_product pr on pr.id = b.product_id
                     join mis_unit u on u.id = pr.base_unit_id left join mis_stock_movement mv on mv.batch_id = b.id
                where 1 = 1""" + (like != null ? " and (lower(h.container_no) like ? or lower(pr.name) like ? or lower(pr.sku) like ?) " : "")
                + " group by b.id, h.container_no, b.batch_no, pr.sku, pr.name, u.name, b.received_qty, h.arrival_date, h.id order by h.arrival_date desc, h.id desc, pr.name",
                like != null ? new Object[]{like, like, like} : new Object[0]);
        Map<Object, Map<String, Object>> sold = new LinkedHashMap<>();
        for (var r : q("""
                select l.batch_id as bid, sum(l.base_qty) as qty, sum(l.net_amount) as sales, sum(l.base_qty * l.unit_cost) as cost
                from mis_sale_line l join mis_sale s on s.id = l.sale_id where""" + SALE_RANGE + "group by l.batch_id", range)) sold.put(r.get("bid"), r);
        Map<Object, Map<String, Object>> back = new LinkedHashMap<>();
        for (var r : q("""
                select rl.batch_id as bid, sum(rl.base_qty) as qty, sum(rl.net_amount) as returns, sum(rl.base_qty * rl.unit_cost) as cost
                from mis_sale_return_line rl join mis_sale_return sr on sr.id = rl.sale_return_id
                where sr.return_date between ? and ? group by rl.batch_id""", range)) back.put(r.get("bid"), r);
        for (var r : rows) {
            var s = sold.get(r.get("bid"));
            var b = back.get(r.get("bid"));
            BigDecimal sales = s == null ? BigDecimal.ZERO : bd(s.get("sales"));
            BigDecimal returns = b == null ? BigDecimal.ZERO : bd(b.get("returns"));
            BigDecimal cost = (s == null ? BigDecimal.ZERO : bd(s.get("cost"))).subtract(b == null ? BigDecimal.ZERO : bd(b.get("cost")));
            r.put("sold_qty", s == null ? BigDecimal.ZERO : s.get("qty"));
            r.put("returned_qty", b == null ? BigDecimal.ZERO : b.get("qty"));
            r.put("sales", sales);
            r.put("returns", returns);
            r.put("net_sales", sales.subtract(returns));
            r.put("cost", cost);
            r.put("profit", sales.subtract(returns).subtract(cost));
        }
        return new ReportResult("container-product-sales", "Container-wise sales detail (by product)", period(p) + " - each product batch within each container",
                List.of(text("container", "Container"), text("batch", "Batch"), text("sku", "Code"), text("product", "Product"), text("unit", "Unit"),
                        qty("received", "Received"), qty("sold_qty", "Sold"), qty("returned_qty", "Returned"), qty("on_hand", "On hand"),
                        money("sales", "Sales"), money("returns", "Returned value"), money("net_sales", "Net sales"), money("cost", "Cost"), money("profit", "Profit")),
                rows, totals(rows, "sales", "returns", "net_sales", "cost", "profit"));
    }

    // ---------------------------------------------------------------- inventory

    private ReportResult currentStock(Params p, boolean valuation, boolean lowOnly) {
        String like = p.like();
        var rows = q("""
                select pr.id as id, pr.sku as sku, pr.name as product, pr.category as category, u.name as unit,
                       coalesce(m.qty, 0) as on_hand, pr.min_stock as min_stock, coalesce(m.val, 0) as val,
                       case when pr.active then 'Active' else 'Inactive' end as status
                from mis_product pr join mis_unit u on u.id = pr.base_unit_id
                left join (select mv.product_id as product_id, sum(mv.qty) as qty, sum(mv.qty * b.unit_cost) as val
                           from mis_stock_movement mv join mis_batch b on b.id = mv.batch_id group by mv.product_id) m on m.product_id = pr.id
                where 1 = 1""" + (like != null ? " and (lower(pr.name) like ? or lower(pr.sku) like ?) " : "") + " order by pr.name",
                like != null ? new Object[]{like, like} : new Object[0]);
        if (lowOnly) rows.removeIf(r -> !("Active".equals(r.get("status")) && bd(r.get("on_hand")).compareTo(bd(r.get("min_stock"))) <= 0));
        for (var r : rows) {
            BigDecimal qty = bd(r.get("on_hand"));
            r.put("avg_cost", qty.signum() > 0 ? bd(r.get("val")).divide(qty, 2, java.math.RoundingMode.HALF_UP) : BigDecimal.ZERO);
            r.put("flag", qty.compareTo(bd(r.get("min_stock"))) <= 0 ? "Low" : "OK");
        }
        List<Col> cols = new ArrayList<>(List.of(text("sku", "Code"), text("product", "Product"), text("category", "Category"),
                text("unit", "Unit"), qty("on_hand", "On hand"), qty("min_stock", "Min stock")));
        if (valuation) { cols.add(money("avg_cost", "Avg cost")); cols.add(money("val", "Stock value")); }
        else { cols.add(text("flag", "Level")); cols.add(text("status", "Status")); }
        return new ReportResult(lowOnly ? "low-stock" : valuation ? "stock-valuation" : "current-stock",
                lowOnly ? "Low-stock products" : valuation ? "Stock valuation (at batch cost)" : "Current stock", "As of today",
                cols, rows, valuation ? totals(rows, "val") : totals(rows, "on_hand"));
    }

    private ReportResult productWiseStock(Params p) {
        var rows = q("""
                select pr.sku as sku, pr.name as product, u.name as unit,
                       coalesce(sum(case when mv.type = 'RECEIPT' then mv.qty end), 0) as received,
                       coalesce(-sum(case when mv.type = 'SALE' then mv.qty end), 0) as sold,
                       coalesce(sum(case when mv.type = 'SALE_RETURN' then mv.qty end), 0) as returned,
                       coalesce(-sum(case when mv.type in ('DAMAGED','MISSING') then mv.qty end), 0) as damaged,
                       coalesce(sum(case when mv.type in ('CORRECTION','OTHER_ADJUSTMENT') then mv.qty end), 0) as adjustments,
                       coalesce(sum(mv.qty), 0) as available
                from mis_product pr join mis_unit u on u.id = pr.base_unit_id
                left join mis_stock_movement mv on mv.product_id = pr.id and mv.move_date <= ?
                group by pr.id, pr.sku, pr.name, u.name order by pr.name""", sql(p.toOrDefault()));
        return new ReportResult("product-wise-stock", "Product-wise stock position", "Up to " + p.toOrDefault(),
                List.of(text("sku", "Code"), text("product", "Product"), text("unit", "Unit"), qty("received", "Received"), qty("sold", "Sold"),
                        qty("returned", "Returned"), qty("damaged", "Damaged / missing"), qty("adjustments", "Adjustments"), qty("available", "Available")),
                rows, totals(rows, "received", "sold", "returned", "damaged", "adjustments", "available"));
    }

    private ReportResult batchWiseStock(Params p) {
        String like = p.like();
        var rows = q("""
                select b.id as batch_id, b.batch_no as batch, h.shipment_no as shipment, h.container_no as container, h.arrival_date as arrival, sp.name as supplier, pr.sku as sku,
                       pr.name as product, u.name as unit, b.received_qty as received, b.unit_cost as cost,
                       coalesce(-sum(case when mv.type = 'SALE' then mv.qty end), 0) as sold,
                       coalesce(sum(case when mv.type = 'SALE_RETURN' then mv.qty end), 0) as returned,
                       coalesce(sum(case when mv.type in ('DAMAGED','MISSING','CORRECTION','OTHER_ADJUSTMENT') then mv.qty end), 0) as adjusted,
                       coalesce(sum(mv.qty), 0) as on_hand
                from mis_batch b join mis_shipment h on h.id = b.shipment_id join mis_supplier sp on sp.id = h.supplier_id
                     join mis_product pr on pr.id = b.product_id join mis_unit u on u.id = pr.base_unit_id
                     left join mis_stock_movement mv on mv.batch_id = b.id
                where 1 = 1""" + (like != null ? " and (lower(b.batch_no) like ? or lower(h.shipment_no) like ? or lower(h.container_no) like ? or lower(pr.name) like ? or lower(pr.sku) like ?) " : "")
                + (p.id() != null ? " and pr.id = " + p.id() : "")
                + " group by b.id, b.batch_no, h.shipment_no, h.container_no, h.arrival_date, sp.name, pr.sku, pr.name, u.name, b.received_qty, b.unit_cost "
                + " order by pr.name, h.arrival_date, b.id",
                like != null ? new Object[]{like, like, like, like, like} : new Object[0]);
        for (var r : rows) r.put("value", bd(r.get("on_hand")).multiply(bd(r.get("cost"))).setScale(2, java.math.RoundingMode.HALF_UP));
        return new ReportResult("batch-wise-stock", "Batch-wise stock", "Each batch carries its own manually entered cost",
                List.of(text("batch", "Batch"), text("container", "Container"), text("shipment", "Receiving"), date("arrival", "Arrived"), text("supplier", "Supplier"),
                        text("sku", "Code"), text("product", "Product"), qty("received", "Received"), qty("sold", "Sold"), qty("returned", "Returned"),
                        qty("adjusted", "Adjusted"), qty("on_hand", "On hand"), money("cost", "Unit cost"), money("value", "Value")),
                rows, totals(rows, "received", "sold", "returned", "adjusted", "on_hand", "value"));
    }

    private ReportResult stockReceived(Params p) {
        String like = p.like();
        var rows = q("""
                select h.arrival_date as dt, h.shipment_no as shipment, b.batch_no as batch, sp.name as supplier, pr.sku as sku, pr.name as product,
                       b.entered_qty as qty, eu.name as unit, b.entered_unit_cost as cost, (b.entered_qty * b.entered_unit_cost) as val,
                       w.name as warehouse
                from mis_batch b join mis_shipment h on h.id = b.shipment_id join mis_supplier sp on sp.id = h.supplier_id
                     join mis_product pr on pr.id = b.product_id join mis_unit eu on eu.id = b.entered_unit_id
                     join mis_warehouse w on w.id = h.warehouse_id
                where h.arrival_date between ? and ? """
                + (like != null ? " and (lower(b.batch_no) like ? or lower(h.shipment_no) like ? or lower(pr.name) like ? or lower(sp.name) like ?) " : "")
                + " order by h.arrival_date desc, b.id",
                like != null ? new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault()), like, like, like, like}
                        : new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault())});
        return new ReportResult("stock-received", "Stock received", period(p),
                List.of(date("dt", "Arrived"), text("shipment", "Shipment"), text("batch", "Batch"), text("supplier", "Supplier"), text("sku", "Code"),
                        text("product", "Product"), qty("qty", "Qty"), text("unit", "Unit"), money("cost", "Unit cost"), money("val", "Value"),
                        text("warehouse", "Warehouse")),
                rows, totals(rows, "val"));
    }

    private ReportResult movements(Params p, String code, String title, String types) {
        String like = p.like();
        var rows = q("""
                select mv.move_date as dt, mv.type as type, pr.sku as sku, pr.name as product, b.batch_no as batch, mv.qty as qty,
                       mv.unit_cost as cost, (mv.qty * mv.unit_cost) as val, mv.ref_no as ref, mv.reason as reason, mv.created_by as by_user
                from mis_stock_movement mv join mis_product pr on pr.id = mv.product_id join mis_batch b on b.id = mv.batch_id
                where mv.move_date between ? and ? """
                + (types != null ? " and mv.type in (" + types + ") " : "")
                + (p.id() != null ? " and pr.id = " + p.id() + " " : "")
                + (p.type() != null && !p.type().isBlank() ? " and mv.type = '" + p.type().replaceAll("[^A-Z_]", "") + "' " : "")
                + (like != null ? " and (lower(pr.name) like ? or lower(pr.sku) like ? or lower(b.batch_no) like ? or lower(mv.ref_no) like ?) " : "")
                + " order by mv.move_date desc, mv.id desc",
                like != null ? new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault()), like, like, like, like}
                        : new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault())});
        return new ReportResult(code, title, period(p),
                List.of(date("dt", "Date"), text("type", "Type"), text("sku", "Code"), text("product", "Product"), text("batch", "Batch"),
                        qty("qty", "Qty (+/-)"), money("cost", "Unit cost"), money("val", "Value"), text("ref", "Reference"),
                        text("reason", "Reason"), text("by_user", "By")),
                rows, totals(rows, "qty", "val"));
    }

    // ---------------------------------------------------------------- customers

    private ReportResult customerBalances(Params p) {
        var rows = customerPositions(p.like());
        return new ReportResult("customer-balances", "Customer balances", "As of today",
                List.of(text("code", "Code"), text("customer", "Customer"), text("type", "Type"), text("phone", "Phone"),
                        money("opening", "Opening"), money("sales", "Sales"), money("payments", "Payments"), money("returns", "Returns"),
                        money("adjustments", "Adjustments"), money("balance", "Balance"), money("credit_limit", "Credit limit")),
                rows, totals(rows, "opening", "sales", "payments", "returns", "adjustments", "balance"));
    }

    private List<Map<String, Object>> customerPositions(String like) {
        var rows = q("""
                select c.id as id, c.code as code, c.name as customer, c.type as type, c.phone as phone, c.credit_limit as credit_limit,
                       c.opening_balance as opening,
                       coalesce((select sum(s.total) from mis_sale s where s.customer_id = c.id), 0) as sales,
                       coalesce((select sum(s.paid_at_sale) from mis_sale s where s.customer_id = c.id), 0)
                         + coalesce((select sum(r.amount) from mis_receipt r where r.customer_id = c.id), 0) as payments,
                       coalesce((select sum(x.total - x.refund_amount) from mis_sale_return x where x.customer_id = c.id), 0) as returns,
                       coalesce((select sum(a.amount) from mis_party_adjustment a where a.party_type = 'CUSTOMER' and a.party_id = c.id), 0) as adjustments
                from mis_customer c where c.walk_in = false""" + (like != null ? " and (lower(c.name) like ? or lower(c.code) like ?) " : "") + " order by c.name",
                like != null ? new Object[]{like, like} : new Object[0]);
        for (var r : rows) {
            r.put("balance", bd(r.get("opening")).add(bd(r.get("sales"))).subtract(bd(r.get("payments"))).subtract(bd(r.get("returns"))).add(bd(r.get("adjustments"))));
        }
        return rows;
    }

    private record OpenInvoice(long customerId, String customer, String invoice, LocalDate date, LocalDate due, BigDecimal outstanding) {}

    private List<OpenInvoice> openInvoices(Long customerId) {
        var rows = q("""
                select s.customer_id as cid, c.name as customer, s.invoice_no as invoice, s.sale_date as dt, c.credit_days as days,
                       (s.total - s.paid_amount - s.returned_amount) as outstanding
                from mis_sale s join mis_customer c on c.id = s.customer_id
                where (s.total - s.paid_amount - s.returned_amount) > 0""" + (customerId != null ? " and s.customer_id = " + customerId : "")
                + " order by s.sale_date, s.id");
        List<OpenInvoice> out = new ArrayList<>();
        for (var r : rows) {
            LocalDate day = (LocalDate) r.get("dt");
            out.add(new OpenInvoice(((Number) r.get("cid")).longValue(), (String) r.get("customer"), (String) r.get("invoice"), day,
                    day.plusDays(((Number) r.get("days")).longValue()), bd(r.get("outstanding"))));
        }
        return out;
    }

    private ReportResult receivables(Params p) {
        LocalDate today = LocalDate.now();
        var rows = customerPositions(p.like());
        Map<Long, List<OpenInvoice>> byCustomer = new LinkedHashMap<>();
        for (OpenInvoice oi : openInvoices(null)) byCustomer.computeIfAbsent(oi.customerId(), k -> new ArrayList<>()).add(oi);
        for (var r : rows) {
            BigDecimal current = BigDecimal.ZERO, d30 = BigDecimal.ZERO, d60 = BigDecimal.ZERO, d90 = BigDecimal.ZERO, d90p = BigDecimal.ZERO;
            for (OpenInvoice oi : byCustomer.getOrDefault(((Number) r.get("id")).longValue(), List.of())) {
                long late = ChronoUnit.DAYS.between(oi.due(), today);
                if (late <= 0) current = current.add(oi.outstanding());
                else if (late <= 30) d30 = d30.add(oi.outstanding());
                else if (late <= 60) d60 = d60.add(oi.outstanding());
                else if (late <= 90) d90 = d90.add(oi.outstanding());
                else d90p = d90p.add(oi.outstanding());
            }
            BigDecimal overdue = d30.add(d60).add(d90).add(d90p);
            r.put("not_due", current);
            r.put("late_30", d30);
            r.put("late_60", d60);
            r.put("late_90", d90);
            r.put("late_90p", d90p);
            r.put("overdue", overdue);
        }
        rows.removeIf(r -> bd(r.get("balance")).signum() == 0);
        return new ReportResult("receivables", "Receivables (customer-wise)", "As of today. Overdue is counted from each invoice due date (invoice date + customer credit days)",
                List.of(text("code", "Code"), text("customer", "Customer"), money("balance", "Total receivable"), money("not_due", "Not yet due"),
                        money("late_30", "1-30 late"), money("late_60", "31-60 late"), money("late_90", "61-90 late"), money("late_90p", "90+ late"),
                        money("overdue", "Overdue")),
                rows, totals(rows, "balance", "not_due", "late_30", "late_60", "late_90", "late_90p", "overdue"));
    }

    private ReportResult overdue(Params p) {
        LocalDate today = LocalDate.now();
        List<Map<String, Object>> rows = new ArrayList<>();
        for (OpenInvoice oi : openInvoices(p.id())) {
            long late = ChronoUnit.DAYS.between(oi.due(), today);
            if (late <= 0) continue;
            rows.add(row().put("customer", oi.customer()).put("invoice", oi.invoice()).put("dt", oi.date()).put("due", oi.due())
                    .put("days_late", late).put("outstanding", oi.outstanding()).build());
        }
        rows.sort((a, b) -> Long.compare(((Number) b.get("days_late")).longValue(), ((Number) a.get("days_late")).longValue()));
        return new ReportResult("overdue", "Outstanding / overdue invoices", "As of today",
                List.of(text("customer", "Customer"), text("invoice", "Invoice"), date("dt", "Invoice date"), date("due", "Due date"),
                        integer("days_late", "Days overdue"), money("outstanding", "Outstanding")),
                rows, totals(rows, "outstanding"));
    }

    private ReportResult customerPayments(Params p) {
        var rows = q("""
                select * from (
                  select r.receipt_date as dt, r.receipt_no as ref, c.name as customer, r.method as method, r.reference as reference,
                         a.name as account, r.amount as amount, 'Receipt' as kind, r.customer_id as cid
                  from mis_receipt r join mis_customer c on c.id = r.customer_id join mis_account a on a.id = r.account_id
                  union all
                  select s.sale_date, s.invoice_no, c.name, s.payment_method, null, a.name, s.paid_at_sale, 'Paid at sale', s.customer_id
                  from mis_sale s join mis_customer c on c.id = s.customer_id left join mis_account a on a.id = s.account_id
                  where s.paid_at_sale > 0
                ) t where t.dt between ? and ?""" + (p.id() != null ? " and t.cid = " + p.id() : "") + " order by t.dt desc, t.ref desc",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("customer-payment-history", "Customer payment history", period(p),
                List.of(date("dt", "Date"), text("ref", "Reference"), text("customer", "Customer"), text("kind", "Kind"), text("method", "Method"),
                        text("reference", "Cheque / ref"), text("account", "Account"), money("amount", "Amount")),
                rows, totals(rows, "amount"));
    }

    // ---------------------------------------------------------------- suppliers

    private ReportResult payables(Params p) {
        var rows = q("""
                select s.code as code, s.name as supplier, s.country as country, s.opening_balance as opening,
                       coalesce((select sum(h.payable_amount) from mis_shipment h where h.supplier_id = s.id), 0) as purchases,
                       coalesce((select sum(x.amount) from mis_supplier_payment x where x.supplier_id = s.id), 0) as payments,
                       coalesce((select sum(a.amount) from mis_party_adjustment a where a.party_type = 'SUPPLIER' and a.party_id = s.id), 0) as adjustments
                from mis_supplier s order by s.name""");
        for (var r : rows) {
            r.put("balance", bd(r.get("opening")).add(bd(r.get("purchases"))).subtract(bd(r.get("payments"))).add(bd(r.get("adjustments"))));
        }
        return new ReportResult("payables", "Supplier payables", "Positive balance = amount we owe",
                List.of(text("code", "Code"), text("supplier", "Supplier"), text("country", "Country"), money("opening", "Opening"),
                        money("purchases", "Payable on receipts"), money("payments", "Payments"), money("adjustments", "Adjustments"),
                        money("balance", "Balance")),
                rows, totals(rows, "opening", "purchases", "payments", "adjustments", "balance"));
    }

    private ReportResult supplierTransactions(Params p) {
        var rows = q("""
                select * from (
                  select h.arrival_date as dt, h.shipment_no as ref, s.name as supplier, 'Stock received' as kind, h.total_cost as amount,
                         h.payable_amount as payable, s.id as sid
                  from mis_shipment h join mis_supplier s on s.id = h.supplier_id
                  union all
                  select x.payment_date, x.payment_no, s.name, 'Payment', x.amount, 0, s.id
                  from mis_supplier_payment x join mis_supplier s on s.id = x.supplier_id
                ) t where t.dt between ? and ?""" + (p.id() != null ? " and t.sid = " + p.id() : "") + " order by t.dt desc, t.ref desc",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("supplier-transactions", "Supplier transactions", period(p),
                List.of(date("dt", "Date"), text("ref", "Reference"), text("supplier", "Supplier"), text("kind", "Kind"),
                        money("amount", "Amount"), money("payable", "Added to payable")),
                rows, totals(rows, "payable"));
    }

    private ReportResult supplierPayments(Params p) {
        var rows = q("""
                select x.payment_date as dt, x.payment_no as ref, s.name as supplier, x.method as method, x.reference as reference,
                       a.name as account, x.amount as amount
                from mis_supplier_payment x join mis_supplier s on s.id = x.supplier_id join mis_account a on a.id = x.account_id
                where x.payment_date between ? and ?""" + (p.id() != null ? " and s.id = " + p.id() : "") + " order by x.payment_date desc, x.id desc",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        return new ReportResult("supplier-payment-history", "Supplier payment history", period(p),
                List.of(date("dt", "Date"), text("ref", "Reference"), text("supplier", "Supplier"), text("method", "Method"),
                        text("reference", "Cheque / ref"), text("account", "Account"), money("amount", "Amount")),
                rows, totals(rows, "amount"));
    }

    // ---------------------------------------------------------------- financial

    /** Net credit-minus-debit (income-like) or debit-minus-credit by head type within a date range. */
    private Map<String, BigDecimal> headNet(LocalDate from, LocalDate to) {
        var rows = q("""
                select l.head_code as code, sum(l.debit) as dr, sum(l.credit) as cr
                from mis_journal_line l join mis_journal j on j.id = l.journal_id
                where j.journal_date between ? and ? group by l.head_code""", sql(from), sql(to));
        Map<String, BigDecimal> out = new LinkedHashMap<>();
        for (var r : rows) out.put((String) r.get("code"), bd(r.get("dr")).subtract(bd(r.get("cr"))));
        return out;
    }

    private ReportResult profitLoss(Params p) {
        LocalDate from = p.fromOrDefault(), to = p.toOrDefault();
        Map<String, BigDecimal> net = headNet(from, to); // debit minus credit
        BigDecimal sales = net.getOrDefault(Heads.SALES, BigDecimal.ZERO).negate();
        BigDecimal returns = net.getOrDefault(Heads.SALES_RETURNS, BigDecimal.ZERO);
        BigDecimal netSales = sales.subtract(returns);
        BigDecimal cogs = net.getOrDefault(Heads.COGS, BigDecimal.ZERO);
        BigDecimal loss = net.getOrDefault(Heads.STOCK_LOSS, BigDecimal.ZERO);
        BigDecimal gross = netSales.subtract(cogs).subtract(loss);
        var heads = q("select code, name from mis_head where type = 'EXPENSE' and code <> ? order by code", Heads.OTHER_EXPENSE);

        List<Map<String, Object>> rows = new ArrayList<>();
        rows.add(pl("Sales", sales, "line"));
        rows.add(pl("Less: sales returns", returns.negate(), "line"));
        rows.add(pl("Net sales", netSales, "sub"));
        rows.add(pl("Cost of goods sold", cogs.negate(), "line"));
        if (loss.signum() != 0) rows.add(pl("Stock write-offs / adjustments", loss.negate(), "line"));
        rows.add(pl("Gross profit", gross, "sub"));
        BigDecimal opex = BigDecimal.ZERO;
        rows.add(pl("Operating expenses", null, "head"));
        for (var h : heads) {
            BigDecimal v = net.getOrDefault((String) h.get("code"), BigDecimal.ZERO);
            if (v.signum() == 0) continue;
            opex = opex.add(v);
            rows.add(pl("   " + h.get("name"), v.negate(), "line"));
        }
        rows.add(pl("Total operating expenses", opex.negate(), "sub"));
        BigDecimal otherInc = net.getOrDefault(Heads.OTHER_INCOME, BigDecimal.ZERO).negate();
        BigDecimal otherExp = net.getOrDefault(Heads.OTHER_EXPENSE, BigDecimal.ZERO);
        rows.add(pl("Other income", otherInc, "line"));
        rows.add(pl("Other expenses", otherExp.negate(), "line"));
        BigDecimal netProfit = gross.subtract(opex).add(otherInc).subtract(otherExp);
        rows.add(pl("Net profit", netProfit, "total"));
        BigDecimal nonOp = q("""
                select coalesce(sum(l.debit - l.credit), 0) as v from mis_journal_line l join mis_journal j on j.id = l.journal_id
                where l.head_code = ? and j.journal_date between ? and ?""", Heads.NON_OPERATING, sql(from), sql(to)).stream()
                .map(r -> bd(r.get("v"))).findFirst().orElse(BigDecimal.ZERO);
        rows.add(pl("Memo: non-operating / shipment payments (excluded from profit, paid from cash/bank)", nonOp, "note"));
        Map<String, Object> t = new LinkedHashMap<>();
        t.put("gross_profit", gross);
        t.put("net_profit", netProfit);
        return new ReportResult("profit-loss", "Profit & Loss", period(p),
                List.of(text("line", "Particulars"), money("amount", "Amount")), rows, t);
    }

    private static Map<String, Object> pl(String line, BigDecimal amount, String style) {
        return row().put("line", line).put("amount", amount).put("_style", style).build();
    }

    private ReportResult netProfitTrend(Params p) {
        var raw = q("""
                select year(j.journal_date) as y, month(j.journal_date) as m,
                       sum(case when l.head_code in ('4000','4100') then l.credit - l.debit else 0 end) as income,
                       sum(case when l.head_code = '4900' then l.credit - l.debit else 0 end) as other_income,
                       sum(case when h.type = 'COST_OF_SALES' then l.debit - l.credit else 0 end) as cost,
                       sum(case when h.type = 'EXPENSE' then l.debit - l.credit else 0 end) as expenses
                from mis_journal_line l join mis_journal j on j.id = l.journal_id join mis_head h on h.code = l.head_code
                where j.journal_date between ? and ? group by year(j.journal_date), month(j.journal_date) order by 1, 2""",
                sql(p.fromOrDefault()), sql(p.toOrDefault()));
        for (var r : raw) {
            r.put("month", String.format("%04d-%02d", ((Number) r.get("y")).intValue(), ((Number) r.get("m")).intValue()));
            BigDecimal inc = bd(r.get("income"));
            r.put("gross_profit", inc.subtract(bd(r.get("cost"))));
            r.put("net_profit", inc.subtract(bd(r.get("cost"))).subtract(bd(r.get("expenses"))).add(bd(r.get("other_income"))));
        }
        return new ReportResult("net-profit", "Net profit by month", period(p) + " - operating expenses only; non-operating payments excluded",
                List.of(text("month", "Month"), money("income", "Net sales"), money("cost", "Cost of goods"),
                        money("gross_profit", "Gross profit"), money("expenses", "Expenses"), money("other_income", "Other income"),
                        money("net_profit", "Net profit")),
                raw, totals(raw, "income", "cost", "gross_profit", "expenses", "other_income", "net_profit"));
    }

    private ReportResult expenseReport(Params p) {
        String nature = p.type() != null && (p.type().equals("OPERATING") || p.type().equals("NON_OPERATING")) ? p.type() : null;
        String like = p.like();
        var rows = q("""
                select e.expense_date as dt, e.expense_no as ref, e.nature as nature, c.name as category, e.description as description,
                       a.name as account, h.shipment_no as shipment, e.amount as amount
                from mis_expense e join mis_expense_category c on c.id = e.category_id join mis_account a on a.id = e.account_id
                     left join mis_shipment h on h.id = e.shipment_id
                where e.expense_date between ? and ? """ + (nature != null ? " and e.nature = '" + nature + "' " : "")
                + (like != null ? " and (lower(c.name) like ? or lower(e.description) like ?) " : "") + " order by e.expense_date desc, e.id desc",
                like != null ? new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault()), like, like}
                        : new Object[]{sql(p.fromOrDefault()), sql(p.toOrDefault())});
        BigDecimal op = BigDecimal.ZERO, nonOp = BigDecimal.ZERO;
        for (var r : rows) {
            if ("OPERATING".equals(r.get("nature"))) op = op.add(bd(r.get("amount"))); else nonOp = nonOp.add(bd(r.get("amount")));
        }
        Map<String, Object> t = new LinkedHashMap<>();
        t.put("operating", op);
        t.put("non_operating", nonOp);
        t.put("amount", op.add(nonOp));
        return new ReportResult("expense-report", "Expense report", period(p) + " - only OPERATING expenses reduce profit",
                List.of(date("dt", "Date"), text("ref", "Ref"), text("nature", "Nature"), text("category", "Category"), text("description", "Description"),
                        text("account", "Paid from"), text("shipment", "Shipment"), money("amount", "Amount")),
                rows, t);
    }

    private ReportResult cashBook(Params p, String type, String code, String title) {
        var accounts = q("select id, name, head_code from mis_account where type = ? order by id", type);
        if (accounts.isEmpty()) return new ReportResult(code, title, "No " + type.toLowerCase() + " accounts yet",
                List.of(text("note", "Note")), new ArrayList<>(), new LinkedHashMap<>());
        Map<String, Object> acc = p.id() == null ? accounts.get(0)
                : accounts.stream().filter(a -> ((Number) a.get("id")).longValue() == p.id()).findFirst().orElse(accounts.get(0));
        String head = (String) acc.get("head_code");
        LocalDate from = p.fromOrDefault(), to = p.toOrDefault();
        BigDecimal opening = q("""
                select coalesce(sum(l.debit - l.credit), 0) as v from mis_journal_line l join mis_journal j on j.id = l.journal_id
                where l.head_code = ? and j.journal_date < ?""", head, sql(from)).get(0).get("v") instanceof BigDecimal b ? b : BigDecimal.ZERO;
        var lines = q("""
                select j.journal_date as dt, j.source_type as src, j.source_no as ref, j.narration as narration, l.debit as receipt, l.credit as payment
                from mis_journal_line l join mis_journal j on j.id = l.journal_id
                where l.head_code = ? and j.journal_date between ? and ? order by j.journal_date, j.id, l.id""", head, sql(from), sql(to));
        List<Map<String, Object>> rows = new ArrayList<>();
        rows.add(row().put("dt", from).put("src", "").put("ref", "").put("narration", "Opening balance").put("balance", opening).build());
        BigDecimal run = opening, in = BigDecimal.ZERO, out = BigDecimal.ZERO;
        for (var l : lines) {
            run = run.add(bd(l.get("receipt"))).subtract(bd(l.get("payment")));
            in = in.add(bd(l.get("receipt")));
            out = out.add(bd(l.get("payment")));
            l.put("balance", run);
            rows.add(l);
        }
        Map<String, Object> t = new LinkedHashMap<>();
        t.put("receipt", in);
        t.put("payment", out);
        t.put("balance", run);
        ReportResult r = new ReportResult(code, title + " - " + acc.get("name"), period(p),
                List.of(date("dt", "Date"), text("src", "Type"), text("ref", "Reference"), text("narration", "Narration"),
                        money("receipt", "Receipts"), money("payment", "Payments"), money("balance", "Balance")),
                rows, t);
        return r;
    }

    private ReportResult cashFlow(Params p) {
        LocalDate from = p.fromOrDefault(), to = p.toOrDefault();
        var rows = q("""
                select j.source_type as src, sum(l.debit) as inflow, sum(l.credit) as outflow
                from mis_journal_line l join mis_journal j on j.id = l.journal_id join mis_account a on a.head_code = l.head_code
                where j.journal_date between ? and ? and j.source_type <> 'OPENING_ACCOUNT'
                group by j.source_type order by j.source_type""", sql(from), sql(to));
        var names = Map.ofEntries(Map.entry("SALE", "Sales received"), Map.entry("RECEIPT", "Customer receipts"),
                Map.entry("SHIPMENT", "Stock receiving"), Map.entry("SUPPLIER_PAYMENT", "Supplier payments"),
                Map.entry("EXPENSE", "Expenses & shipment payments"), Map.entry("RETURN", "Customer refunds"),
                Map.entry("VOUCHER", "Other cash/bank vouchers & transfers"), Map.entry("PARTY_ADJ", "Adjustments"));
        for (var r : rows) {
            r.put("activity", names.getOrDefault((String) r.get("src"), (String) r.get("src")));
            r.put("net", bd(r.get("inflow")).subtract(bd(r.get("outflow"))));
        }
        BigDecimal openBal = q("""
                select coalesce(sum(l.debit - l.credit), 0) as v from mis_journal_line l join mis_journal j on j.id = l.journal_id
                join mis_account a on a.head_code = l.head_code where j.journal_date < ?""", sql(from)).get(0).get("v") instanceof BigDecimal b ? b : BigDecimal.ZERO;
        Map<String, Object> t = totals(rows, "inflow", "outflow", "net");
        t.put("opening", openBal);
        t.put("closing", openBal.add(bd(t.get("net"))));
        return new ReportResult("cash-flow", "Cash flow (cash + bank)", period(p) + " - opening " + openBal + ", closing " + t.get("closing"),
                List.of(text("activity", "Activity"), money("inflow", "Money in"), money("outflow", "Money out"), money("net", "Net")), rows, t);
    }

    private ReportResult trialBalance(Params p) {
        LocalDate to = p.toOrDefault();
        var rows = q("""
                select h.code as code, h.name as name, h.type as type, coalesce(sum(l.debit), 0) as dr, coalesce(sum(l.credit), 0) as cr
                from mis_head h left join mis_journal_line l on l.head_code = h.code
                left join mis_journal j on j.id = l.journal_id
                where j.journal_date <= ? or j.id is null group by h.code, h.name, h.type order by h.code""", sql(to));
        List<Map<String, Object>> out = new ArrayList<>();
        for (var r : rows) {
            BigDecimal bal = bd(r.get("dr")).subtract(bd(r.get("cr")));
            if (bal.signum() == 0 && bd(r.get("dr")).signum() == 0) continue;
            r.put("debit", bal.signum() > 0 ? bal : BigDecimal.ZERO);
            r.put("credit", bal.signum() < 0 ? bal.negate() : BigDecimal.ZERO);
            out.add(r);
        }
        return new ReportResult("trial-balance", "Trial balance", "As of " + to,
                List.of(text("code", "Code"), text("name", "Account"), text("type", "Type"), money("debit", "Debit"), money("credit", "Credit")),
                out, totals(out, "debit", "credit"));
    }

    private ReportResult balanceSheet(Params p) {
        LocalDate to = p.toOrDefault();
        var rows = q("""
                select h.code as code, h.name as name, h.type as type, coalesce(sum(l.debit - l.credit), 0) as bal
                from mis_head h left join mis_journal_line l on l.head_code = h.code
                left join mis_journal j on j.id = l.journal_id
                where j.journal_date <= ? or j.id is null group by h.code, h.name, h.type order by h.code""", sql(to));
        List<Map<String, Object>> out = new ArrayList<>();
        BigDecimal assets = BigDecimal.ZERO, liabilities = BigDecimal.ZERO, equity = BigDecimal.ZERO, profit = BigDecimal.ZERO;
        out.add(pl("ASSETS", null, "head"));
        for (var r : rows) if ("ASSET".equals(r.get("type")) && bd(r.get("bal")).signum() != 0) {
            assets = assets.add(bd(r.get("bal")));
            out.add(pl("   " + r.get("name"), bd(r.get("bal")), "line"));
        }
        out.add(pl("Total assets", assets, "sub"));
        out.add(pl("LIABILITIES", null, "head"));
        for (var r : rows) if ("LIABILITY".equals(r.get("type")) && bd(r.get("bal")).signum() != 0) {
            liabilities = liabilities.add(bd(r.get("bal")).negate());
            out.add(pl("   " + r.get("name"), bd(r.get("bal")).negate(), "line"));
        }
        out.add(pl("Total liabilities", liabilities, "sub"));
        out.add(pl("EQUITY", null, "head"));
        for (var r : rows) if ("EQUITY".equals(r.get("type")) && bd(r.get("bal")).signum() != 0) {
            equity = equity.add(bd(r.get("bal")).negate());
            out.add(pl("   " + r.get("name"), bd(r.get("bal")).negate(), "line"));
        }
        for (var r : rows) {
            String type = (String) r.get("type");
            if ("INCOME".equals(type)) profit = profit.add(bd(r.get("bal")).negate());
            else if ("COST_OF_SALES".equals(type) || "EXPENSE".equals(type)) profit = profit.subtract(bd(r.get("bal")));
        }
        out.add(pl("   Profit for the period to date", profit, "line"));
        equity = equity.add(profit);
        out.add(pl("Total equity", equity, "sub"));
        out.add(pl("Total liabilities + equity", liabilities.add(equity), "total"));
        Map<String, Object> t = new LinkedHashMap<>();
        t.put("assets", assets);
        t.put("liabilities_equity", liabilities.add(equity));
        return new ReportResult("balance-sheet", "Balance sheet", "As of " + to, List.of(text("line", "Particulars"), money("amount", "Amount")), out, t);
    }
}
