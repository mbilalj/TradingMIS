package com.portside.trading.config;

import com.portside.trading.domain.*;
import com.portside.trading.repo.Repos.*;
import com.portside.trading.service.*;
import com.portside.trading.web.dto.Req.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * One-time demo data for a Lahore importer: suppliers in six countries, a product catalogue, eight containers received
 * over the last four months (every product line is a container batch), Lahore customers, and sales / receipts /
 * returns / expenses / vouchers booked through the normal services so every ledger and report has real figures.
 * Runs once (marker setting), after {@link SeedService}. Disable with {@code portside.sample-data.enabled=false}.
 */
@Component
@Order(10)
@ConditionalOnProperty(name = "portside.sample-data.enabled", havingValue = "true", matchIfMissing = true)
public class SampleDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(SampleDataSeeder.class);
    private static final String MARKER = "sample.data.v1";

    private final SettingsService settings;
    private final MasterDataService master;
    private final ShipmentService shipments;
    private final SaleService sales;
    private final SaleReturnService returns;
    private final PaymentService payments;
    private final ExpenseService expenses;
    private final StockAdjustmentService adjustments;
    private final CashService cash;
    private final StockService stock;
    private final LedgerService ledger;
    private final UnitRepo unitRepo;
    private final ProductRepo productRepo;
    private final SupplierRepo supplierRepo;
    private final CustomerRepo customerRepo;
    private final ShipmentRepo shipmentRepo;
    private final AccountRepo accountRepo;
    private final ExpenseCategoryRepo categoryRepo;
    private final SaleRepo saleRepo;
    private final BatchRepo batchRepo;

    public SampleDataSeeder(SettingsService settings, MasterDataService master, ShipmentService shipments, SaleService sales,
                            SaleReturnService returns, PaymentService payments, ExpenseService expenses,
                            StockAdjustmentService adjustments, CashService cash, StockService stock, LedgerService ledger, UnitRepo unitRepo,
                            ProductRepo productRepo, SupplierRepo supplierRepo, CustomerRepo customerRepo, ShipmentRepo shipmentRepo,
                            AccountRepo accountRepo, ExpenseCategoryRepo categoryRepo, SaleRepo saleRepo, BatchRepo batchRepo) {
        this.settings = settings;
        this.master = master;
        this.shipments = shipments;
        this.sales = sales;
        this.returns = returns;
        this.payments = payments;
        this.expenses = expenses;
        this.adjustments = adjustments;
        this.cash = cash;
        this.stock = stock;
        this.ledger = ledger;
        this.unitRepo = unitRepo;
        this.productRepo = productRepo;
        this.supplierRepo = supplierRepo;
        this.customerRepo = customerRepo;
        this.shipmentRepo = shipmentRepo;
        this.accountRepo = accountRepo;
        this.categoryRepo = categoryRepo;
        this.saleRepo = saleRepo;
        this.batchRepo = batchRepo;
    }

    /** A dated step; steps are executed oldest first so stock always exists before it is sold. */
    private record Step(LocalDate date, int order, Runnable action) {}

    private final List<Step> timeline = new ArrayList<>();
    private final Random rnd = new Random(2026);
    private LocalDate today;
    private int seq;

    @Override
    public void run(ApplicationArguments args) {
        if (!settings.get(MARKER).isBlank()) return;
        settings.setIfAbsent(MARKER, "seeding");
        today = LocalDate.now();
        try {
            settings.update(Map.of("business.name", "Portside Trading Co.", "business.address", "Shop 14, Azam Cloth Market, Lahore, Pakistan",
                    "business.phone", "042-37654321", "business.email", "accounts@portside.pk", "business.taxNo", "NTN 3520211-4"));
            accounts();
            suppliers();
            products();
            customers();
            planContainers();
            planSales();
            planCollections();
            planExpenses();
            timeline.sort(Comparator.comparing(Step::date).thenComparingInt(Step::order));
            timeline.forEach(s -> s.action().run());
            log.info("Sample data loaded: {} products, {} containers, {} invoices", productRepo.count(), shipmentRepo.count(), saleRepo.count());
        } catch (RuntimeException e) {
            log.warn("Sample data seeding stopped part-way: {}", e.getMessage(), e);
        }
    }

    private LocalDate ago(int days) {
        return today.minusDays(days);
    }

    private void at(LocalDate date, int order, Runnable r) {
        timeline.add(new Step(date, order, r));
    }

    private static BigDecimal bd(double v) {
        return BigDecimal.valueOf(v);
    }

    // ------------------------------------------------------------------ accounts

    private void accounts() {
        if (accountRepo.count() <= 2) {
            cash.saveAccount(null, new AccountReq("HBL Current - Lahore Main Branch", AccountType.BANK, "PK36HABB0000123456702", BigDecimal.ZERO, true));
            cash.saveAccount(null, new AccountReq("Meezan Bank - Gulberg Branch", AccountType.BANK, "PK12MEZN0001230101234567", BigDecimal.ZERO, true));
        }
        CashAccount bank = accountRepo.findAll().stream().filter(a -> a.getType() == AccountType.BANK).findFirst().orElseThrow();
        CashAccount till = accountRepo.findAll().stream().filter(a -> a.getType() == AccountType.CASH).findFirst().orElseThrow();
        at(ago(135), 0, () -> cash.createVoucher(new VoucherReq(ago(135), VoucherKind.RECEIPT, "CAPITAL_INTRODUCED", bank.getId(), null,
                bd(60_000_000), "Owner capital introduced to fund container imports")));
        at(ago(135), 1, () -> cash.createVoucher(new VoucherReq(ago(135), VoucherKind.TRANSFER, null, bank.getId(), till.getId(),
                bd(1_500_000), "Float for the shop till")));
    }

    // ------------------------------------------------------------------ suppliers (one country each)

    private Supplier sup(String code, String name, String country, String contact, String address, double opening) {
        Supplier s = new Supplier();
        s.setCode(code);
        s.setName(name);
        s.setCountry(country);
        s.setContact(contact);
        s.setAddress(address);
        s.setOpeningBalance(bd(opening));
        s.setActive(true);
        return supplierRepo.findByCode(code).orElseGet(() -> master.saveSupplier(null, s));
    }

    private void suppliers() {
        sup("SUP-SZ", "Shenzhen Brightway Electronics Co., Ltd", "China", "Mr. Kevin Zhao - +86 755 8266 1180", "Bao'an District, Shenzhen (via Yantian port)", 0);
        sup("SUP-GZ", "Guangzhou Greenfield Houseware Trading", "China", "Ms. Linda Chen - +86 20 8765 4421", "Baiyun District, Guangzhou (via Nansha port)", 0);
        sup("SUP-DXB", "Al Safa General Trading LLC", "UAE", "Mr. Yousuf Al Mansoori - +971 4 881 2290", "Deira, Dubai (via Jebel Ali)", 0);
        sup("SUP-IST", "Bosphorus Home Textiles A.S.", "Turkey", "Mr. Emre Kaya - +90 212 555 0143", "Bursa / Istanbul (via Mersin port)", 0);
        sup("SUP-BKK", "Siam Living Products Co., Ltd", "Thailand", "Khun Somchai - +66 2 123 4567", "Samut Prakan, Bangkok (via Laem Chabang)", 0);
        sup("SUP-KUL", "Pinnacle Oleo & Home Care Sdn Bhd", "Malaysia", "Mr. Tan Wei Ming - +60 3 3341 7788", "Port Klang, Selangor", 0);
    }

    // ------------------------------------------------------------------ products

    private Unit unit(String name) {
        return unitRepo.findByNameIgnoreCase(name).orElseThrow();
    }

    /** Prices are per base unit; [conversions] are "unit:factor" pairs. */
    private void prod(String sku, String name, String category, String brand, String base, double retail, double wholesale, double minStock, String... conversions) {
        if (productRepo.findBySku(sku).isPresent()) return;
        List<UnitConv> units = new ArrayList<>();
        for (String c : conversions) {
            String[] p = c.split(":");
            units.add(new UnitConv(unit(p[0]).getId(), new BigDecimal(p[1])));
        }
        master.saveProduct(null, new ProductReq(sku, name, category, brand, null, unit(base).getId(), bd(retail), bd(wholesale), bd(retail), bd(minStock), true, units));
    }

    private void products() {
        prod("ELE-LED12", "LED Bulb 12W Daylight E27", "Electronics", "Brightway", "Piece", 290, 245, 600, "Carton:100", "Box:10");
        prod("ELE-USBC1", "USB-C Fast Charging Cable 1m", "Electronics", "Brightway", "Piece", 450, 360, 500, "Box:50", "Carton:200");
        prod("ELE-PWB10", "Power Bank 10000mAh Dual USB", "Electronics", "Voltix", "Piece", 3200, 2650, 100, "Carton:20");
        prod("ELE-BTSPK", "Bluetooth Speaker Portable", "Electronics", "Voltix", "Piece", 2800, 2300, 60, "Carton:24");
        prod("HOM-STOR30", "Plastic Storage Box 30L with Lid", "Houseware", "KeepWell", "Piece", 1150, 920, 80, "Carton:12");
        prod("HOM-BOTL750", "Stainless Steel Water Bottle 750ml", "Houseware", "KeepWell", "Piece", 1350, 1080, 120, "Carton:48");
        prod("HOM-PAN26", "Non-stick Frying Pan 26cm", "Houseware", "ChefMate", "Piece", 2400, 1950, 60, "Carton:12");
        prod("HOM-DIN24", "Ceramic Dinner Set 24 Pieces", "Houseware", "Royal Bone", "Set", 9800, 8300, 20, "Carton:4");
        prod("TEX-TWL70", "Cotton Bath Towel 70x140cm", "Textiles", "Anatolia", "Piece", 1450, 1150, 150, "Dozen:12", "Carton:60");
        prod("TEX-BSET", "Printed Cotton Bed Sheet Set (King)", "Textiles", "Anatolia", "Set", 3900, 3200, 60, "Carton:10");
        prod("FRG-OUD12", "Arabic Oud Attar 12ml", "Fragrance", "Al Safa", "Piece", 1650, 1250, 120, "Dozen:12", "Carton:144");
        prod("FOD-DATE1", "Premium Medjool Dates", "Food", "Al Safa", "Kg", 1850, 1550, 200, "Carton:10");
        prod("HOM-PILLOW", "Natural Latex Pillow", "Houseware", "Siam Dream", "Piece", 4600, 3800, 40, "Carton:8");
        prod("FOD-COCO400", "Coconut Milk 400ml Can", "Food", "Chaokoh", "Piece", 420, 340, 400, "Carton:24");
        prod("FOD-PALM5", "Refined Palm Cooking Oil", "Food", "Golden Palm", "Litre", 520, 455, 500, "Carton:20");
        prod("CLN-DET1", "Laundry Detergent Powder 1kg", "Cleaning", "BrightWash", "Pack", 590, 485, 300, "Carton:12");
    }

    // ------------------------------------------------------------------ customers (all in Lahore)

    private void cust(String code, String name, String phone, String address, SaleType type, double opening, double limit, int days, String notes) {
        if (customerRepo.findByCode(code).isPresent()) return;
        Customer c = new Customer();
        c.setCode(code);
        c.setName(name);
        c.setPhone(phone);
        c.setAddress(address);
        c.setType(type);
        c.setOpeningBalance(bd(opening));
        c.setCreditLimit(bd(limit));
        c.setCreditDays(days);
        c.setNotes(notes);
        c.setActive(true);
        master.saveCustomer(null, c);
    }

    private void customers() {
        cust("CUS-AMT", "Al-Madina Traders", "0300-4412876", "Shop 22, Azam Cloth Market, Lahore", SaleType.WHOLESALE, 85_000, 2_500_000, 30, "Textiles and household buyer; pays on the 1st of every month.");
        cust("CUS-SAE", "Shah Alam Electronics Centre", "0321-4410098", "Shah Alam Market, Lahore", SaleType.WHOLESALE, 0, 3_000_000, 21, "Large electronics reseller.");
        cust("CUS-HMA", "Hafeez Mobile Accessories", "0333-4287761", "Hafeez Centre, Gulberg III, Lahore", SaleType.WHOLESALE, 0, 1_500_000, 14, "Cables, power banks and speakers.");
        cust("CUS-LHS", "Liberty Home Store", "042-35761208", "Liberty Market, Gulberg, Lahore", SaleType.WHOLESALE, 0, 2_000_000, 30, null);
        cust("CUS-RGS", "Rehmat General Store", "0345-4509912", "Lohari Gate, Lahore", SaleType.WHOLESALE, 42_500, 1_000_000, 30, null);
        cust("CUS-BRK", "Brandreth Road Kitchenware", "0300-4398120", "Brandreth Road, Lahore", SaleType.WHOLESALE, 0, 1_800_000, 21, "Steel, non-stick and ceramic ware.");
        cust("CUS-ISM", "Ichhra Super Mart", "0322-4471109", "Ferozepur Road near Ichhra Bazaar, Lahore", SaleType.WHOLESALE, 0, 1_200_000, 30, "Grocery chain, two outlets.");
        cust("CUS-MTG", "Model Town Grocers", "042-35832245", "Link Road, Model Town, Lahore", SaleType.WHOLESALE, 0, 800_000, 15, null);
        cust("CUS-ANA", "Al-Noor Attar House", "0301-4466720", "Chowk Rang Mahal, Walled City, Lahore", SaleType.WHOLESALE, 0, 600_000, 15, "Perfume and dates.");
        cust("CUS-FKW", "Faisal Kitchen Ware", "0314-4452307", "Mozang Chungi, Lahore", SaleType.WHOLESALE, 0, 900_000, 21, null);
        cust("CUS-DCC", "DHA Cash & Carry", "0321-4423319", "Phase 5, DHA, Lahore", SaleType.RETAIL, 0, 400_000, 7, "Walk-in retail with a running account.");
        cust("CUS-JTC", "Johar Town Bedding Centre", "0332-4415566", "Block R1, Johar Town, Lahore", SaleType.WHOLESALE, 0, 1_000_000, 30, null);
    }

    // ------------------------------------------------------------------ containers

    private record Ln(String sku, String unit, double qty, double costPerEnteredUnit) {}

    private void container(int daysAgo, String no, String supplierCode, String containerNo, double payable, String notes, Ln... lines) {
        LocalDate d = ago(daysAgo);
        at(d, 10, () -> {
            if (shipmentRepo.findByShipmentNo(no).isPresent()) return;
            Supplier s = supplierRepo.findByCode(supplierCode).orElseThrow();
            List<ShipmentLineReq> ls = new ArrayList<>();
            for (Ln l : lines) {
                Product p = productRepo.findBySku(l.sku()).orElseThrow();
                ls.add(new ShipmentLineReq(p.getId(), null, unit(l.unit()).getId(), bd(l.qty()), bd(l.costPerEnteredUnit())));
            }
            shipments.create(new ShipmentReq(no, containerNo, d, s.getId(), null, notes, bd(payable), ls));
        });
    }

    private void planContainers() {
        container(120, "IMP-001", "SUP-SZ", "MSKU4417823", 1_800_000, "20ft, Yantian to Karachi (KICT), cleared and trucked to Lahore.",
                new Ln("ELE-LED12", "Carton", 80, 18_500), new Ln("ELE-USBC1", "Carton", 30, 33_000),
                new Ln("ELE-PWB10", "Carton", 12, 52_000), new Ln("ELE-BTSPK", "Carton", 10, 43_000));
        container(105, "IMP-002", "SUP-GZ", "TCLU8830912", 0, "40ft HC, Nansha to Karachi (KPT), cleared and trucked to Lahore.",
                new Ln("HOM-STOR30", "Carton", 90, 9_800), new Ln("HOM-BOTL750", "Carton", 40, 31_000),
                new Ln("HOM-PAN26", "Carton", 50, 17_500), new Ln("HOM-DIN24", "Carton", 25, 52_000));
        container(90, "IMP-003", "SUP-IST", "CMAU2257741", 2_500_000, "40ft, Mersin to Karachi, then Lahore Dry Port.",
                new Ln("TEX-TWL70", "Carton", 70, 55_000), new Ln("TEX-BSET", "Carton", 45, 21_500));
        container(75, "IMP-004", "SUP-BKK", "HLXU6014389", 0, "20ft, Laem Chabang to Karachi, clearing at Port Qasim.",
                new Ln("HOM-PILLOW", "Carton", 30, 24_500), new Ln("FOD-COCO400", "Carton", 160, 4_300));
        container(60, "IMP-005", "SUP-DXB", "OOLU3392760", 900_000, "20ft reefer, Jebel Ali to Karachi, cleared and trucked to Lahore.",
                new Ln("FRG-OUD12", "Carton", 12, 150_000), new Ln("FOD-DATE1", "Carton", 140, 11_800));
        container(45, "IMP-006", "SUP-KUL", "MAEU5568124", 1_200_000, "40ft, Port Klang to Karachi (KICT).",
                new Ln("FOD-PALM5", "Carton", 220, 9_200), new Ln("CLN-DET1", "Carton", 120, 5_500));
        container(25, "IMP-007", "SUP-SZ", "EGHU9027153", 0, "Repeat order, 20ft via Yantian. Slightly higher unit costs than IMP-001.",
                new Ln("ELE-LED12", "Carton", 60, 19_200), new Ln("ELE-USBC1", "Carton", 25, 34_500),
                new Ln("ELE-PWB10", "Carton", 10, 54_000), new Ln("ELE-BTSPK", "Carton", 8, 44_500));
        container(12, "IMP-008", "SUP-GZ", "ZIMU1473986", 1_100_000, "40ft HC, Nansha to Karachi. Cleared last week.",
                new Ln("HOM-STOR30", "Carton", 50, 10_400), new Ln("HOM-BOTL750", "Carton", 30, 32_500),
                new Ln("HOM-PAN26", "Carton", 30, 18_400), new Ln("HOM-DIN24", "Carton", 12, 55_000));

        // Import-side payments tied to each container (customs, clearing, freight) and the supplier settlements.
        Object[][] charges = {{118, "IMP-001", 1_150_000, 235_000}, {103, "IMP-002", 1_420_000, 310_000}, {88, "IMP-003", 1_680_000, 350_000},
                {73, "IMP-004", 760_000, 190_000}, {58, "IMP-005", 940_000, 205_000}, {43, "IMP-006", 1_050_000, 260_000}};
        for (Object[] c : charges) {
            int day = (int) c[0];
            String no = (String) c[1];
            at(ago(day), 20, () -> {
                Long sid = shipmentRepo.findByShipmentNo(no).map(Shipment::getId).orElse(null);
                if (sid == null) return;
                expense(ago(day), "Customs duty", ExpenseNature.NON_OPERATING, ((Integer) c[2]).doubleValue(), "BANK_TRANSFER", sid, "Customs duty and taxes - " + no);
                expense(ago(day), "Port & clearing charges", ExpenseNature.NON_OPERATING, ((Integer) c[3]).doubleValue(), "BANK_TRANSFER", sid, "Clearing agent, terminal and demurrage - " + no);
            });
        }
        at(ago(100), 20, () -> supplierPay("SUP-SZ", 1_000_000, "BANK_TRANSFER", "TT-88214", "Part payment IMP-001"));
        at(ago(70), 20, () -> supplierPay("SUP-IST", 1_500_000, "BANK_TRANSFER", "TT-88377", "Part payment IMP-003"));
        at(ago(40), 20, () -> supplierPay("SUP-DXB", 500_000, "BANK_TRANSFER", "TT-88590", "Part payment IMP-005"));
        at(ago(15), 20, () -> supplierPay("SUP-KUL", 700_000, "BANK_TRANSFER", "TT-88702", "Part payment IMP-006"));
    }

    private void supplierPay(String code, double amount, String method, String ref, String notes) {
        Supplier s = supplierRepo.findByCode(code).orElseThrow();
        payments.paySupplier(new SupplierPaymentReq(s.getId(), null, bd(amount), method, null, ref, notes));
    }

    private void expense(LocalDate date, String category, ExpenseNature nature, double amount, String method, Long shipmentId, String description) {
        ExpenseCategory c = categoryRepo.findByNameAndNature(category, nature).orElseThrow();
        expenses.create(new ExpenseReq(date, nature, c.getId(), bd(amount), null, method, shipmentId, description));
    }

    // ------------------------------------------------------------------ sales

    /** Days-ago on which each product first had stock, so a sale is never dated before its container arrived. */
    private static final Map<String, Integer> FIRST_STOCK = Map.ofEntries(
            Map.entry("ELE-LED12", 120), Map.entry("ELE-USBC1", 120), Map.entry("ELE-PWB10", 120), Map.entry("ELE-BTSPK", 120),
            Map.entry("HOM-STOR30", 105), Map.entry("HOM-BOTL750", 105), Map.entry("HOM-PAN26", 105), Map.entry("HOM-DIN24", 105),
            Map.entry("TEX-TWL70", 90), Map.entry("TEX-BSET", 90), Map.entry("HOM-PILLOW", 75), Map.entry("FOD-COCO400", 75),
            Map.entry("FRG-OUD12", 60), Map.entry("FOD-DATE1", 60), Map.entry("FOD-PALM5", 45), Map.entry("CLN-DET1", 45));

    private void planSales() {
        List<String> skus = new ArrayList<>(FIRST_STOCK.keySet());
        skus.sort(String::compareTo);
        List<String> buyers = List.of("CUS-AMT", "CUS-SAE", "CUS-HMA", "CUS-LHS", "CUS-RGS", "CUS-BRK", "CUS-ISM", "CUS-MTG", "CUS-ANA", "CUS-FKW", "CUS-DCC", "CUS-JTC");
        for (int day = 112; day >= 1; day -= 2) {
            final int d = day;
            // two or three invoices every other day; the seeder trims quantities to what is actually on the shelf
            int count = 2 + rnd.nextInt(2);
            for (int k = 0; k < count; k++) {
                String sku = skus.get(rnd.nextInt(skus.size()));
                if (FIRST_STOCK.get(sku) - 1 >= d) {
                    boolean retail = rnd.nextInt(100) < 35;
                    String buyer = retail ? null : buyers.get(rnd.nextInt(buyers.size()));
                    int cartons = 1 + rnd.nextInt(4);
                    int pieces = 1 + rnd.nextInt(4);
                    double creditPct = new double[]{0, 0.3, 0.5, 1.0, 1.0}[rnd.nextInt(5)];
                    boolean discount = rnd.nextInt(100) < 20;
                    at(ago(d), 30 + k, () -> sellOne(ago(d), sku, buyer, cartons, pieces, creditPct, discount));
                }
            }
        }
    }

    private void sellOne(LocalDate date, String sku, String buyerCode, int cartons, int pieces, double paidPct, boolean discount) {
        Product p = productRepo.findBySku(sku).orElseThrow();
        boolean wholesale = buyerCode != null;
        Unit carton = unit("Carton");
        BigDecimal factor = p.getUnits().stream().filter(u -> u.getUnit().getId().equals(carton.getId())).map(ProductUnit::getFactor).findFirst().orElse(BigDecimal.ONE);
        BigDecimal available = stock.onHandForProduct(p.getId());
        boolean inCartons = wholesale && factor.signum() > 0;
        BigDecimal qty = inCartons ? bd(cartons) : bd(pieces);
        BigDecimal base = inCartons ? qty.multiply(factor) : qty;
        if (available.compareTo(base) < 0) {
            if (!inCartons || available.compareTo(factor) < 0) return;
            qty = available.divide(factor, 0, java.math.RoundingMode.DOWN);
            base = qty.multiply(factor);
            if (qty.signum() <= 0) return;
        }
        // Container-wise: sell from the oldest container that can cover the whole line, else let FIFO span containers.
        final BigDecimal need = base;
        Long batchId = stock.availableBatches(p.getId()).stream()
                .filter(a -> a.batch().getShipment().getArrivalDate().compareTo(date) <= 0 && a.baseQty().compareTo(need) >= 0)
                .map(a -> a.batch().getId()).findFirst().orElse(null);
        Customer customer = wholesale ? customerRepo.findByCode(buyerCode).orElseThrow() : null;
        BigDecimal rateUnit = (wholesale ? p.getWholesalePrice() : p.getRetailPrice());
        BigDecimal rate = inCartons ? rateUnit.multiply(factor) : rateUnit;
        BigDecimal lineGross = rate.multiply(qty);
        BigDecimal disc = discount && wholesale ? lineGross.multiply(bd(0.03)).setScale(0, java.math.RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal total = lineGross.subtract(disc);
        BigDecimal paid = wholesale ? total.multiply(bd(paidPct)).setScale(0, java.math.RoundingMode.HALF_UP) : total;
        sales.create(new SaleReq(date, wholesale ? SaleType.WHOLESALE : SaleType.RETAIL, customer == null ? null : customer.getId(),
                paid.signum() == 0 ? "CREDIT" : (rnd.nextBoolean() ? "CASH" : "BANK_TRANSFER"), null, paid, null, true,
                List.of(new SaleLineReq(p.getId(), batchId, inCartons ? carton.getId() : null, qty, rate, disc, BigDecimal.ZERO))));
    }

    // ------------------------------------------------------------------ collections, returns, adjustments

    private void planCollections() {
        at(ago(80), 40, () -> collect(ago(80), "CUS-AMT", 250_000, "CHEQUE", "CHQ-4412"));
        at(ago(60), 40, () -> collect(ago(60), "CUS-SAE", 400_000, "BANK_TRANSFER", "IBFT-22014"));
        at(ago(50), 40, () -> collect(ago(50), "CUS-LHS", 180_000, "BANK_TRANSFER", "IBFT-22871"));
        at(ago(42), 40, () -> collect(ago(42), "CUS-BRK", 150_000, "CASH", null));
        at(ago(33), 40, () -> collect(ago(33), "CUS-AMT", 300_000, "CHEQUE", "CHQ-4467"));
        at(ago(28), 40, () -> collect(ago(28), "CUS-HMA", 120_000, "ONLINE", "JC-901233"));
        at(ago(20), 40, () -> collect(ago(20), "CUS-ISM", 90_000, "CASH", null));
        at(ago(14), 40, () -> collect(ago(14), "CUS-SAE", 500_000, "BANK_TRANSFER", "IBFT-23310"));
        at(ago(9), 40, () -> collect(ago(9), "CUS-RGS", 42_500, "CASH", "Opening balance cleared"));
        at(ago(5), 40, () -> collect(ago(5), "CUS-JTC", 75_000, "CASH", null));

        // A return against the most recent wholesale invoice of Al-Madina Traders, and stock losses on two containers.
        at(ago(30), 50, () -> {
            Customer c = customerRepo.findByCode("CUS-AMT").orElseThrow();
            saleRepo.findByCustomerIdOrderBySaleDateAscIdAsc(c.getId()).stream().filter(s -> !s.getLines().isEmpty()).reduce((a, b) -> b).ifPresent(s -> {
                SaleLine line = s.getLines().get(0);
                BigDecimal q = line.getQty().min(BigDecimal.ONE);
                returns.create(new ReturnReq(s.getId(), ago(30), "Customer returned one unit - packaging damaged in transit.", BigDecimal.ZERO, null,
                        List.of(new ReturnLineReq(line.getId(), q))));
            });
        });
        at(ago(40), 51, () -> adjustFirstBatch(ago(40), "HOM-DIN24", MovementType.DAMAGED, 3, "3 sets broken during unloading from container"));
        at(ago(38), 51, () -> adjustFirstBatch(ago(38), "FOD-DATE1", MovementType.MISSING, 8, "Shortage found on counting - 8 kg short against packing list"));
    }

    private void collect(LocalDate date, String code, double amount, String method, String ref) {
        Customer c = customerRepo.findByCode(code).orElseThrow();
        // never collect more than the customer actually owes at that point in the timeline
        BigDecimal owed = ledger.customerBalance(c.getId());
        BigDecimal pay = bd(amount).min(owed);
        if (pay.signum() <= 0) return;
        payments.receivePayment(new ReceiptReq(c.getId(), date, pay, method, null, ref, null));
    }

    private void adjustFirstBatch(LocalDate date, String sku, MovementType type, double qty, String reason) {
        Product p = productRepo.findBySku(sku).orElseThrow();
        stock.availableBatches(p.getId()).stream().findFirst().ifPresent(a ->
                adjustments.adjust(new StockAdjReq(date, a.batch().getId(), type, false, p.getBaseUnit().getId(), bd(qty), reason)));
    }

    // ------------------------------------------------------------------ operating expenses

    private void planExpenses() {
        for (int m = 4; m >= 0; m--) {
            int day = m * 30 + 3;
            if (day > 130) continue;
            LocalDate d = ago(day);
            at(d, 60, () -> {
                expense(d, "Rent", ExpenseNature.OPERATING, 185_000, "BANK_TRANSFER", null, "Warehouse and shop rent");
                expense(d, "Salaries", ExpenseNature.OPERATING, 420_000, "BANK_TRANSFER", null, "Staff salaries (9 employees)");
                expense(d, "Electricity", ExpenseNature.OPERATING, 64_000 + rnd.nextInt(18_000), "CASH", null, "LESCO bill - warehouse");
            });
            at(d.plusDays(5), 61, () -> {
                expense(d.plusDays(5), "Transport", ExpenseNature.OPERATING, 38_000 + rnd.nextInt(15_000), "CASH", null, "Local delivery - Suzuki and Shehzore hire");
                expense(d.plusDays(5), "Loading / unloading", ExpenseNature.OPERATING, 22_000 + rnd.nextInt(8_000), "CASH", null, "Labour for container unloading");
                expense(d.plusDays(5), "Office expenses", ExpenseNature.OPERATING, 9_500 + rnd.nextInt(4_000), "CASH", null, "Stationery, tea and internet");
            });
        }
        at(ago(20), 62, () -> expense(ago(20), "Repairs", ExpenseNature.OPERATING, 28_000, "CASH", null, "Forklift service"));
        at(ago(10), 62, () -> expense(ago(10), "Bank charges", ExpenseNature.OPERATING, 6_800, "BANK_TRANSFER", null, "TT and LC charges"));
        at(ago(8), 63, () -> cash.createVoucher(new VoucherReq(ago(8), VoucherKind.PAYMENT, "DRAWINGS", null, null, bd(150_000), "Owner drawings")));
        at(ago(6), 63, () -> cash.createVoucher(new VoucherReq(ago(6), VoucherKind.RECEIPT, "OTHER_INCOME", null, null, bd(35_000), "Scrap sale - packing material")));
    }
}
