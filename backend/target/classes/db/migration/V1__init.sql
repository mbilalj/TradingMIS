-- Portside Container Trading System - core schema

CREATE TABLE app_user (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  password_hash VARCHAR(100) NOT NULL,
  full_name VARCHAR(128) NOT NULL,
  role VARCHAR(32) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE item (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  uom VARCHAR(16) NOT NULL,
  category VARCHAR(64) NOT NULL,
  reorder_level DOUBLE NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE supplier (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  origin_port VARCHAR(128) NOT NULL,
  payment_terms VARCHAR(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE customer (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  name VARCHAR(200) NOT NULL,
  city VARCHAR(64) NOT NULL,
  payment_terms VARCHAR(32) NOT NULL,
  credit_limit DOUBLE NOT NULL DEFAULT 0,
  standing_discount_pct DOUBLE NOT NULL DEFAULT 0,
  salesman VARCHAR(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE price_list_entry (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  item_id BIGINT NOT NULL UNIQUE,
  list_price DOUBLE NOT NULL,
  floor_markup_pct DOUBLE NOT NULL,
  tier_b_pct DOUBLE NOT NULL,
  tier_c_pct DOUBLE NOT NULL,
  tier_d_pct DOUBLE NOT NULL,
  CONSTRAINT fk_price_item FOREIGN KEY (item_id) REFERENCES item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE container (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  container_no VARCHAR(32) NOT NULL,
  supplier_id BIGINT NOT NULL,
  bl_number VARCHAR(32),
  gd_number VARCHAR(32),
  size VARCHAR(16) NOT NULL,
  eta DATE,
  received_date DATE,
  status VARCHAR(16) NOT NULL,
  current_basis VARCHAR(16) NOT NULL DEFAULT 'VALUE',
  CONSTRAINT fk_container_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE container_line (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  container_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,
  qty DOUBLE NOT NULL,
  fob_unit_price_usd DOUBLE NOT NULL,
  weight_kg DOUBLE NOT NULL,
  CONSTRAINT fk_cline_container FOREIGN KEY (container_id) REFERENCES container(id),
  CONSTRAINT fk_cline_item FOREIGN KEY (item_id) REFERENCES item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE container_cost (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  container_id BIGINT NOT NULL,
  expense_head VARCHAR(128) NOT NULL,
  amount_pkr DOUBLE NOT NULL,
  basis VARCHAR(16) NOT NULL,
  CONSTRAINT fk_ccost_container FOREIGN KEY (container_id) REFERENCES container(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchase_order (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  supplier_id BIGINT NOT NULL,
  order_date DATE NOT NULL,
  incoterm VARCHAR(64) NOT NULL,
  payment_terms VARCHAR(64) NOT NULL,
  status VARCHAR(16) NOT NULL,
  container_id BIGINT,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES supplier(id),
  CONSTRAINT fk_po_container FOREIGN KEY (container_id) REFERENCES container(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE purchase_order_line (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,
  qty DOUBLE NOT NULL,
  fob_unit_price_usd DOUBLE NOT NULL,
  CONSTRAINT fk_poline_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_order(id),
  CONSTRAINT fk_poline_item FOREIGN KEY (item_id) REFERENCES item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock_entry (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  `date` DATE NOT NULL,
  type VARCHAR(24) NOT NULL,
  posted_by VARCHAR(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE stock_entry_line (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  stock_entry_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,
  container_id BIGINT NOT NULL,
  signed_qty DOUBLE NOT NULL,
  reason VARCHAR(255),
  unit_cost_snapshot DOUBLE NOT NULL,
  CONSTRAINT fk_seline_entry FOREIGN KEY (stock_entry_id) REFERENCES stock_entry(id),
  CONSTRAINT fk_seline_item FOREIGN KEY (item_id) REFERENCES item(id),
  CONSTRAINT fk_seline_container FOREIGN KEY (container_id) REFERENCES container(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sales_invoice (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  `date` DATE NOT NULL,
  customer_id BIGINT NOT NULL,
  status VARCHAR(24) NOT NULL,
  created_by VARCHAR(128),
  CONSTRAINT fk_inv_customer FOREIGN KEY (customer_id) REFERENCES customer(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE sales_invoice_line (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT NOT NULL,
  item_id BIGINT NOT NULL,
  container_id BIGINT NOT NULL,
  qty DOUBLE NOT NULL,
  rate_pkr DOUBLE NOT NULL,
  unit_cost_snapshot DOUBLE NOT NULL,
  CONSTRAINT fk_invline_invoice FOREIGN KEY (invoice_id) REFERENCES sales_invoice(id),
  CONSTRAINT fk_invline_item FOREIGN KEY (item_id) REFERENCES item(id),
  CONSTRAINT fk_invline_container FOREIGN KEY (container_id) REFERENCES container(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE receipt (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,
  `date` DATE NOT NULL,
  customer_id BIGINT NOT NULL,
  amount_pkr DOUBLE NOT NULL,
  mode VARCHAR(64) NOT NULL,
  CONSTRAINT fk_receipt_customer FOREIGN KEY (customer_id) REFERENCES customer(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE receipt_allocation (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  receipt_id BIGINT NOT NULL,
  invoice_id BIGINT NOT NULL,
  amount_applied DOUBLE NOT NULL,
  CONSTRAINT fk_ralloc_receipt FOREIGN KEY (receipt_id) REFERENCES receipt(id),
  CONSTRAINT fk_ralloc_invoice FOREIGN KEY (invoice_id) REFERENCES sales_invoice(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chart_of_account (
  code VARCHAR(16) PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  type VARCHAR(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE journal_entry (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  voucher_no VARCHAR(32) NOT NULL UNIQUE,
  `date` DATE NOT NULL,
  narration VARCHAR(255) NOT NULL,
  source_type VARCHAR(32) NOT NULL,
  source_code VARCHAR(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE journal_line (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  journal_entry_id BIGINT NOT NULL,
  account_code VARCHAR(16) NOT NULL,
  debit DOUBLE NOT NULL DEFAULT 0,
  credit DOUBLE NOT NULL DEFAULT 0,
  CONSTRAINT fk_jline_entry FOREIGN KEY (journal_entry_id) REFERENCES journal_entry(id),
  CONSTRAINT fk_jline_account FOREIGN KEY (account_code) REFERENCES chart_of_account(code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE app_setting (
  setting_key VARCHAR(64) PRIMARY KEY,
  setting_value VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
