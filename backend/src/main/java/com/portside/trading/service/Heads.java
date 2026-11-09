package com.portside.trading.service;

/** Codes of the fixed accounting heads. Per-account and per-expense-category heads are created on demand. */
public final class Heads {
    private Heads() {}

    public static final String AR = "1200";
    public static final String INVENTORY = "1300";
    /** Payments tied to inventory/shipments (customs duty etc.) that reduce cash/bank but never reach the P&L. */
    public static final String NON_OPERATING = "1400";
    public static final String AP = "2100";
    public static final String SALES_TAX = "2200";
    /** Offset for stock received at its manually-entered cost when not owed to a supplier. */
    public static final String IMPORT_CLEARING = "3100";
    public static final String CAPITAL = "3200";
    public static final String DRAWINGS = "3300";
    public static final String OPENING = "3900";
    public static final String SALES = "4000";
    public static final String SALES_RETURNS = "4100";
    public static final String OTHER_INCOME = "4900";
    public static final String COGS = "5000";
    public static final String STOCK_LOSS = "5100";
    public static final String OTHER_EXPENSE = "6900";
}
