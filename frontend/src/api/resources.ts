import { api } from './client'
import type {
  AccountRow, Attachment, Batch, BatchAvailability, Customer, CustomerRow, Dashboard, Expense, ExpenseCategory,
  LoginResponse, ProductRow, Receipt, ReportResult, Sale, SaleReturn, SearchHit, Shipment, Supplier, SupplierPayment,
  SupplierRow, Unit, Voucher, Warehouse, Product,
} from './types'

const d = <T>(p: Promise<{ data: T }>) => p.then((r) => r.data)

export const AuthApi = {
  login: (username: string, password: string) => d(api.post<LoginResponse>('/auth/login', { username, password })),
  me: () => d(api.get<LoginResponse>('/auth/me')),
}

export const Api = {
  units: () => d(api.get<Unit[]>('/units')),
  createUnit: (name: string) => d(api.post<Unit>('/units', { name })),
  warehouses: () => d(api.get<Warehouse[]>('/warehouses')),

  products: () => d(api.get<ProductRow[]>('/products')),
  productBatches: (id: number) => d(api.get<BatchAvailability[]>(`/products/${id}/batches`)),
  saveProduct: (id: number | null, body: unknown) =>
    d(id == null ? api.post<Product>('/products', body) : api.put<Product>(`/products/${id}`, body)),

  customers: () => d(api.get<CustomerRow[]>('/customers')),
  saveCustomer: (id: number | null, body: Partial<Customer>) =>
    d(id == null ? api.post<Customer>('/customers', body) : api.put<Customer>(`/customers/${id}`, body)),

  suppliers: () => d(api.get<SupplierRow[]>('/suppliers')),
  saveSupplier: (id: number | null, body: Partial<Supplier>) =>
    d(id == null ? api.post<Supplier>('/suppliers', body) : api.put<Supplier>(`/suppliers/${id}`, body)),

  shipments: () => d(api.get<Shipment[]>('/shipments')),
  shipment: (id: number) =>
    d(api.get<{ shipment: Shipment; batches: { batch: Batch; onHand: number }[]; payments: Expense[] }>(`/shipments/${id}`)),
  receive: (body: unknown) => d(api.post<Shipment>('/shipments', body)),
  adjustStock: (body: unknown) => d(api.post('/stock-adjustments', body)),

  sales: (params: Record<string, string | undefined>) => d(api.get<Sale[]>('/sales', { params })),
  sale: (id: number) => d(api.get<Sale>(`/sales/${id}`)),
  createSale: (body: unknown) => d(api.post<Sale>('/sales', body)),
  returns: () => d(api.get<SaleReturn[]>('/sale-returns')),
  returnsFor: (saleId: number) => d(api.get<SaleReturn[]>(`/sales/${saleId}/returns`)),
  createReturn: (body: unknown) => d(api.post<SaleReturn>('/sale-returns', body)),

  receipts: () => d(api.get<Receipt[]>('/receipts')),
  createReceipt: (body: unknown) => d(api.post<Receipt>('/receipts', body)),
  supplierPayments: () => d(api.get<SupplierPayment[]>('/supplier-payments')),
  createSupplierPayment: (body: unknown) => d(api.post<SupplierPayment>('/supplier-payments', body)),
  createPartyAdjustment: (body: unknown) => d(api.post('/party-adjustments', body)),

  categories: () => d(api.get<ExpenseCategory[]>('/expense-categories')),
  createCategory: (body: unknown) => d(api.post<ExpenseCategory>('/expense-categories', body)),
  expenses: (params: Record<string, string | undefined>) => d(api.get<Expense[]>('/expenses', { params })),
  createExpense: (body: unknown) => d(api.post<Expense>('/expenses', body)),
  deleteExpense: (id: number) => api.delete(`/expenses/${id}`),

  accounts: () => d(api.get<AccountRow[]>('/accounts')),
  saveAccount: (id: number | null, body: unknown) => d(id == null ? api.post('/accounts', body) : api.put(`/accounts/${id}`, body)),
  vouchers: () => d(api.get<Voucher[]>('/vouchers')),
  createVoucher: (body: unknown) => d(api.post<Voucher>('/vouchers', body)),
  deleteVoucher: (id: number) => api.delete(`/vouchers/${id}`),

  dashboard: () => d(api.get<Dashboard>('/dashboard')),
  report: (code: string, params: Record<string, string | undefined>) => d(api.get<ReportResult>(`/reports/${code}`, { params })),
  search: (q: string) => d(api.get<SearchHit[]>('/search', { params: { q } })),
  settings: () => d(api.get<Record<string, string>>('/settings')),
  saveSettings: (body: Record<string, string>) => d(api.put<Record<string, string>>('/settings', body)),

  attachments: (ownerType: string, ownerId: number) => d(api.get<Attachment[]>('/attachments', { params: { ownerType, ownerId } })),
  upload: (ownerType: string, ownerId: number, file: File) => {
    const form = new FormData()
    form.append('file', file)
    return d(api.post<Attachment>('/attachments', form, { params: { ownerType, ownerId } }))
  },
  deleteAttachment: (id: number) => api.delete(`/attachments/${id}`),
}
