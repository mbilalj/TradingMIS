import { useQuery } from '@tanstack/react-query'
import { Api } from './resources'

const LONG = 60_000

export const useUnits = () => useQuery({ queryKey: ['units'], queryFn: Api.units, staleTime: LONG })
export const useWarehouses = () => useQuery({ queryKey: ['warehouses'], queryFn: Api.warehouses, staleTime: LONG })
export const useProducts = () => useQuery({ queryKey: ['products'], queryFn: Api.products })
export const useCustomers = () => useQuery({ queryKey: ['customers'], queryFn: Api.customers })
export const useSuppliers = () => useQuery({ queryKey: ['suppliers'], queryFn: Api.suppliers })
export const useAccounts = () => useQuery({ queryKey: ['accounts'], queryFn: Api.accounts })
export const useCategories = () => useQuery({ queryKey: ['categories'], queryFn: Api.categories, staleTime: LONG })
export const useSettings = () => useQuery({ queryKey: ['settings'], queryFn: Api.settings, staleTime: LONG })
