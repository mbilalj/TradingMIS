-- Portside Container Trading System - demo seed data (mirrors the design prototype)

-- Chart of accounts
INSERT INTO chart_of_account (code, name, type) VALUES ('1100', 'Bank — Meezan current', 'ASSET');
INSERT INTO chart_of_account (code, name, type) VALUES ('1200', 'Trade receivables', 'ASSET');
INSERT INTO chart_of_account (code, name, type) VALUES ('1300', 'Inventory — container lots', 'ASSET');
INSERT INTO chart_of_account (code, name, type) VALUES ('1310', 'Goods in transit', 'ASSET');
INSERT INTO chart_of_account (code, name, type) VALUES ('1400', 'Sales tax input (import)', 'ASSET');
INSERT INTO chart_of_account (code, name, type) VALUES ('2100', 'Trade payables — suppliers', 'LIABILITY');
INSERT INTO chart_of_account (code, name, type) VALUES ('2200', 'Sales tax output', 'LIABILITY');
INSERT INTO chart_of_account (code, name, type) VALUES ('3100', 'Owner capital & retained', 'EQUITY');
INSERT INTO chart_of_account (code, name, type) VALUES ('4100', 'Sales revenue', 'REVENUE');
INSERT INTO chart_of_account (code, name, type) VALUES ('5100', 'Cost of goods sold', 'EXPENSE');
INSERT INTO chart_of_account (code, name, type) VALUES ('5200', 'Import & clearing expenses', 'EXPENSE');
INSERT INTO chart_of_account (code, name, type) VALUES ('6100', 'Operating expenses', 'EXPENSE');

-- App settings
INSERT INTO app_setting (setting_key, setting_value) VALUES ('usdRate', '296.5');
INSERT INTO app_setting (setting_key, setting_value) VALUES ('taxRatePct', '18');

-- Items
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('HW-1001', 'Ball bearing 6204-2RS', 'pcs', 'Hardware', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('HW-1002', 'Hex bolt M12 x 80, box 100', 'box', 'Hardware', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('HW-1010', 'Angle grinder 850W', 'pcs', 'Power tools', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('EL-2003', 'Copper cable 2.5mm, roll 100m', 'roll', 'Electrical', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('EL-2007', 'LED panel light 36W', 'pcs', 'Electrical', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('PL-3001', 'PPRC elbow 32mm, box 50', 'box', 'Plumbing', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('PL-3004', 'Gate valve 2in brass', 'pcs', 'Plumbing', 400);
INSERT INTO item (code, name, uom, category, reorder_level) VALUES ('TL-4002', 'Impact drill 13mm', 'pcs', 'Power tools', 400);

-- Suppliers
INSERT INTO supplier (code, name, origin_port, payment_terms) VALUES ('SUP-01', 'HTM Tools Co. Ltd', 'Guangzhou, CN', 'LC 60 days');
INSERT INTO supplier (code, name, origin_port, payment_terms) VALUES ('SUP-02', 'Sunrise Hardware Ind.', 'Ningbo, CN', 'TT 30% advance');
INSERT INTO supplier (code, name, origin_port, payment_terms) VALUES ('SUP-03', 'Jinhe Fittings Group', 'Qingdao, CN', 'LC at sight');
INSERT INTO supplier (code, name, origin_port, payment_terms) VALUES ('SUP-04', 'Yuhua Electricals', 'Shanghai, CN', 'LC 90 days');

-- Customers
INSERT INTO customer (code, name, city, payment_terms, credit_limit, standing_discount_pct, salesman) VALUES ('C-01', 'Al-Madina Hardware', 'Karachi', '30 days', 4000000, 0, 'Imran Qadri');
INSERT INTO customer (code, name, city, payment_terms, credit_limit, standing_discount_pct, salesman) VALUES ('C-02', 'Sindh Electric Traders', 'Hyderabad', '45 days', 2500000, 2.5, 'Imran Qadri');
INSERT INTO customer (code, name, city, payment_terms, credit_limit, standing_discount_pct, salesman) VALUES ('C-03', 'Gulf Tools & Machinery', 'Lahore', 'Cash', 1500000, 5, 'Naveed Alam');
INSERT INTO customer (code, name, city, payment_terms, credit_limit, standing_discount_pct, salesman) VALUES ('C-04', 'Pak Plumbing Mart', 'Karachi', '30 days', 1000000, 0, 'Naveed Alam');
INSERT INTO customer (code, name, city, payment_terms, credit_limit, standing_discount_pct, salesman) VALUES ('C-05', 'Continental Traders', 'Faisalabad', '60 days', 3000000, 3, 'Imran Qadri');

-- Price list (seeded from average landed cost across lots, matching the prototype's priceRec() default)
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='HW-1001'), 1135, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='HW-1002'), 4225, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='HW-1010'), 13015, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='EL-2003'), 16830, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='EL-2007'), 3150, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='PL-3001'), 4705, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='PL-3004'), 6525, 8, 2.5, 5, 3);
INSERT INTO price_list_entry (item_id, list_price, floor_markup_pct, tier_b_pct, tier_c_pct, tier_d_pct) VALUES ((SELECT id FROM item WHERE code='TL-4002'), 13835, 8, 2.5, 5, 3);

-- Containers
INSERT INTO container (code, container_no, supplier_id, bl_number, gd_number, size, eta, received_date, status, current_basis) VALUES ('PSC-2601', 'MSKU-4471820', (SELECT id FROM supplier WHERE code='SUP-01'), 'BL-HKG-77412', 'KAPW-HC-118420', '40'' HC', '2026-07-10', '2026-07-12', 'SELLING', 'VALUE');
INSERT INTO container (code, container_no, supplier_id, bl_number, gd_number, size, eta, received_date, status, current_basis) VALUES ('PSC-2602', 'TGHU-9013355', (SELECT id FROM supplier WHERE code='SUP-02'), 'BL-NGB-30188', 'KAPW-HC-121004', '40'' HC', '2026-07-30', '2026-08-02', 'SELLING', 'VALUE');
INSERT INTO container (code, container_no, supplier_id, bl_number, gd_number, size, eta, received_date, status, current_basis) VALUES ('PSC-2603', 'CSNU-6628104', (SELECT id FROM supplier WHERE code='SUP-03'), 'BL-TAO-55290', 'KAPW-HC-124771', '20'' GP', '2026-08-26', '2026-08-28', 'SELLING', 'VALUE');
INSERT INTO container (code, container_no, supplier_id, bl_number, gd_number, size, eta, received_date, status, current_basis) VALUES ('PSC-2604', 'OOLU-2277431', (SELECT id FROM supplier WHERE code='SUP-04'), 'BL-SHA-91002', NULL, '40'' HC', '2026-09-09', NULL, 'IN_CLEARANCE', 'VALUE');
INSERT INTO container (code, container_no, supplier_id, bl_number, gd_number, size, eta, received_date, status, current_basis) VALUES ('PSC-2605', 'MSKU-7710269', (SELECT id FROM supplier WHERE code='SUP-02'), 'BL-NGB-31644', NULL, '40'' HC', '2026-09-22', NULL, 'IN_TRANSIT', 'VALUE');

-- Container lines
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), (SELECT id FROM item WHERE code='HW-1001'), 4800, 1.95, 4200);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), (SELECT id FROM item WHERE code='HW-1002'), 900, 7.4, 6300);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), (SELECT id FROM item WHERE code='TL-4002'), 420, 21.5, 3200);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), (SELECT id FROM item WHERE code='EL-2003'), 1250, 33, 12500);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), (SELECT id FROM item WHERE code='EL-2007'), 2600, 6.1, 3900);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), (SELECT id FROM item WHERE code='HW-1010'), 560, 26, 4500);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), (SELECT id FROM item WHERE code='PL-3001'), 1800, 9.2, 5400);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), (SELECT id FROM item WHERE code='PL-3004'), 1400, 12.8, 7000);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2604'), (SELECT id FROM item WHERE code='EL-2007'), 3200, 6.05, 4800);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2604'), (SELECT id FROM item WHERE code='EL-2003'), 700, 32.4, 7000);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2605'), (SELECT id FROM item WHERE code='HW-1001'), 5200, 2.02, 4550);
INSERT INTO container_line (container_id, item_id, qty, fob_unit_price_usd, weight_kg) VALUES ((SELECT id FROM container WHERE code='PSC-2605'), (SELECT id FROM item WHERE code='HW-1002'), 1100, 7.55, 7700);

-- Container costs
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Ocean freight', 1185000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Marine insurance', 214000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Customs duty 20%', 2394000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Port & terminal (KPT)', 386000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Clearing agent', 175000, 'QUANTITY');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Inland transport', 248000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2601'), 'Bank & LC charges', 142000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Ocean freight', 1310000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Marine insurance', 268000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Customs duty 20%', 3012000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Port & terminal (KPT)', 402000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Clearing agent', 180000, 'QUANTITY');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Inland transport', 262000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2602'), 'Bank & LC charges', 161000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Ocean freight', 690000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Marine insurance', 118000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Customs duty 20%', 1485000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Port & terminal (KPT)', 240000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Clearing agent', 150000, 'QUANTITY');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Inland transport', 146000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2603'), 'Bank & LC charges', 88000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2604'), 'Ocean freight', 1272000, 'OVERALL');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2604'), 'Marine insurance', 231000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2604'), 'Customs duty 20%', 2640000, 'VALUE');
INSERT INTO container_cost (container_id, expense_head, amount_pkr, basis) VALUES ((SELECT id FROM container WHERE code='PSC-2605'), 'Ocean freight', 1240000, 'OVERALL');

-- Purchase orders
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2601', (SELECT id FROM supplier WHERE code='SUP-01'), '2026-06-02', 'FOB Guangzhou', 'LC 60 days', 'RECEIVED', (SELECT id FROM container WHERE code='PSC-2601'));
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2602', (SELECT id FROM supplier WHERE code='SUP-02'), '2026-06-21', 'FOB Ningbo', 'TT 30% advance', 'RECEIVED', (SELECT id FROM container WHERE code='PSC-2602'));
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2603', (SELECT id FROM supplier WHERE code='SUP-03'), '2026-07-14', 'FOB Qingdao', 'LC at sight', 'RECEIVED', (SELECT id FROM container WHERE code='PSC-2603'));
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2604', (SELECT id FROM supplier WHERE code='SUP-04'), '2026-08-08', 'FOB Shanghai', 'LC 90 days', 'SHIPPED', (SELECT id FROM container WHERE code='PSC-2604'));
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2605', (SELECT id FROM supplier WHERE code='SUP-02'), '2026-08-26', 'FOB Ningbo', 'TT 30% advance', 'SHIPPED', (SELECT id FROM container WHERE code='PSC-2605'));
INSERT INTO purchase_order (code, supplier_id, order_date, incoterm, payment_terms, status, container_id) VALUES ('PO-2606', (SELECT id FROM supplier WHERE code='SUP-01'), '2026-09-11', 'FOB Guangzhou', 'LC 60 days', 'ORDERED', NULL);

-- Purchase order lines
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2601'), (SELECT id FROM item WHERE code='HW-1001'), 4800, 1.95);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2601'), (SELECT id FROM item WHERE code='HW-1002'), 900, 7.4);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2601'), (SELECT id FROM item WHERE code='TL-4002'), 420, 21.5);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2602'), (SELECT id FROM item WHERE code='EL-2003'), 1250, 33);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2602'), (SELECT id FROM item WHERE code='EL-2007'), 2600, 6.1);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2602'), (SELECT id FROM item WHERE code='HW-1010'), 560, 26);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2603'), (SELECT id FROM item WHERE code='PL-3001'), 1800, 9.2);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2603'), (SELECT id FROM item WHERE code='PL-3004'), 1400, 12.8);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2604'), (SELECT id FROM item WHERE code='EL-2007'), 3200, 6.05);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2604'), (SELECT id FROM item WHERE code='EL-2003'), 700, 32.4);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2605'), (SELECT id FROM item WHERE code='HW-1001'), 5200, 2.02);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2605'), (SELECT id FROM item WHERE code='HW-1002'), 1100, 7.55);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2606'), (SELECT id FROM item WHERE code='TL-4002'), 600, 21.9);
INSERT INTO purchase_order_line (purchase_order_id, item_id, qty, fob_unit_price_usd) VALUES ((SELECT id FROM purchase_order WHERE code='PO-2606'), (SELECT id FROM item WHERE code='HW-1010'), 400, 25.6);

-- Sales invoices (posted)
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0031', '2026-08-05', (SELECT id FROM customer WHERE code='C-01'), 'POSTED', 'seed');
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0032', '2026-08-12', (SELECT id FROM customer WHERE code='C-02'), 'POSTED', 'seed');
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0033', '2026-08-20', (SELECT id FROM customer WHERE code='C-03'), 'POSTED', 'seed');
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0034', '2026-08-29', (SELECT id FROM customer WHERE code='C-01'), 'POSTED', 'seed');
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0035', '2026-09-03', (SELECT id FROM customer WHERE code='C-04'), 'POSTED', 'seed');
INSERT INTO sales_invoice (code, `date`, customer_id, status, created_by) VALUES ('INV-0036', '2026-09-09', (SELECT id FROM customer WHERE code='C-02'), 'POSTED', 'seed');

-- Sales invoice lines
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0031'), (SELECT id FROM item WHERE code='HW-1001'), (SELECT id FROM container WHERE code='PSC-2601'), 1400, 1010, 962.4404);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0031'), (SELECT id FROM item WHERE code='TL-4002'), (SELECT id FROM container WHERE code='PSC-2601'), 90, 10650, 10324.8418);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0032'), (SELECT id FROM item WHERE code='HW-1002'), (SELECT id FROM container WHERE code='PSC-2601'), 260, 3720, 3572.4193);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0033'), (SELECT id FROM item WHERE code='EL-2007'), (SELECT id FROM container WHERE code='PSC-2602'), 640, 3180, 2310.3495);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0033'), (SELECT id FROM item WHERE code='HW-1010'), (SELECT id FROM container WHERE code='PSC-2602'), 120, 13400, 9714.2366);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0034'), (SELECT id FROM item WHERE code='EL-2003'), (SELECT id FROM container WHERE code='PSC-2602'), 210, 15900, 12318.619);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0034'), (SELECT id FROM item WHERE code='HW-1001'), (SELECT id FROM container WHERE code='PSC-2601'), 900, 1040, 962.4404);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0035'), (SELECT id FROM item WHERE code='PL-3001'), (SELECT id FROM container WHERE code='PSC-2603'), 520, 4380, 3512.9697);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0035'), (SELECT id FROM item WHERE code='PL-3004'), (SELECT id FROM container WHERE code='PSC-2603'), 300, 5950, 4869.2676);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0036'), (SELECT id FROM item WHERE code='EL-2007'), (SELECT id FROM container WHERE code='PSC-2602'), 480, 3120, 2310.3495);
INSERT INTO sales_invoice_line (invoice_id, item_id, container_id, qty, rate_pkr, unit_cost_snapshot) VALUES ((SELECT id FROM sales_invoice WHERE code='INV-0036'), (SELECT id FROM item WHERE code='EL-2003'), (SELECT id FROM container WHERE code='PSC-2602'), 95, 16200, 12318.619);

-- Receipts
INSERT INTO receipt (code, `date`, customer_id, amount_pkr, mode) VALUES ('RV-0021', '2026-08-18', (SELECT id FROM customer WHERE code='C-01'), 1600000, 'Cheque — Meezan 0431');
INSERT INTO receipt (code, `date`, customer_id, amount_pkr, mode) VALUES ('RV-0022', '2026-08-27', (SELECT id FROM customer WHERE code='C-03'), 3600000, 'Bank transfer — HBL');
INSERT INTO receipt (code, `date`, customer_id, amount_pkr, mode) VALUES ('RV-0023', '2026-09-01', (SELECT id FROM customer WHERE code='C-02'), 900000, 'Cheque — UBL 7742');
INSERT INTO receipt (code, `date`, customer_id, amount_pkr, mode) VALUES ('RV-0024', '2026-09-10', (SELECT id FROM customer WHERE code='C-01'), 2200000, 'Bank transfer — Meezan');

-- Receipt allocations: apply each receipt oldest-invoice-first against that customer's posted invoices
INSERT INTO receipt_allocation (receipt_id, invoice_id, amount_applied) VALUES ((SELECT id FROM receipt WHERE code='RV-0021'), (SELECT id FROM sales_invoice WHERE code='INV-0031'), 1600000);
INSERT INTO receipt_allocation (receipt_id, invoice_id, amount_applied) VALUES ((SELECT id FROM receipt WHERE code='RV-0022'), (SELECT id FROM sales_invoice WHERE code='INV-0033'), 3600000);
INSERT INTO receipt_allocation (receipt_id, invoice_id, amount_applied) VALUES ((SELECT id FROM receipt WHERE code='RV-0023'), (SELECT id FROM sales_invoice WHERE code='INV-0032'), 900000);
INSERT INTO receipt_allocation (receipt_id, invoice_id, amount_applied) VALUES ((SELECT id FROM receipt WHERE code='RV-0024'), (SELECT id FROM sales_invoice WHERE code='INV-0031'), 1199550);
INSERT INTO receipt_allocation (receipt_id, invoice_id, amount_applied) VALUES ((SELECT id FROM receipt WHERE code='RV-0024'), (SELECT id FROM sales_invoice WHERE code='INV-0034'), 1000450);
