package com.portside.trading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.service.*;
import com.portside.trading.web.dto.ReportResult;
import com.portside.trading.web.dto.Req.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

/** Receive stock at two costs -> sell (FIFO/batch cost) -> expenses vs non-operating -> return -> receipt -> books balance. */
@SpringBootTest
class BusinessFlowIntegrationTest {

    @Autowired MasterDataService master;
    @Autowired ShipmentService shipments;
    @Autowired SaleService sales;
    @Autowired SaleReturnService returns;
    @Autowired PaymentService payments;
    @Autowired ExpenseService expenses;
    @Autowired StockAdjustmentService adjustments;
    @Autowired CashService cash;
    @Autowired ReportService reports;
    @Autowired LedgerService ledger;
    @Autowired StockService stock;
    @Autowired AccountingService accounting;
    @Autowired UnitRepo unitRepo;
    @Autowired AccountRepo accountRepo;
    @Autowired ExpenseCategoryRepo categoryRepo;
    @Autowired CustomerRepo customerRepo;
    @Autowired BatchRepo batchRepo;

    private static BigDecimal bd(String s) { return new BigDecimal(s); }

    private static BigDecimal amount(ReportResult r, String line) {
        return r.rows().stream().filter(x -> line.equals(String.valueOf(x.get("line")).trim())).map(x -> (BigDecimal) x.get("amount"))
                .findFirst().orElseThrow(() -> new AssertionError("no P&L line " + line));
    }

    @Test
    void fullPostArrivalCycle() {
        Unit piece = unitRepo.findByNameIgnoreCase("Piece").orElseThrow();
        Unit carton = unitRepo.findByNameIgnoreCase("Carton").orElseThrow();
        Product p = master.saveProduct(null, new ProductReq("PA-1", "Product A", "General", "Acme", null, piece.getId(),
                bd("650"), bd("640"), bd("650"), bd("5"), true, List.of(new UnitConv(carton.getId(), bd("200")))));
        Supplier sup = new Supplier();
        sup.setName("Shenzhen Traders");
        sup.setCountry("China");
        sup = master.saveSupplier(null, sup);

        // Same product, two shipments, two costs. Shipment 001 is owed to the supplier in full.
        Shipment s1 = shipments.create(new ShipmentReq("SHP-001", "MSKU1000001", LocalDate.now().minusDays(20), sup.getId(), null, null, bd("5000"),
                List.of(new ShipmentLineReq(p.getId(), null, piece.getId(), bd("10"), bd("500")))));
        shipments.create(new ShipmentReq("SHP-002", "MSKU1000002", LocalDate.now().minusDays(10), sup.getId(), null, null, BigDecimal.ZERO,
                List.of(new ShipmentLineReq(p.getId(), null, carton.getId(), bd("1"), bd("110000")))));
        assertThat(stock.onHandForProduct(p.getId())).isEqualByComparingTo("210");
        assertThat(batchRepo.findByProductIdOrderByShipmentArrivalDateAscIdAsc(p.getId()).get(1).getUnitCost()).isEqualByComparingTo("550");
        assertThat(ledger.supplierBalance(sup.getId())).isEqualByComparingTo("5000");

        // Customer, credit limit, one wholesale sale that spills from batch 1 into batch 2 (10 @500 + 5 @550).
        Customer cust = new Customer();
        cust.setName("Al-Noor Stores");
        cust.setType(SaleType.WHOLESALE);
        cust.setCreditLimit(bd("20000"));
        cust.setOpeningBalance(bd("1000"));
        cust = master.saveCustomer(null, cust);
        Sale sale = sales.create(new SaleReq(LocalDate.now(), SaleType.WHOLESALE, cust.getId(), "CASH", null, bd("2000"), null, false,
                List.of(new SaleLineReq(p.getId(), null, piece.getId(), bd("15"), bd("650"), bd("150"), BigDecimal.ZERO))));
        assertThat(sale.getLines()).hasSize(2);
        assertThat(sale.getTotal()).isEqualByComparingTo("9600"); // 15*650 - 150
        assertThat(sale.getCogsTotal()).isEqualByComparingTo("7750"); // 10*500 + 5*550
        assertThat(sale.profit()).isEqualByComparingTo("1850");
        assertThat(ledger.customerBalance(cust.getId())).isEqualByComparingTo("8600"); // 1000 opening + 9600 - 2000
        assertThatThrownBy(() -> sales.create(new SaleReq(LocalDate.now(), SaleType.WHOLESALE, customerRepo.findAll().stream().filter(c -> c.getName().startsWith("Al")).findFirst().get().getId(),
                "CASH", null, BigDecimal.ZERO, null, false,
                List.of(new SaleLineReq(p.getId(), null, piece.getId(), bd("100"), bd("650"), null, null)))))
                .hasMessageContaining("Credit limit");

        // Retail walk-in sale paid in full; selling 300 pieces must fail (only 195 left).
        Customer walkIn = customerRepo.findFirstByWalkInTrue().orElseThrow();
        assertThatThrownBy(() -> sales.create(new SaleReq(null, SaleType.RETAIL, walkIn.getId(), "CASH", null, null, null, null,
                List.of(new SaleLineReq(p.getId(), null, piece.getId(), bd("300"), null, null, null))))).hasMessageContaining("Insufficient stock");
        Sale retail = sales.create(new SaleReq(null, SaleType.RETAIL, null, "CASH", null, null, null, null,
                List.of(new SaleLineReq(p.getId(), null, piece.getId(), bd("2"), null, null, null))));
        assertThat(retail.getTotal()).isEqualByComparingTo("1300");
        assertThat(retail.getPaidAmount()).isEqualByComparingTo("1300");

        // Damaged stock reduces stock and profit through the books.
        Batch b2 = batchRepo.findByProductIdOrderByShipmentArrivalDateAscIdAsc(p.getId()).get(1);
        adjustments.adjust(new StockAdjReq(LocalDate.now(), b2.getId(), MovementType.DAMAGED, false, null, bd("3"), "Water damage"));
        assertThat(stock.onHandForProduct(p.getId())).isEqualByComparingTo("190");

        // Operating expense hits profit; customs duty (non-operating) only moves the bank.
        CashAccount bank = accountRepo.findAll().stream().filter(a -> a.getType() == AccountType.BANK).findFirst().orElseThrow();
        ExpenseCategory elec = categoryRepo.findAll().stream().filter(c -> c.getName().equals("Electricity")).findFirst().orElseThrow();
        ExpenseCategory duty = categoryRepo.findAll().stream().filter(c -> c.getName().equals("Customs duty")).findFirst().orElseThrow();
        expenses.create(new ExpenseReq(LocalDate.now(), ExpenseNature.OPERATING, elec.getId(), bd("300"), bank.getId(), "BANK_TRANSFER", null, "Bill"));
        expenses.create(new ExpenseReq(LocalDate.now(), ExpenseNature.NON_OPERATING, duty.getId(), bd("40000"), bank.getId(), "BANK_TRANSFER", s1.getId(), "Container duty"));
        assertThat(accounting.balance(bank.getHeadCode(), null)).isEqualByComparingTo("-40300");

        // Return 2 pieces from the batch-2 line of the wholesale sale; they go back to batch 2 at its original cost.
        SaleLine batch2Line = sale.getLines().get(1);
        SaleReturn ret = returns.create(new ReturnReq(sale.getId(), LocalDate.now(), "Faulty", BigDecimal.ZERO, null,
                List.of(new ReturnLineReq(batch2Line.getId(), bd("2")))));
        assertThat(ret.getTotal()).isEqualByComparingTo("1280"); // 2 * 650 less proportional 150 discount share
        assertThat(stock.onHand(b2.getId())).isEqualByComparingTo("192"); // 200 received - 5 - 2 sold - 3 damaged + 2 returned

        // Customer pays 3000 later: settles the oldest unpaid invoice first.
        payments.receivePayment(new ReceiptReq(cust.getId(), LocalDate.now(), bd("3000"), "BANK_TRANSFER", bank.getId(), "CHQ-1", null));
        BigDecimal balance = ledger.customerBalance(cust.getId());
        assertThat(balance).isEqualByComparingTo("4320"); // 8600 - 1280 - 3000

        // Reports: P&L excludes the customs duty; trial balance balances; balance sheet balances.
        LocalDate from = LocalDate.now().minusDays(30), to = LocalDate.now();
        ReportResult pl = reports.run("profit-loss", new ReportService.Params(from, to, null, null, null));
        assertThat(amount(pl, "Total operating expenses")).isEqualByComparingTo("-300");
        assertThat(amount(pl, "Memo: non-operating / shipment payments (excluded from profit, paid from cash/bank)")).isEqualByComparingTo("40000");
        ReportResult tb = reports.run("trial-balance", new ReportService.Params(null, to, null, null, null));
        assertThat((BigDecimal) tb.totals().get("debit")).isEqualByComparingTo((BigDecimal) tb.totals().get("credit"));
        ReportResult bs = reports.run("balance-sheet", new ReportService.Params(null, to, null, null, null));
        assertThat((BigDecimal) bs.totals().get("assets")).isEqualByComparingTo((BigDecimal) bs.totals().get("liabilities_equity"));

        // Every report must at least execute against the schema.
        for (String code : List.of("container-wise-sales", "container-product-sales", "daily-sales", "monthly-sales", "customer-wise-sales", "product-wise-sales", "gross-profit",
                "wholesale-sales", "retail-sales", "sales-by-invoice", "sales-by-range", "sales-returns", "current-stock", "stock-valuation",
                "low-stock", "product-wise-stock", "batch-wise-stock", "stock-received", "stock-sold", "stock-adjustments", "damaged-stock",
                "stock-movement", "customer-balances", "receivables", "overdue", "customer-payment-history", "payables",
                "supplier-transactions", "supplier-payment-history", "net-profit", "expense-report", "cash-book", "bank-book", "cash-flow")) {
            assertThat(reports.run(code, new ReportService.Params(from, to, null, null, null)).columns()).as(code).isNotEmpty();
        }
        assertThat(reports.run("customer-ledger", new ReportService.Params(from, to, cust.getId(), null, null)).rows()).hasSizeGreaterThan(3);
        assertThat(reports.run("supplier-ledger", new ReportService.Params(from, to, sup.getId(), null, null)).rows()).isNotEmpty();
    }
}
