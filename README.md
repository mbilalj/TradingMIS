# Portside — Post-Arrival Operations MIS

Import business software that starts the moment goods reach the Lahore warehouse (per the Software
Requirements Document). It manages stock by shipment batch, wholesale + retail sales, customers,
suppliers, payments, expenses, cash/bank and basic double-entry accounting as one connected system.
Import costing is **not** calculated — final cost is entered by hand on each shipment.

- `backend/` — Spring Boot 3.5, JPA/Hibernate, MySQL, JWT auth
- `frontend/` — React 19 + TypeScript + Vite + Tailwind

## Run it

```bash
# backend (http://localhost:8080) — set SERVER_PORT if 8080 is taken
cd backend && ./mvnw spring-boot:run

# frontend (http://localhost:5173); API_TARGET overrides the proxy target if the backend port changed
cd frontend && npm install && npm run dev
```

Database defaults are in `backend/src/main/resources/application.yml` (override with `DB_HOST`, `DB_PORT`,
`DB_NAME`, `DB_USER`, `DB_PASSWORD`). On start-up Hibernate creates/extends the `mis_*` tables
(`ddl-auto: update`, which never drops anything, so old container-era tables are left untouched and
unused) and a seeder adds units, the Lahore warehouse, accounting heads, a cash and a bank account, a
walk-in customer and the expense categories.

Demo logins (password `Portside@123`): `owner`, `accountant`, `sales`, `storekeeper`, `importdesk`.

## How the SRD maps to the product

| SRD section | Where |
|---|---|
| 3 Product master, units & conversions | Products (per-product conversion, e.g. 1 Carton = 200 Piece) |
| 4, 12 Shipment/batch + stock receiving | Stock receiving → one batch per product line, manual cost, documents, supplier payable |
| 5 Inventory + adjustments | Stock & batches (by product, by batch, history), Stock adjustment with mandatory reason |
| 6, 7 Wholesale/retail sales, invoice | New sale (retail quick-add by code, wholesale), printable invoice → Save as PDF |
| 8, 9 Customers, ledger, receivables | Customer account + ledger, payments, receivables with overdue ageing |
| 10 Suppliers | Supplier account, ledger, payments |
| 11 Sales returns | Return from any invoice: stock back to original batch, balance/sales/profit adjusted |
| 13, 13.1 Expenses | Every payment is tagged **Operating** (hits P&L) or **Non-operating** (cash/bank only, can be linked to a shipment) |
| 14 Cash & bank | Accounts, money in/out, transfers, balances, cash/bank book |
| 15, 16 Accounting, P&L | Every transaction posts a balanced journal; P&L excludes non-operating payments |
| 17, 18 Profit, batch costing | **Batch-specific costing** — each sale line is tied to a batch (oldest first by default, or chosen) and uses that batch’s cost |
| 19 Dashboard | Dashboard |
| 20, 21 Reports, search | 36 reports with date filters, CSV (Excel) export and print/PDF; global search box |

## Decisions worth knowing

- **Costing method: batch-specific.** Sales default to the oldest batch with stock (FIFO) and can be pointed
  at a specific batch; a line that spans two batches is split so each part carries its own cost.
- **Shipment value** is credited to *Accounts payable* only for the amount you say you still owe the supplier;
  the rest goes to an equity clearing head (“imported stock introduced”), because import settlement happens
  outside this system.
- **Non-operating payments** debit a separate asset head, never an expense head, so they cannot reach profit.
- Overdue = invoice date + the customer’s credit days; customer payments settle the oldest invoices first.
- Reports export to CSV (opens in Excel) and print; “PDF” is the browser’s Save as PDF from the print dialog.

## Tests

`cd backend && ./mvnw test` runs a full cycle on H2: receive at two costs → sell across batches → damaged stock →
operating vs non-operating payments → return → customer payment → trial balance and balance sheet balance, and
every report executes.

## Sample data (Lahore importer)

On first start the backend loads demo data once (`SampleDataSeeder`; marker setting `sample.data.v1`):
6 overseas suppliers (China ×2, UAE, Turkey, Thailand, Malaysia), 16 products, 12 Lahore customers, **8 containers**
received over the last four months, ~100 wholesale/retail invoices sold container by container, customer receipts,
supplier payments, customs/clearing payments linked to containers, a return, stock losses, operating expenses and
cash vouchers. Disable with `SAMPLE_DATA=false`; to reload, clear the database (or delete the `sample.data.v1` row
and the demo records) and restart.

## Container-wise stock

Every receiving record carries a **container number** (required); each product in it is a batch numbered
`<container>-NN`. Sales pick a container per line (defaults to the oldest container with stock; “Any container”
lets a line span several), so cost, profit and returns all trace back to a container.

## Keyboard shortcuts (press `?` in the app)

| Keys | Action |
|---|---|
| `Alt+N` | New record on any list screen (product, customer, supplier, container, sale, return, payment, expense, account…) |
| `↑` `↓` / `Enter` / `Alt+E` / `Delete` / `/` | Highlight a row / open / edit / delete / filter |
| `Ctrl+S` or `Ctrl+Enter` | Save in any dialog or form |
| `Ctrl+P`, `Alt+A` / `F2`, `Alt+Delete` | New sale: save & print, add line, remove line |
| `Alt+R` / `Alt+P` / `Alt+T` | Cash & bank: money in / out / transfer |
| `G` then a letter | Go to a screen (`G S` sales, `G N` new sale, `G P` products, `G R` containers …) |
| `Ctrl+K`, `?` | Global search, shortcut help |

In sales and receiving, **type in the Product box** (code, name or brand) and press `Enter` to pick it; focus then
jumps to the quantity, and `Enter` there starts the next line.
