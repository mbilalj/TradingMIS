package com.portside.trading;

import static org.assertj.core.api.Assertions.assertThat;

import com.portside.trading.domain.Shipment;
import com.portside.trading.repo.Repos.*;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {"portside.sample-data.enabled=true", "spring.datasource.url=jdbc:h2:mem:portside_sample;MODE=MySQL;DB_CLOSE_DELAY=-1"})
class SampleDataSeederTest {

    @Autowired ProductRepo products;
    @Autowired ShipmentRepo shipments;
    @Autowired CustomerRepo customers;
    @Autowired SupplierRepo suppliers;
    @Autowired SaleRepo sales;
    @Autowired BatchRepo batches;
    @Autowired MovementRepo movements;
    @Autowired com.portside.trading.service.ReportService reports;

    @Test
    void loadsContainerWiseDemoData() {
        assertThat(products.count()).isEqualTo(16);
        assertThat(suppliers.count()).isEqualTo(6);
        assertThat(customers.count()).isGreaterThan(10);
        assertThat(shipments.count()).isEqualTo(8);
        assertThat(sales.count()).isGreaterThan(40);
        for (Shipment s : shipments.findAll()) {
            assertThat(s.getContainerNo()).isNotBlank();
            assertThat(s.getBatches()).isNotEmpty().allSatisfy(b -> assertThat(b.getBatchNo()).startsWith(s.getContainerNo()));
        }
        // no batch may ever be oversold
        batches.findAll().forEach(b -> assertThat(movements.onHandForBatch(b.getId())).isGreaterThanOrEqualTo(BigDecimal.ZERO));
    }

    @Test
    void containerReportsReconcileWithSalesReport() {
        var p = new com.portside.trading.service.ReportService.Params(java.time.LocalDate.now().minusDays(200), java.time.LocalDate.now(), null, null, null);
        var byContainer = reports.run("container-wise-sales", p);
        var detail = reports.run("container-product-sales", p);
        var byProduct = reports.run("product-wise-sales", p);
        assertThat(byContainer.rows()).hasSize(8);
        assertThat((BigDecimal) byContainer.totals().get("net_sales")).isGreaterThan(BigDecimal.ZERO);
        // the same sales, grouped three ways, must agree
        assertThat((BigDecimal) byContainer.totals().get("net_sales")).isEqualByComparingTo((BigDecimal) detail.totals().get("net_sales"));
        assertThat((BigDecimal) byContainer.totals().get("net_sales")).isEqualByComparingTo((BigDecimal) byProduct.totals().get("net_sales"));
        assertThat((BigDecimal) byContainer.totals().get("returns")).isGreaterThan(BigDecimal.ZERO);
    }
}
