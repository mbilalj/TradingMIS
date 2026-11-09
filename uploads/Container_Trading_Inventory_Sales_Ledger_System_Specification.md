# Container Trading, Inventory, Sales, Purchase & Ledger Management System

## 1. Purpose

This system is designed for a trading/import business that:

1. Books or purchases a container from a foreign country.
2. Receives a container containing multiple items/SKUs.
3. Clears the container through customs and pays duties, taxes, clearing, freight and other charges.
4. Enters the imported items into the system using a **lump-sum inventory value / declared system value**, rather than necessarily recording the actual supplier cost against every item.
5. Maintains container-wise and item-wise inventory.
6. Sells items to retailers, wholesalers and other customers.
7. Uses customer-specific selling prices and discounts.
8. Tracks receivables/payments.
9. Maintains a general ledger and accounting transactions.
10. Produces gross profit, margin, stock, container profitability and customer reports.

> **Important accounting design point:** The system should separately capture **commercial/supplier purchase price**, **customs/declaration value**, **landed costs**, **inventory valuation**, and **sales price** where applicable. The business may choose to use a lump-sum value for operational inventory entry, but the system should preserve the underlying source values for auditability.

---

# 2. Core Business Flow

```text
Supplier / Overseas Purchase
        |
        v
Container Booking / Import File
        |
        v
Container Items / Expected Quantity
        |
        v
Shipping / Freight / Documentation
        |
        v
Customs Clearance
        |
        +--> Customs Duty
        +--> Taxes
        +--> Clearing Charges
        +--> Port Charges
        +--> Freight
        +--> Other Charges
        |
        v
Container Received / Warehouse GRN
        |
        v
Inventory by Container + Item
        |
        v
Pricing / Customer Price List
        |
        v
Sales Order
        |
        v
Delivery / Invoice
        |
        v
Customer Receivable
        |
        v
Customer Payment
        |
        v
Ledger / Financial Reporting
```

---

# 3. Recommended System Modules

## Module 01 — Organization & Company Setup

### Purpose

Maintain company-level configuration.

### Inputs

- Company Name
- Legal Name
- Registration Number
- NTN
- STRN
- Address
- City
- Country
- Phone
- Email
- Website
- Logo
- Fiscal Year
- Base Currency
- Secondary Currencies
- Tax Configuration
- Default Warehouse
- Default Sales Account
- Default Purchase Account
- Default Inventory Account
- Default Receivable Account
- Default Payable Account
- Default Cash Account
- Default Bank Account

### Features

- Multiple branches
- Multiple warehouses
- Financial year configuration
- Currency configuration
- Tax configuration
- Numbering configuration
- Document prefix configuration

---

# 4. Module 02 — User, Roles & Security Management

## Users

### Inputs

- User ID
- Name
- Email
- Mobile
- Username
- Password / Authentication Reference
- Role
- Branch
- Warehouse
- Status

## Roles

Suggested roles:

- System Administrator
- Management
- Import Manager
- Purchase Officer
- Warehouse Manager
- Sales Manager
- Sales Officer
- Accounts Manager
- Accounts Officer
- Auditor
- Viewer

## Permissions

Permissions should be controlled at:

- Module level
- Screen level
- Create
- Edit
- Delete
- View
- Approve
- Post
- Cancel
- Print
- Export
- Financial-value visibility

## Approval Workflow

Examples:

- Container booking approval
- Purchase approval
- Customs expense approval
- Stock adjustment approval
- Sales discount approval
- Sales invoice approval
- Credit sale approval
- Payment approval

---

# 5. Module 03 — Master Data Management

This is the foundation of the entire system.

## 5.1 Item / Product Master

### Inputs

- Item Code / SKU
- Barcode
- Item Name
- Short Description
- Long Description
- Category
- Subcategory
- Brand
- Model
- Country of Origin
- HS Code
- Unit of Measure
- Purchase UOM
- Sales UOM
- Conversion Factor
- Weight
- Dimensions
- Package Type
- Color
- Size
- Serial Number Requirement
- Batch Requirement
- Expiry Requirement
- Minimum Stock
- Maximum Stock
- Reorder Level
- Default Purchase Price
- Default Sales Price
- Tax Rate
- Active / Inactive

### Optional Attributes

- Size
- Color
- Material
- Grade
- Specification
- Manufacturer Part Number

---

# 6. Module 04 — Item Category & Classification

### Hierarchy

```text
Category
  |
  +-- Subcategory
        |
        +-- Brand
              |
              +-- Item
```

### Examples

- Electronics
- Auto Parts
- Machinery
- Garments
- Household Items
- Industrial Goods

### Inputs

- Category Code
- Category Name
- Parent Category
- Description
- Status

---

# 7. Module 05 — Supplier Management

## Supplier Master

### Inputs

- Supplier Code
- Supplier Name
- Supplier Type
- Country
- City
- Address
- Contact Person
- Phone
- Email
- Website
- Tax ID
- NTN / Registration
- Currency
- Payment Terms
- Credit Limit
- Bank Details
- Account / Ledger
- Status

## Supplier Types

- Overseas Supplier
- Local Supplier
- Shipping Agent
- Clearing Agent
- Freight Forwarder
- Other Service Provider

---

# 8. Module 06 — Customer Management

## Customer Master

### Inputs

- Customer Code
- Customer Name
- Customer Type
- Retailer / Wholesaler / Distributor / Other
- Contact Person
- Mobile
- Email
- Address
- City
- Area
- NTN
- STRN
- CNIC (if required)
- Credit Limit
- Payment Terms
- Default Discount
- Price List
- Customer-specific Price
- Tax Profile
- Sales Representative
- Opening Balance
- Status

## Customer Classification

```text
Customer
   |
   +-- Retailer
   +-- Wholesaler
   +-- Distributor
   +-- Cash Customer
   +-- Credit Customer
```

---

# 9. Module 07 — Warehouse & Location Management

### Inputs

- Warehouse Code
- Warehouse Name
- Branch
- Address
- Manager
- Capacity
- Status

## Locations

- Rack
- Shelf
- Bin
- Floor
- Zone

### Stock Tracking

Every inventory transaction should be traceable to:

- Warehouse
- Location
- Container
- Item
- Batch
- Serial Number where applicable

---

# 10. Module 08 — Currency & Exchange Rate

Since imports originate from foreign countries, multi-currency support is important.

### Inputs

- Currency
- Currency Code
- Exchange Rate
- Effective Date
- Rate Type
- Source

### Supported Rate Types

- Commercial Bank Rate
- Customs Rate
- Company Rate
- Invoice Rate

The system should preserve the exchange rate used on every transaction.

---

# 11. Module 09 — Import / Container Management

This is the **core module** of the system.

## Container / Import File

Each container should have a unique Import File / Container ID.

### Inputs

- Container ID
- Container Number
- Booking Number
- Supplier
- Country of Origin
- Port of Loading
- Port of Discharge
- Shipping Line
- Freight Forwarder
- Clearing Agent
- Vessel Name
- Voyage Number
- BL Number
- Commercial Invoice Number
- Invoice Date
- Invoice Currency
- Invoice Amount
- Container Type
- Container Size
- Booking Date
- Shipment Date
- ETA
- Arrival Date
- Customs Declaration Number
- Customs Clearance Date
- Warehouse Receipt Date
- Status

## Container Status

```text
Draft
Booked
Supplier Confirmed
In Transit
Arrived Port
Under Clearance
Cleared
Received Warehouse
Partially Received
Fully Received
Closed
Cancelled
```

---

# 12. Module 10 — Container Item / Packing List

Each container can contain many items.

### Inputs

- Container ID
- Item Code
- Item Description
- Supplier Item Code
- HS Code
- Quantity
- UOM
- Package Count
- Cartons
- Net Weight
- Gross Weight
- Supplier Purchase Price
- Currency
- Declared Value
- System Inventory Value
- Expected Sales Price
- Notes

### Container Item Status

- Expected
- Partially Received
- Received
- Short
- Excess
- Damaged
- Rejected

---

# 13. Module 11 — Purchase / Import Cost Management

The system should distinguish different types of values.

## A. Supplier Purchase Value

Actual amount payable to supplier.

## B. Customs / Declared Value

Value used for customs declaration.

## C. Operational Inventory Value

The value entered by the business for inventory management.

## D. Landed Cost

Actual total cost associated with bringing the container into warehouse.

### Cost Components

- Supplier Purchase
- Freight
- Insurance
- Customs Duty
- Sales Tax
- Additional Customs Duty
- Regulatory Duty
- Income Tax / Withholding
- Port Charges
- Terminal Charges
- Clearing Agent
- Transport
- Documentation
- Bank Charges
- Demurrage
- Inspection Charges
- Other Expenses

---

# 14. Module 12 — Customs Clearance Management

## Inputs

- Container ID
- GD / Declaration Number
- Customs Agent
- Customs Port
- Assessment Date
- Clearance Date
- Customs Value
- Duty
- Sales Tax
- Additional Duty
- Regulatory Duty
- Other Taxes
- Penalties
- Port Charges
- Clearing Charges
- Payment Reference
- Payment Date
- Bank
- Remarks

## Documents

- Commercial Invoice
- Packing List
- Bill of Lading
- GD
- Customs Assessment
- Duty Payment
- Delivery Order
- Other Documents

---

# 15. Module 13 — Container Expense Management

All expenses should be attached to the relevant container.

### Expense Categories

- Freight
- Customs Duty
- Clearing
- Port
- Transport
- Insurance
- Bank Charges
- Documentation
- Storage
- Demurrage
- Inspection
- Miscellaneous

### Inputs

- Container ID
- Expense Date
- Expense Type
- Vendor
- Amount
- Currency
- Exchange Rate
- Local Amount
- Payment Method
- Reference Number
- Remarks
- Attachment

---

# 16. Module 14 — Landed Cost Calculation

This module calculates the actual cost of bringing stock into the warehouse.

## Example

Container has:

```text
Supplier Invoice             = $50,000
Freight                      = $4,000
Insurance                    = $500
Customs Duty                 = $8,000
Taxes                        = $5,000
Clearing                     = $1,000
Port Charges                 = $1,500
Transport                    = $1,000

Total Landed Cost            = $71,000
```

If the business wants operational inventory to be entered as a lump sum:

```text
Container Inventory Value = PKR X
```

the system should still maintain the detailed cost records.

## Allocation Methods

Landed cost may be allocated by:

1. Quantity
2. Item value
3. Weight
4. Volume
5. Manual allocation
6. Equal allocation
7. Custom allocation percentage

---

# 17. Module 15 — Inventory Receipt / GRN

When a container reaches the warehouse, the user creates a Goods Receipt Note.

### Inputs

- GRN Number
- Container ID
- Warehouse
- Location
- Receipt Date
- Item
- Expected Quantity
- Received Quantity
- Damaged Quantity
- Short Quantity
- Excess Quantity
- Inventory Value
- Unit Value
- Batch
- Serial
- Remarks

### Validation

```text
Expected Qty
       |
       +-- Received
       +-- Short
       +-- Excess
       +-- Damaged
```

---

# 18. Module 16 — Container-wise Inventory

This is one of the most important management views.

### Report Fields

- Container Number
- Supplier
- Item
- SKU
- Quantity
- Available Quantity
- Sold Quantity
- Reserved Quantity
- Damaged Quantity
- Unit Inventory Value
- Total Inventory Value
- Sales Value
- Gross Profit
- Gross Margin %
- Warehouse
- Location

### Drill Down

```text
Container
   |
   +-- Item
       |
       +-- Received
       +-- Sold
       +-- Available
       +-- Sales
       +-- Profit
```

---

# 19. Module 17 — Inventory Management

## Stock Transactions

- Opening Stock
- Import Receipt
- Purchase Receipt
- Sales Issue
- Sales Return
- Purchase Return
- Stock Transfer
- Stock Adjustment
- Damage
- Loss
- Found Stock

## Stock Ledger

For each item:

```text
Date
Document
Container
Warehouse
Opening Qty
Received Qty
Issued Qty
Balance Qty
Unit Value
Stock Value
```

---

# 20. Module 18 — Stock Transfer

Transfers between warehouses.

### Inputs

- Transfer Number
- Date
- From Warehouse
- To Warehouse
- Item
- Container
- Quantity
- Location
- Remarks

### Workflow

```text
Draft
   ↓
Requested
   ↓
Approved
   ↓
Dispatched
   ↓
Received
   ↓
Completed
```

---

# 21. Module 19 — Stock Adjustment

For discrepancies.

### Inputs

- Adjustment Number
- Date
- Warehouse
- Item
- Container
- Current Quantity
- Adjustment Quantity
- Reason
- Supporting Document
- Approval
- Remarks

### Reasons

- Physical Count Difference
- Damage
- Theft/Loss
- Data Correction
- Expiry
- Other

---

# 22. Module 20 — Physical Stock Count

### Inputs

- Stock Count Number
- Date
- Warehouse
- Counter
- Item
- Container
- System Quantity
- Physical Quantity
- Difference
- Reason
- Approval

### Reports

- Stock Variance
- Positive Variance
- Negative Variance
- Adjustment Required

---

# 23. Module 21 — Sales Price Management

The company requires different selling prices depending upon customer.

## Price Lists

Example:

```text
Retail Price
Wholesale Price
Distributor Price
Special Customer Price
Promotional Price
```

### Inputs

- Price List
- Item
- Customer Type
- Customer
- Sales Price
- Minimum Quantity
- Maximum Quantity
- Discount %
- Effective From
- Effective To
- Currency
- Tax
- Status

---

# 24. Module 22 — Customer-specific Pricing

A customer can have a special negotiated price.

### Priority

```text
Customer + Item Price
        ↓
Customer Type Price
        ↓
Price List
        ↓
Default Item Price
```

### Inputs

- Customer
- Item
- Price
- Discount %
- Effective Date
- Expiry Date
- Minimum Quantity
- Approval

---

# 25. Module 23 — Sales Order

### Inputs

- Sales Order Number
- Date
- Customer
- Customer Type
- Salesperson
- Warehouse
- Item
- Container
- Quantity
- Unit Price
- Discount %
- Discount Amount
- Tax
- Net Amount
- Delivery Date
- Payment Terms
- Remarks

### Status

- Draft
- Approved
- Reserved
- Partially Delivered
- Delivered
- Cancelled

---

# 26. Module 24 — Delivery Note / Stock Issue

### Inputs

- Delivery Number
- Sales Order
- Customer
- Warehouse
- Item
- Container
- Quantity
- Batch / Serial
- Delivery Date
- Vehicle
- Driver
- Receiver
- Remarks

Stock is reduced only when the defined business process permits the delivery/issue transaction.

---

# 27. Module 25 — Sales Invoice

### Inputs

- Invoice Number
- Date
- Customer
- Sales Order
- Delivery Note
- Item
- Container
- Quantity
- Unit Price
- Gross Amount
- Discount %
- Discount Amount
- Tax
- Net Amount
- Payment Terms
- Due Date
- Salesperson

### Formula

```text
Gross Sales = Quantity × Selling Price

Discount = Gross Sales × Discount %

Net Sales = Gross Sales - Discount + Applicable Tax
```

---

# 28. Module 26 — Sales Return

### Inputs

- Return Number
- Customer
- Original Invoice
- Item
- Container
- Quantity
- Selling Price
- Discount
- Reason
- Condition
- Warehouse
- Restocking Decision

---

# 29. Module 27 — Purchase Return

For returns to supplier.

### Inputs

- Purchase Document
- Supplier
- Container
- Item
- Quantity
- Unit Cost
- Reason
- Date
- Warehouse
- Financial Adjustment

---

# 30. Module 28 — Customer Receivables

Tracks customer outstanding balances.

### Inputs

- Customer
- Invoice
- Invoice Date
- Due Date
- Invoice Amount
- Discount
- Paid Amount
- Outstanding Amount
- Aging
- Payment Status

### Aging

```text
Current
1–30 Days
31–60 Days
61–90 Days
91–120 Days
120+ Days
```

---

# 31. Module 29 — Customer Payment / Receipt

### Inputs

- Receipt Number
- Customer
- Date
- Payment Method
- Bank/Cash Account
- Amount
- Reference
- Cheque Number
- Cheque Date
- Invoice Allocation
- Remarks

### Payment Methods

- Cash
- Bank Transfer
- Cheque
- Online Transfer
- Other

---

# 32. Module 30 — Supplier Payables

### Inputs

- Supplier
- Invoice
- Due Date
- Amount
- Paid
- Outstanding
- Aging
- Payment Terms

---

# 33. Module 31 — Supplier Payment

### Inputs

- Payment Number
- Supplier
- Date
- Bank/Cash
- Amount
- Reference
- Invoice Allocation
- Remarks

---

# 34. Module 32 — General Ledger / Accounting

The system should have a double-entry accounting engine.

## Chart of Accounts

### Suggested Structure

```text
Assets
  Cash
  Bank
  Inventory
  Accounts Receivable
  Prepayments

Liabilities
  Accounts Payable
  Taxes Payable
  Other Liabilities

Equity
  Capital
  Retained Earnings

Revenue
  Sales
  Other Income

Cost of Sales
  Cost of Goods Sold

Expenses
  Freight
  Customs
  Clearing
  Salaries
  Rent
  Utilities
  Bank Charges
  Other Expenses
```

---

# 35. Module 33 — Journal Voucher

### Inputs

- Journal Number
- Date
- Description
- Reference
- Debit Account
- Credit Account
- Amount
- Cost Center
- Container
- Customer
- Supplier
- Remarks
- Attachment

### Rule

```text
Total Debit = Total Credit
```

---

# 36. Module 34 — Cash & Bank Management

### Cash

- Cash Account
- Cash Receipt
- Cash Payment
- Cash Transfer
- Opening Balance

### Bank

- Bank
- Account Number
- Bank Receipt
- Bank Payment
- Transfer
- Cheque
- Reconciliation

---

# 37. Module 35 — Bank Reconciliation

### Inputs

- Bank Account
- Statement Date
- Statement Balance
- System Balance
- Transaction
- Reconciled Status
- Difference
- Reconciliation Date

---

# 38. Module 36 — Tax Management

Support configurable tax structures.

### Inputs

- Tax Type
- Tax Rate
- Effective Date
- Tax Account
- Sales Tax
- Withholding Tax
- Customs Taxes
- Other Tax

### Reports

- Tax Summary
- Sales Tax
- Purchase Tax
- Withholding Tax
- Tax Payable
- Tax Receivable

---

# 39. Module 37 — Gross Profit & Margin Engine

This is a critical management feature.

## Sales

```text
Gross Sales
- Discount
= Net Sales
```

## Gross Profit

```text
Gross Profit = Net Sales - Cost of Goods Sold
```

## Gross Margin

```text
Gross Margin % =
(Gross Profit / Net Sales) × 100
```

## Example

```text
Item Quantity                  = 100

Inventory Cost / Unit          = PKR 700
Selling Price / Unit           = PKR 1,000

Gross Sales                    = 100,000
Discount 5%                    = 5,000
Net Sales                      = 95,000

COGS                           = 70,000

Gross Profit                   = 25,000

Gross Margin                   = 26.32%
```

---

# 40. Module 38 — Cost Basis Configuration

Because the company enters inventory using lump-sum values, cost calculation must be configurable.

## Possible Cost Methods

- Fixed entered cost
- Weighted Average Cost
- FIFO
- Specific Container Cost
- Specific Batch Cost
- Landed Cost
- Manual Management Cost

### Recommended

For this business, support:

**Container-specific inventory valuation + configurable cost allocation.**

This makes container profitability possible.

---

# 41. Module 39 — Container Profitability

Management should be able to select a container and see:

```text
Container
Supplier
Total Inventory Value
Total Landed Cost
Total Quantity
Sales Value
Discount
Net Sales
COGS
Gross Profit
Gross Margin %
Remaining Stock Value
Remaining Stock Quantity
```

### Example

```text
Container C-001

Inventory Value       10,000,000
Additional Costs       2,000,000
Total Cost            12,000,000

Sold Value            15,000,000
Discount                 500,000
Net Sales             14,500,000

COGS                   8,000,000

Gross Profit           6,500,000
Gross Margin              44.83%
```

---

# 42. Module 40 — Sales Profitability

Profit should be visible at multiple levels:

- Invoice
- Customer
- Customer Type
- Item
- Category
- Salesperson
- Warehouse
- Container
- Date
- Month
- Year

### Report

| Item | Qty | Gross Sales | Discount | Net Sales | COGS | Gross Profit | Margin % |
|---|---:|---:|---:|---:|---:|---:|---:|
| Item A | 100 | 100,000 | 5,000 | 95,000 | 70,000 | 25,000 | 26.32% |

---

# 43. Module 41 — Dashboard

## Management Dashboard

### KPIs

- Total Inventory Value
- Total Inventory Quantity
- Number of Containers
- Containers in Transit
- Containers Under Clearance
- Containers Received
- Monthly Sales
- Monthly Purchases
- Gross Profit
- Gross Margin %
- Customer Receivables
- Supplier Payables
- Cash Balance
- Bank Balance
- Slow-moving Stock
- Fast-moving Stock
- Stock Aging

### Charts

- Sales by Month
- Profit by Month
- Sales by Customer
- Sales by Item Category
- Container Profitability
- Inventory by Warehouse
- Inventory by Container
- Receivables Aging

---

# 44. Module 42 — Reports

## A. Container Reports

1. Container Register
2. Container Status Report
3. Container Item List
4. Container-wise Stock
5. Container-wise Inventory Value
6. Container-wise Sales
7. Container-wise Profit
8. Container-wise Remaining Stock
9. Container Cost Summary
10. Container Expense Detail
11. Container Landed Cost
12. Container Clearance Report
13. Container Aging
14. Container Receipt Report

---

# 45. Inventory Reports

1. Stock Position
2. Stock Ledger
3. Item-wise Stock
4. Warehouse-wise Stock
5. Container-wise Stock
6. Category-wise Stock
7. Brand-wise Stock
8. Stock Valuation
9. Available Stock
10. Reserved Stock
11. Damaged Stock
12. Slow Moving Stock
13. Fast Moving Stock
14. Dead Stock
15. Stock Aging
16. Stock Adjustment Report
17. Physical Stock Variance
18. Stock Transfer Report
19. Reorder Report

---

# 46. Sales Reports

1. Sales Register
2. Sales Invoice Register
3. Customer-wise Sales
4. Item-wise Sales
5. Category-wise Sales
6. Salesperson-wise Sales
7. Warehouse-wise Sales
8. Container-wise Sales
9. Daily Sales
10. Monthly Sales
11. Yearly Sales
12. Discount Report
13. Customer-specific Pricing Report
14. Sales Return Report
15. Outstanding Sales
16. Gross Sales vs Net Sales

---

# 47. Profitability Reports

1. Gross Profit Report
2. Gross Margin Report
3. Item-wise Gross Profit
4. Customer-wise Gross Profit
5. Container-wise Gross Profit
6. Category-wise Gross Profit
7. Salesperson-wise Gross Profit
8. Monthly Gross Profit
9. Profit after Discount
10. Profitability by Price List
11. Profitability by Customer Type
12. Low Margin Sales Report

---

# 48. Purchase / Import Reports

1. Purchase Register
2. Supplier-wise Purchases
3. Container-wise Purchases
4. Item-wise Purchases
5. Import Cost Report
6. Landed Cost Report
7. Customs Duty Report
8. Freight Report
9. Clearing Expense Report
10. Supplier Payables
11. Purchase Return Report

---

# 49. Customer Reports

1. Customer Ledger
2. Customer Statement
3. Customer Aging
4. Customer Outstanding
5. Customer Sales
6. Customer Profitability
7. Customer Discount Report
8. Customer Price List
9. Customer Payment History
10. Credit Limit Utilization

---

# 50. Supplier Reports

1. Supplier Ledger
2. Supplier Statement
3. Supplier Balance
4. Supplier Purchases
5. Supplier Payment History
6. Supplier Outstanding
7. Supplier Aging
8. Supplier-wise Container Report

---

# 51. Accounting Reports

1. Trial Balance
2. General Ledger
3. Chart of Accounts
4. Journal Register
5. Cash Book
6. Bank Book
7. Bank Reconciliation
8. Accounts Receivable
9. Accounts Payable
10. Profit & Loss
11. Balance Sheet
12. Cash Flow
13. Expense Report
14. Tax Report

---

# 52. Module 43 — Document Management

Documents should be attachable to transactions.

### Documents

- Supplier Invoice
- Packing List
- Bill of Lading
- Customs GD
- Customs Assessment
- Duty Payment
- Clearing Invoice
- Freight Invoice
- Delivery Order
- GRN
- Sales Invoice
- Purchase Invoice
- Payment Voucher
- Receipt
- Cheque
- Other Supporting Documents

### Requirements

- File upload
- File type validation
- Document version
- Document date
- Description
- Uploaded by
- Uploaded date
- Access permissions

---

# 53. Module 44 — Audit Trail

Every important transaction should record:

- Created By
- Created Date/Time
- Modified By
- Modified Date/Time
- Approved By
- Approved Date
- Posted By
- Posted Date
- Cancelled By
- Cancellation Reason

### Audit Events

- Login
- Create
- Update
- Delete
- Approve
- Reject
- Post
- Cancel
- Price Change
- Discount Change
- Stock Adjustment
- Journal Adjustment

---

# 54. Module 45 — Notifications

### Notifications

- Container arrival
- Customs clearance pending
- Container received
- Stock below reorder level
- Customer credit limit exceeded
- Invoice overdue
- Supplier payment due
- Low margin sale
- High discount sale
- Approval pending

---

# 55. Module 46 — Search & Global Transaction Traceability

A global search should allow users to search:

- Container Number
- Item Code
- Item Name
- Supplier
- Customer
- Invoice Number
- Sales Order
- GRN
- GD Number
- Bill of Lading
- Payment Reference

## Transaction Trace

Example:

```text
Container C-1001
   ↓
Purchase
   ↓
Customs Clearance
   ↓
GRN
   ↓
Inventory
   ↓
Sales Order
   ↓
Delivery
   ↓
Sales Invoice
   ↓
Customer Payment
   ↓
Ledger
```

---

# 56. Module 47 — Import Data / Excel Upload

For initial migration and bulk operations.

### Excel Imports

- Items
- Customers
- Suppliers
- Opening Stock
- Opening Receivables
- Opening Payables
- Containers
- Container Items
- Prices
- Sales
- Purchases

### Validation

- Duplicate codes
- Invalid quantities
- Missing required fields
- Invalid customer
- Invalid item
- Invalid container
- Invalid prices
- Invalid dates

---

# 57. Module 48 — Opening Balances

### Opening Inventory

- Item
- Container
- Warehouse
- Quantity
- Unit Value
- Total Value

### Opening Customer Balance

- Customer
- Invoice / Reference
- Debit
- Credit
- Balance

### Opening Supplier Balance

- Supplier
- Reference
- Debit
- Credit
- Balance

### Opening Cash / Bank

- Account
- Opening Balance
- Date

---

# 58. Module 49 — System Configuration

### Configurable Parameters

- Invoice Prefix
- Container Prefix
- GRN Prefix
- Customer Prefix
- Supplier Prefix
- Currency
- Decimal Places
- Tax Rates
- Default Discount
- Approval Rules
- Stock Costing Method
- Negative Stock Allowed
- Credit Sale Allowed
- Backdated Transaction Allowed
- Financial Period Lock
- Document Numbering

---

# 59. Key Database Entities

A suggested high-level data model:

```text
Company
Branch
Warehouse
Location

User
Role
Permission

Customer
CustomerType
CustomerPrice

Supplier

Item
ItemCategory
Brand
UOM

Container
ContainerItem
ContainerExpense
CustomsClearance
LandedCost
GRN
GRNItem

InventoryTransaction
StockLedger
StockAdjustment
StockTransfer

PriceList
ItemPrice

SalesOrder
SalesOrderItem
DeliveryNote
DeliveryItem
SalesInvoice
SalesInvoiceItem
SalesReturn
SalesReturnItem

Purchase
PurchaseItem
PurchaseReturn

CustomerReceipt
SupplierPayment

ChartOfAccount
Journal
JournalLine

Tax
Currency
ExchangeRate

Document
AuditLog
Approval
```

---

# 60. Critical Relationships

```text
Supplier
   |
   +---- Container
             |
             +---- Container Items
             |
             +---- Customs
             |
             +---- Expenses
             |
             +---- GRN
                     |
                     +---- Inventory
                              |
                              +---- Sales
                                      |
                                      +---- Invoice
                                              |
                                              +---- Customer
                                              |
                                              +---- Receivable
```

---

# 61. Gross Profit Calculation Design

The system should never simply calculate profit as:

```text
Selling Price - Entered Purchase Price
```

without defining the cost basis.

Instead:

```text
Sales Invoice
     |
     +-- Quantity
     +-- Gross Selling Price
     +-- Discount
     +-- Net Selling Price
     |
     v
Inventory Issue
     |
     +-- Container
     +-- Item
     +-- Cost Basis
     |
     v
COGS
     |
     v
Gross Profit
```

## Formula

```text
Net Sales
=
Quantity × Selling Price
- Discount
- Sales Returns
+/- Applicable Adjustments
```

```text
Gross Profit
=
Net Sales - COGS
```

```text
Gross Margin %
=
Gross Profit / Net Sales × 100
```

---

# 62. Recommended Cost Tracking Model

Because the business specifically wants **container-wise stock and profitability**, every inventory quantity should retain its source.

Example:

```text
ITEM-001

Container C001
Received = 500
Cost = PKR 800

Container C002
Received = 300
Cost = PKR 850

Total Stock = 800
```

If 200 units are sold, the system can determine exactly which container supplied the stock.

This is much better than maintaining only:

```text
ITEM-001 = 600 units
```

because management loses container-level profitability.

---

# 63. Recommended Inventory Costing Options

The application should support configurable inventory costing:

## Option A — FIFO

Oldest container stock is sold first.

## Option B — Weighted Average

Average cost is recalculated based on receipts.

## Option C — Specific Container

User selects the container from which stock is sold.

## Option D — Manual Cost

Management-defined cost.

### Recommended Initial Implementation

Use:

**Specific Container + FIFO fallback + configurable weighted average reporting.**

---

# 64. Discount Management

Discount should be stored separately from price.

Example:

```text
List Price       = 1,000
Discount         = 10%
Discount Amount  = 100
Net Price        = 900
```

Do not overwrite the original selling price.

This allows management to report:

- Sales before discount
- Discount amount
- Discount %
- Sales after discount
- Profit after discount

---

# 65. Low Margin Control

The system should optionally prevent or warn against low-margin sales.

Example:

```text
Cost = 800
Selling Price = 850
Margin = 5.88%
```

If minimum allowed margin = 10%:

```text
WARNING:
Sale margin is below approved minimum.
Approval required.
```

---

# 66. Credit Control

Before confirming a credit sale:

```text
Current Outstanding
+
New Invoice
-
Available Credit Limit
```

If exceeded:

```text
Credit Limit Exceeded
Approval Required
```

---

# 67. Important Business KPIs

Management dashboard should include:

### Inventory

- Total Stock
- Stock Value
- Stock by Container
- Stock by Warehouse
- Slow Moving Stock
- Dead Stock

### Sales

- Today's Sales
- Monthly Sales
- Year-to-Date Sales
- Average Invoice Value
- Discount %

### Profit

- Gross Profit
- Gross Margin %
- Profit by Item
- Profit by Customer
- Profit by Container

### Finance

- Receivables
- Payables
- Cash
- Bank
- Overdue Customers

### Import

- Containers in Transit
- Containers at Port
- Containers Under Clearance
- Containers Received
- Average Clearance Cost
- Average Landed Cost

---

# 68. Recommended Screens / Menu Structure

```text
DASHBOARD

MASTERS
  ├── Items
  ├── Categories
  ├── Brands
  ├── Customers
  ├── Suppliers
  ├── Warehouses
  ├── Locations
  ├── UOM
  ├── Currencies
  └── Tax

IMPORT
  ├── Container Booking
  ├── Container Register
  ├── Container Items
  ├── Shipping
  ├── Customs Clearance
  ├── Container Expenses
  ├── Landed Cost
  └── Container Documents

PURCHASE
  ├── Purchase
  ├── Purchase Receipt
  └── Purchase Return

INVENTORY
  ├── GRN
  ├── Stock
  ├── Stock Ledger
  ├── Stock Transfer
  ├── Stock Adjustment
  ├── Physical Count
  └── Stock Valuation

SALES
  ├── Price Lists
  ├── Customer Pricing
  ├── Sales Orders
  ├── Delivery Notes
  ├── Sales Invoices
  └── Sales Returns

ACCOUNTS
  ├── Customer Receipts
  ├── Supplier Payments
  ├── Cash
  ├── Bank
  ├── Journal Voucher
  ├── General Ledger
  └── Chart of Accounts

REPORTS
  ├── Container
  ├── Inventory
  ├── Sales
  ├── Purchases
  ├── Profitability
  ├── Customers
  ├── Suppliers
  └── Accounts

ADMIN
  ├── Users
  ├── Roles
  ├── Approvals
  ├── Audit Trail
  ├── Numbering
  └── System Configuration
```

---

# 69. MVP Scope

If the client wants a first release, prioritize:

### Phase 1

1. Company Setup
2. Users/Roles
3. Item Master
4. Customer Master
5. Supplier Master
6. Warehouse
7. Container Management
8. Container Items
9. Customs & Expenses
10. GRN
11. Container-wise Inventory
12. Stock Ledger
13. Price Management
14. Sales Invoice
15. Customer Receipts
16. Supplier Payments
17. Customer Ledger
18. Supplier Ledger
19. General Ledger
20. Gross Profit Report
21. Container Profitability
22. Basic Dashboard
23. Audit Trail
24. Excel Import/Export

---

# 70. Phase 2

1. Advanced landed cost allocation
2. Multi-warehouse
3. Barcode
4. Batch/serial tracking
5. Sales Order
6. Delivery Note
7. Purchase workflow
8. Credit control
9. Approval workflows
10. Bank reconciliation
11. Tax reporting
12. Advanced dashboards
13. Mobile/responsive operations

---

# 71. Phase 3

1. BI / analytics
2. Demand forecasting
3. Stock forecasting
4. Automated reorder recommendations
5. Customer profitability analytics
6. Supplier performance analytics
7. Container profitability forecasting
8. Advanced pricing engine
9. API integrations
10. Accounting software integration
11. Customs/shipping integrations where available

---

# 72. Non-Functional Requirements

## Security

- Role-based access
- Password policy / SSO option
- Session management
- Audit logs
- Encryption in transit
- Encryption at rest
- Backup
- Restore procedure
- Financial period locking

## Performance

Target:

- Normal screen response < 2–3 seconds
- Report filtering < 5 seconds for normal operational datasets
- Pagination for large data
- Asynchronous export for large reports

## Availability

- Daily database backup
- Backup retention policy
- Disaster recovery
- Monitoring
- Error logging

---

# 73. Critical Controls

The system should enforce:

1. No stock issue without available stock unless explicitly allowed.
2. No posted transaction should be silently edited.
3. Financial changes require audit trail.
4. Container should be linked to imported inventory.
5. Sales should identify inventory source/cost.
6. Discounts should be separately recorded.
7. Customer credit limits should be enforceable.
8. Journal entries must balance.
9. Cancelled transactions must retain history.
10. Stock adjustments require reason and authorization.
11. Price changes should be audited.
12. Container expenses should be traceable to the relevant container.
13. Customs expenses should be distinguishable from inventory selling value.
14. Reports should use posted/approved transactions according to configuration.

---

# 74. Key Management Reports — Final Priority List

The client specifically requested gross profit and container-wise inventory. The following should be treated as priority reports:

### 1. Container Stock Report

```text
Container | Item | Received | Sold | Available | Value
```

### 2. Container Profitability Report

```text
Container
Total Cost
Total Sales
Discount
Net Sales
COGS
Gross Profit
Gross Margin %
Remaining Stock
```

### 3. Item Gross Profit Report

```text
Item
Qty Sold
Sales Price
Discount
Net Sales
Cost
Gross Profit
Margin %
```

### 4. Customer Profitability Report

```text
Customer
Sales
Discount
Net Sales
COGS
Gross Profit
Margin %
```

### 5. Sales Register

```text
Invoice
Date
Customer
Item
Container
Qty
Price
Discount
Net Sales
Cost
Profit
Margin %
```

### 6. Inventory Valuation

```text
Container
Item
Qty
Unit Cost
Total Cost
```

### 7. Customer Aging

```text
Customer
Current
1-30
31-60
61-90
90+
Total
```

### 8. Stock Aging

```text
Item
Container
Received Date
Quantity
Value
Days in Stock
```

---

# 75. Recommended Architecture

For a modern business application:

```text
Frontend
   |
   | REST API
   v
Backend Application
   |
   +---- Authentication / Authorization
   |
   +---- Inventory Service
   +---- Import / Container Service
   +---- Sales Service
   +---- Purchase Service
   +---- Accounting Service
   +---- Reporting Service
   |
   v
Relational Database
   |
   +---- Transaction Data
   +---- Inventory Ledger
   +---- Accounting Ledger
   +---- Audit Trail
```

For an initial implementation, a **modular monolith** is generally preferable to immediately introducing microservices. The modules should have clean boundaries so that high-volume or independently scalable services can be extracted later.

---

# 76. Most Important Design Decision

The client is describing two different concepts:

### Purchase / Import Cost

What the company actually paid or incurred.

### Inventory Selling/Management Value

The lump-sum value that management wants to use when entering stock.

These should **not be stored as one field**.

Recommended structure:

```text
Supplier Purchase Value
Customs Declared Value
Freight
Duty
Taxes
Clearing
Other Landed Costs
--------------------------------
Calculated Landed Cost

Management Inventory Value
Sales Price
Discount
Net Sales Price
```

This separation will make the system much more useful for:

- Gross profit
- Container profitability
- Cost analysis
- Customs analysis
- Management reporting
- Accounting
- Audit
- Future valuation changes

---

# 77. Final End-to-End Transaction Example

```text
1. Supplier sends container
       |
2. Create Container C-1001
       |
3. Add 50 different items
       |
4. Enter supplier purchase information
       |
5. Enter customs declaration
       |
6. Record duty/taxes
       |
7. Record freight/clearing/port expenses
       |
8. Calculate landed cost
       |
9. Container arrives
       |
10. Create GRN
       |
11. Stock becomes available
       |
12. Inventory remains linked to C-1001
       |
13. Define customer prices
       |
14. Customer A gets Price A
       |
15. Customer B gets Price B
       |
16. Create Sales Order
       |
17. Deliver goods
       |
18. Create Sales Invoice
       |
19. Apply customer discount
       |
20. Calculate COGS
       |
21. Calculate gross profit
       |
22. Receive customer payment
       |
23. Update customer ledger
       |
24. Update cash/bank
       |
25. Update GL
       |
26. Container profitability report updates
       |
27. Remaining container stock updates
```

---

# 78. Recommended Project Deliverables

The implementation project should produce:

1. Business Requirement Document (BRD)
2. Functional Requirement Document (FRD)
3. Process Flow Diagrams
4. Database ERD
5. UI/UX Design
6. Role & Permission Matrix
7. Approval Matrix
8. Accounting Chart of Accounts
9. Inventory Costing Rules
10. API Specification
11. Database Design
12. Test Cases
13. UAT Scenarios
14. User Manual
15. Deployment Guide
16. Backup & DR Procedure
17. Security & Audit Specification
18. Report Catalogue

---

# 79. Recommended Next Step

Before development starts, the client's most important workshop should resolve these questions:

1. Is the lump-sum inventory value intended to represent **actual cost**, **management valuation**, or **selling/expected value**?
2. Should customs/freight/clearing costs increase inventory cost or remain expenses?
3. Which inventory costing method should be used for COGS?
4. Can one sale contain items from multiple containers?
5. Can users manually select the source container during sale?
6. Can stock be transferred between warehouses?
7. Can stock be sold below cost?
8. What happens when a customer returns an item?
9. Are sales tax and withholding taxes applicable?
10. What accounting system/ledger structure does the company currently use?
11. Is the system expected to produce formal financial statements?
12. What are the required approval levels?
13. What information is required on printed invoices?
14. What exact fields are available from customs/shipping documents?
15. How will opening stock and historical containers be migrated?

These decisions directly affect the database, inventory costing engine, accounting design, and gross profit calculation.
