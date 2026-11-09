import type { ReactNode } from 'react'
import { Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from './auth/AuthContext'
import Layout from './components/Layout'
import { Loading } from './components/ui'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import ProductsPage from './pages/ProductsPage'
import ReceivingPage from './pages/ReceivingPage'
import ReceivingFormPage from './pages/ReceivingFormPage'
import ShipmentDetailPage from './pages/ShipmentDetailPage'
import StockPage from './pages/StockPage'
import SalesPage from './pages/SalesPage'
import NewSalePage from './pages/NewSalePage'
import InvoicePage from './pages/InvoicePage'
import ReturnsPage from './pages/ReturnsPage'
import CustomersPage from './pages/CustomersPage'
import CustomerDetailPage from './pages/CustomerDetailPage'
import { ReceiptsPage, ReceivablesPage } from './pages/ReceiptsPage'
import SuppliersPage, { SupplierPaymentsPage } from './pages/SuppliersPage'
import SupplierDetailPage from './pages/SupplierDetailPage'
import ExpensesPage from './pages/ExpensesPage'
import CashPage from './pages/CashPage'
import { ReportPage, ReportsHub } from './pages/ReportsPage'
import SettingsPage from './pages/SettingsPage'

function RequireAuth({ children }: { children: ReactNode }) {
  const { user, loading } = useAuth()
  if (loading) return <Loading />
  if (!user) return <Navigate to="/login" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/" element={<RequireAuth><Layout /></RequireAuth>}>
        <Route index element={<DashboardPage />} />
        <Route path="products" element={<ProductsPage />} />
        <Route path="receiving" element={<ReceivingPage />} />
        <Route path="receiving/new" element={<ReceivingFormPage />} />
        <Route path="shipments/:id" element={<ShipmentDetailPage />} />
        <Route path="stock" element={<StockPage />} />
        <Route path="sales" element={<SalesPage />} />
        <Route path="sales/new" element={<NewSalePage />} />
        <Route path="sales/:id" element={<InvoicePage />} />
        <Route path="returns" element={<ReturnsPage />} />
        <Route path="customers" element={<CustomersPage />} />
        <Route path="customers/:id" element={<CustomerDetailPage />} />
        <Route path="receivables" element={<ReceivablesPage />} />
        <Route path="receipts" element={<ReceiptsPage />} />
        <Route path="suppliers" element={<SuppliersPage />} />
        <Route path="suppliers/:id" element={<SupplierDetailPage />} />
        <Route path="supplier-payments" element={<SupplierPaymentsPage />} />
        <Route path="expenses" element={<ExpensesPage />} />
        <Route path="cash" element={<CashPage />} />
        <Route path="reports" element={<ReportsHub />} />
        <Route path="reports/:code" element={<ReportPage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
