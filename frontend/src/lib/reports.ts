export type ReportGroup = 'Sales' | 'Inventory' | 'Customers' | 'Suppliers' | 'Financial'

export interface ReportDef {
  code: string
  title: string
  group: ReportGroup
  blurb: string
  /** range = from/to dates, asof = single "as of" date, none = always current */
  filter: 'range' | 'asof' | 'none'
  pick?: 'customer' | 'supplier' | 'cash' | 'bank' | 'product'
  pickRequired?: boolean
  search?: boolean
  typeOptions?: { value: string; label: string }[]
  /** needs the finance permission */
  fin?: boolean
}

const MOVE_TYPES = [
  { value: '', label: 'All movements' }, { value: 'RECEIPT', label: 'Received' }, { value: 'SALE', label: 'Sold' },
  { value: 'SALE_RETURN', label: 'Returned' }, { value: 'DAMAGED', label: 'Damaged' }, { value: 'MISSING', label: 'Missing' },
  { value: 'CORRECTION', label: 'Corrections' }, { value: 'OTHER_ADJUSTMENT', label: 'Other adjustments' },
]

export const REPORTS: ReportDef[] = [
  // Sales
  { code: 'daily-sales', title: 'Daily sales', group: 'Sales', blurb: 'Invoices, net sales, cost and profit for each day.', filter: 'range' },
  { code: 'monthly-sales', title: 'Monthly sales', group: 'Sales', blurb: 'Month-by-month sales and profit.', filter: 'range' },
  { code: 'customer-wise-sales', title: 'Customer-wise sales', group: 'Sales', blurb: 'Who buys what: sales, returns and profit per customer.', filter: 'range' },
  { code: 'product-wise-sales', title: 'Product-wise sales & profit', group: 'Sales', blurb: 'Quantity, net sales, batch cost and margin per product.', filter: 'range' },
  { code: 'wholesale-sales', title: 'Wholesale sales', group: 'Sales', blurb: 'Every wholesale invoice with payment status and profit.', filter: 'range', search: true },
  { code: 'retail-sales', title: 'Retail sales', group: 'Sales', blurb: 'Every retail invoice with payment status and profit.', filter: 'range', search: true },
  { code: 'sales-by-range', title: 'Sales by date range', group: 'Sales', blurb: 'Line-by-line sales detail for any period.', filter: 'range', search: true },
  { code: 'sales-by-invoice', title: 'Sales by invoice (invoice-wise profit)', group: 'Sales', blurb: 'One row per invoice with cost, profit and margin.', filter: 'range', search: true },
  { code: 'container-wise-sales', title: 'Container-wise sales & returns', group: 'Sales', blurb: 'For every container: cost, sales, returns, net sales, profit, sell-through and stock left.', filter: 'range' },
  { code: 'container-product-sales', title: 'Container-wise sales detail (by product)', group: 'Sales', blurb: 'Each product batch in each container: received, sold, returned, on hand and profit.', filter: 'range', search: true },
  { code: 'sales-returns', title: 'Sales return report', group: 'Sales', blurb: 'Returned items, value, refunds and cost reversed.', filter: 'range' },
  // Inventory
  { code: 'current-stock', title: 'Current stock', group: 'Inventory', blurb: 'On-hand quantity per product.', filter: 'none', search: true },
  { code: 'stock-valuation', title: 'Stock valuation', group: 'Inventory', blurb: 'Stock value at each batch’s own cost.', filter: 'none', search: true, fin: true },
  { code: 'product-wise-stock', title: 'Product-wise stock position', group: 'Inventory', blurb: 'Received, sold, returned, damaged, adjusted and available.', filter: 'asof' },
  { code: 'batch-wise-stock', title: 'Batch-wise stock', group: 'Inventory', blurb: 'Which shipment each unit came from and what remains.', filter: 'none', search: true, pick: 'product' },
  { code: 'stock-received', title: 'Stock received', group: 'Inventory', blurb: 'Shipments and batches received in a period.', filter: 'range', search: true },
  { code: 'stock-sold', title: 'Stock sold', group: 'Inventory', blurb: 'Stock issued through sales.', filter: 'range', search: true, pick: 'product' },
  { code: 'stock-adjustments', title: 'Stock adjustment report', group: 'Inventory', blurb: 'Damaged, missing and correction entries with reasons.', filter: 'range', search: true },
  { code: 'damaged-stock', title: 'Damaged stock', group: 'Inventory', blurb: 'Everything written off as damaged.', filter: 'range' },
  { code: 'low-stock', title: 'Low-stock report', group: 'Inventory', blurb: 'Active products at or below their minimum level.', filter: 'none' },
  { code: 'stock-movement', title: 'Stock movement / history', group: 'Inventory', blurb: 'Full audit trail of every stock change.', filter: 'range', search: true, pick: 'product', typeOptions: MOVE_TYPES },
  // Customers
  { code: 'customer-ledger', title: 'Customer ledger', group: 'Customers', blurb: 'Opening, sales, payments, returns, adjustments and closing balance.', filter: 'range', pick: 'customer', pickRequired: true },
  { code: 'customer-balances', title: 'Customer balances', group: 'Customers', blurb: 'What every customer owes today.', filter: 'none', search: true },
  { code: 'receivables', title: 'Receivables & ageing', group: 'Customers', blurb: 'Customer-wise receivables split into not-due and overdue buckets.', filter: 'none', search: true },
  { code: 'overdue', title: 'Outstanding / overdue invoices', group: 'Customers', blurb: 'Unpaid invoices past their due date, oldest first.', filter: 'none', pick: 'customer' },
  { code: 'customer-payment-history', title: 'Payment history', group: 'Customers', blurb: 'Receipts and payments taken at sale.', filter: 'range', pick: 'customer' },
  // Suppliers
  { code: 'supplier-ledger', title: 'Supplier ledger', group: 'Suppliers', blurb: 'Goods received on credit, payments and balance.', filter: 'range', pick: 'supplier', pickRequired: true, fin: true },
  { code: 'payables', title: 'Supplier payables', group: 'Suppliers', blurb: 'What you owe each supplier.', filter: 'none', fin: true },
  { code: 'supplier-transactions', title: 'Supplier transactions', group: 'Suppliers', blurb: 'Stock received and payments by supplier.', filter: 'range', pick: 'supplier', fin: true },
  { code: 'supplier-payment-history', title: 'Supplier payment history', group: 'Suppliers', blurb: 'Every payment made to suppliers.', filter: 'range', pick: 'supplier', fin: true },
  // Financial
  { code: 'profit-loss', title: 'Profit & Loss', group: 'Financial', blurb: 'Net sales, cost of goods, operating expenses and net profit. Non-operating payments are excluded.', filter: 'range', fin: true },
  { code: 'gross-profit', title: 'Gross profit by product', group: 'Financial', blurb: 'Selling price minus batch cost, per product.', filter: 'range', fin: true },
  { code: 'net-profit', title: 'Net profit by month', group: 'Financial', blurb: 'Gross profit less operating expenses, month by month.', filter: 'range', fin: true },
  { code: 'expense-report', title: 'Expense report', group: 'Financial', blurb: 'Operating expenses and non-operating payments, clearly tagged.', filter: 'range', search: true, fin: true,
    typeOptions: [{ value: '', label: 'All payments' }, { value: 'OPERATING', label: 'Operating expenses' }, { value: 'NON_OPERATING', label: 'Non-operating payments' }] },
  { code: 'cash-book', title: 'Cash book', group: 'Financial', blurb: 'Every rupee in and out of a cash account.', filter: 'range', pick: 'cash', fin: true },
  { code: 'bank-book', title: 'Bank book', group: 'Financial', blurb: 'Every rupee in and out of a bank account.', filter: 'range', pick: 'bank', fin: true },
  { code: 'cash-flow', title: 'Cash flow', group: 'Financial', blurb: 'Cash and bank movement by activity.', filter: 'range', fin: true },
  { code: 'trial-balance', title: 'Trial balance', group: 'Financial', blurb: 'All account heads with debit and credit balances.', filter: 'asof', fin: true },
  { code: 'balance-sheet', title: 'Balance sheet', group: 'Financial', blurb: 'Assets, liabilities and equity at a date.', filter: 'asof', fin: true },
]

export const REPORT_GROUPS: ReportGroup[] = ['Sales', 'Inventory', 'Customers', 'Suppliers', 'Financial']

export function reportDef(code: string): ReportDef | undefined {
  return REPORTS.find((r) => r.code === code)
}
