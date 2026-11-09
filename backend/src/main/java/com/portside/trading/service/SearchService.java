package com.portside.trading.service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** One search box over products, batches, shipments, customers, suppliers and invoices. */
@Service
@Transactional(readOnly = true)
public class SearchService {

    private final JdbcTemplate jdbc;

    public SearchService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public List<Map<String, Object>> search(String term) {
        List<Map<String, Object>> out = new ArrayList<>();
        if (term == null || term.trim().length() < 2) return out;
        String like = "%" + term.trim().toLowerCase() + "%";
        add(out, "Product", "/products", "select id, sku as label, name as sub from mis_product where lower(sku) like ? or lower(name) like ? limit 6", like, like);
        add(out, "Batch", "/shipments", "select h.id as id, b.batch_no as label, concat(pr.name, ' - shipment ', h.shipment_no) as sub from mis_batch b "
                + "join mis_shipment h on h.id = b.shipment_id join mis_product pr on pr.id = b.product_id where lower(b.batch_no) like ? limit 6", like);
        add(out, "Shipment", "/shipments", "select h.id as id, h.shipment_no as label, concat('Container ', coalesce(h.container_no, '-'), ' - arrived ', h.arrival_date, ' - ', s.name) as sub from mis_shipment h "
                + "join mis_supplier s on s.id = h.supplier_id where lower(h.shipment_no) like ? or lower(h.container_no) like ? limit 6", like, like);
        add(out, "Customer", "/customers", "select id, name as label, coalesce(phone, code) as sub from mis_customer where walk_in = false and (lower(name) like ? or lower(code) like ? or lower(phone) like ?) limit 6", like, like, like);
        add(out, "Supplier", "/suppliers", "select id, name as label, coalesce(country, code) as sub from mis_supplier where lower(name) like ? or lower(code) like ? limit 6", like, like);
        add(out, "Invoice", "/sales", "select s.id as id, s.invoice_no as label, concat(c.name, ' - ', s.sale_date) as sub from mis_sale s "
                + "join mis_customer c on c.id = s.customer_id where lower(s.invoice_no) like ? or lower(c.name) like ? order by s.id desc limit 6", like, like);
        return out;
    }

    private void add(List<Map<String, Object>> out, String type, String route, String sql, Object... args) {
        for (Map<String, Object> r : jdbc.queryForList(sql, args)) {
            Map<String, Object> hit = new LinkedHashMap<>();
            Map<String, Object> low = new LinkedHashMap<>();
            r.forEach((k, v) -> low.put(k.toLowerCase(), v));
            hit.put("type", type);
            hit.put("id", low.get("id"));
            hit.put("label", String.valueOf(low.get("label")));
            hit.put("sub", low.get("sub") == null ? "" : String.valueOf(low.get("sub")));
            hit.put("route", route);
            out.add(hit);
        }
    }
}
