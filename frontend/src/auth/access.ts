import type { Role } from '../api/types'

// Mirrors backend AccessService -- for hiding menu items / buttons only; the server enforces the real rule.
const VIEW: Partial<Record<Role, string[]>> = {
  ACCOUNTANT: ['dash', 'products', 'receiving', 'stock', 'adjustments', 'sales', 'returns', 'customers', 'receipts',
    'suppliers', 'supplierpay', 'expenses', 'cash', 'reports', 'finreports'],
  SALES_OFFICER: ['dash', 'products', 'stock', 'sales', 'returns', 'customers', 'receipts', 'reports'],
  STORE_KEEPER: ['dash', 'products', 'receiving', 'stock', 'adjustments'],
  IMPORT_DESK: ['dash', 'products', 'receiving', 'stock', 'suppliers', 'reports'],
}

const EDIT: Record<string, Role[]> = {
  products: ['OWNER', 'ACCOUNTANT', 'STORE_KEEPER', 'IMPORT_DESK'],
  receiving: ['OWNER', 'ACCOUNTANT', 'STORE_KEEPER', 'IMPORT_DESK'],
  adjustments: ['OWNER', 'ACCOUNTANT', 'STORE_KEEPER'],
  sales: ['OWNER', 'ACCOUNTANT', 'SALES_OFFICER'],
  returns: ['OWNER', 'ACCOUNTANT', 'SALES_OFFICER'],
  customers: ['OWNER', 'ACCOUNTANT', 'SALES_OFFICER'],
  receipts: ['OWNER', 'ACCOUNTANT'],
  suppliers: ['OWNER', 'ACCOUNTANT', 'IMPORT_DESK'],
  supplierpay: ['OWNER', 'ACCOUNTANT'],
  expenses: ['OWNER', 'ACCOUNTANT'],
  cash: ['OWNER', 'ACCOUNTANT'],
}

export function canView(role: Role | undefined, module: string): boolean {
  if (!role) return false
  if (role === 'OWNER') return true
  return !!VIEW[role]?.includes(module)
}

export function canEdit(role: Role | undefined, module: string): boolean {
  if (!role) return false
  if (role === 'OWNER') return true
  return !!EDIT[module]?.includes(role)
}

export function isOwner(role: Role | undefined): boolean {
  return role === 'OWNER'
}
