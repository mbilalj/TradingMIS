export type Role = 'OWNER' | 'ACCOUNTANT' | 'SALES_OFFICER' | 'STORE_KEEPER' | 'IMPORT_DESK'

export interface LoginResponse {
  token: string | null
  username: string
  fullName: string
  role: Role
}

export type SaleType = 'WHOLESALE' | 'RETAIL'
export type ExpenseNature = 'OPERATING' | 'NON_OPERATING'
export type AccountType = 'CASH' | 'BANK'
export type MovementType = 'RECEIPT' | 'SALE' | 'SALE_RETURN' | 'DAMAGED' | 'MISSING' | 'CORRECTION' | 'OTHER_ADJUSTMENT'

export interface Unit { id: number; name: string }
export interface Warehouse { id: number; code: string; name: string; address?: string }

export interface ProductUnit { id?: number; unit: Unit; factor: number }
export interface Product {
  id: number
  sku: string
  name: string
  category?: string
  brand?: string
  description?: string
  baseUnit: Unit
  sellingPrice: number
  wholesalePrice: number
  retailPrice: number
  minStock: number
  active: boolean
  units: ProductUnit[]
}
export interface ProductRow {
  product: Product
  onHand: number
  stockValue: number
  lastCost: number
  lowStock: boolean
}

export interface Customer {
  id: number
  code: string
  name: string
  phone?: string
  address?: string
  openingBalance: number
  type: SaleType
  creditLimit: number
  creditDays: number
  notes?: string
  active: boolean
  walkIn: boolean
}
export interface CustomerRow { customer: Customer; balance: number }

export interface Supplier {
  id: number
  code: string
  name: string
  country?: string
  contact?: string
  address?: string
  openingBalance: number
  notes?: string
  active: boolean
}
export interface SupplierRow { supplier: Supplier; balance: number }

export interface Shipment {
  id: number
  shipmentNo: string
  containerNo?: string
  arrivalDate: string
  supplier: Supplier
  warehouse: Warehouse
  notes?: string
  payableAmount: number
  totalCost: number
  createdBy?: string
  batches: Batch[]
}
export interface Batch {
  id: number
  shipment: { id: number; shipmentNo: string; containerNo?: string; arrivalDate: string }
  product: Product
  batchNo: string
  enteredUnit: Unit
  enteredQty: number
  enteredUnitCost: number
  receivedQty: number
  unitCost: number
}
export interface BatchAvailability {
  batchId: number
  batchNo: string
  shipmentNo: string
  containerNo?: string
  arrivalDate: string
  unitCost: number
  available: number
}

export interface SaleLine {
  id: number
  product: Product
  batch: Batch
  unit: Unit
  qty: number
  factor: number
  baseQty: number
  rate: number
  discount: number
  taxPct: number
  netAmount: number
  taxAmount: number
  lineTotal: number
  unitCost: number
  returnedBaseQty: number
}
export interface Sale {
  id: number
  invoiceNo: string
  saleDate: string
  type: SaleType
  customer: Customer
  grossAmount: number
  discountTotal: number
  taxTotal: number
  total: number
  paidAtSale: number
  paidAmount: number
  returnedAmount: number
  cogsTotal: number
  paymentMethod?: string
  account?: CashAccount
  remarks?: string
  createdBy?: string
  lines: SaleLine[]
  outstanding: number
  profit: number
}
export interface SaleReturn {
  id: number
  returnNo: string
  returnDate: string
  sale: Sale
  customer: Customer
  netAmount: number
  taxAmount: number
  total: number
  cogsTotal: number
  refundAmount: number
  notes?: string
  lines: { id: number; saleLine: SaleLine; product: Product; batch: Batch; qty: number; total: number }[]
}

export interface CashAccount {
  id: number
  name: string
  type: AccountType
  accountNumber?: string
  openingBalance: number
  headCode: string
  active: boolean
}
export interface AccountRow { account: CashAccount; balance: number }
export interface Voucher {
  id: number
  voucherNo: string
  voucherDate: string
  kind: 'RECEIPT' | 'PAYMENT' | 'TRANSFER'
  purpose?: string
  account: CashAccount
  toAccount?: CashAccount
  amount: number
  description?: string
}

export interface Receipt {
  id: number
  receiptNo: string
  receiptDate: string
  customer: Customer
  amount: number
  method?: string
  account: CashAccount
  reference?: string
  notes?: string
}
export interface SupplierPayment {
  id: number
  paymentNo: string
  paymentDate: string
  supplier: Supplier
  amount: number
  method?: string
  account: CashAccount
  reference?: string
  notes?: string
}

export interface ExpenseCategory { id: number; name: string; nature: ExpenseNature; active: boolean }
export interface Expense {
  id: number
  expenseNo: string
  expenseDate: string
  nature: ExpenseNature
  category: ExpenseCategory
  amount: number
  account: CashAccount
  method?: string
  shipment?: { id: number; shipmentNo: string }
  description?: string
}

export interface Attachment {
  id: number
  ownerType: string
  ownerId: number
  fileName: string
  size: number
  uploadedBy?: string
  uploadedAt?: string
}

export interface ReportCol { key: string; label: string; type: 'text' | 'money' | 'qty' | 'date' | 'pct' | 'int' }
export interface ReportResult {
  code: string
  title: string
  subtitle?: string
  columns: ReportCol[]
  rows: Record<string, unknown>[]
  totals: Record<string, unknown>
}

export interface SearchHit { type: string; id: number; label: string; sub: string; route: string }

export interface Dashboard {
  todaySales: number
  todayInvoices: number
  todayCollections: number
  totalReceivables: number
  totalPayables: number
  stockValue: number
  todayProfit: number
  monthlySales: number
  monthlyGrossProfit: number
  monthlyProfit: number
  monthlyExpenses: number
  cashBalance: number
  bankBalance: number
  lowStockCount: number
  lowStock: { id: number; sku: string; name: string; unit: string; on_hand: number; min_stock: number }[]
  recent: { day: string; type: string; ref: string; narration: string; amount: number }[]
  salesTrend: { day: string; sales: number }[]
}
