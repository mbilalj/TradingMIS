package com.portside.trading.web.dto;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Generic tabular report payload; the UI renders any report from this one shape (filters, print, export). */
public record ReportResult(String code, String title, String subtitle, List<Col> columns,
                           List<Map<String, Object>> rows, Map<String, Object> totals) {

    /** type: text | money | qty | date | pct | int */
    public record Col(String key, String label, String type) {}

    public static Col text(String key, String label) { return new Col(key, label, "text"); }
    public static Col money(String key, String label) { return new Col(key, label, "money"); }
    public static Col qty(String key, String label) { return new Col(key, label, "qty"); }
    public static Col date(String key, String label) { return new Col(key, label, "date"); }
    public static Col pct(String key, String label) { return new Col(key, label, "pct"); }
    public static Col integer(String key, String label) { return new Col(key, label, "int"); }

    public static Row row() { return new Row(); }

    /** Tiny fluent builder for row maps. */
    public static final class Row {
        private final Map<String, Object> m = new LinkedHashMap<>();
        public Row put(String k, Object v) { m.put(k, v); return this; }
        public Map<String, Object> build() { return m; }
    }
}
