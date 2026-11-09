/*
SQLyog Ultimate v10.00 Beta1
MySQL - 5.7.16-log : Database - portsidedb
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`portsidedb` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `portsidedb`;

/*Table structure for table `app_setting` */

DROP TABLE IF EXISTS `app_setting`;

CREATE TABLE `app_setting` (
  `setting_key` varchar(64) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `app_setting` */

insert  into `app_setting`(`setting_key`,`setting_value`) values ('books.startDate','2026-10-27'),('business.address','Islamabad'),('business.email','accounts@portside.pk'),('business.name','Portside Trading Co.'),('business.phone','0321-5407765'),('business.taxNo','NTN 3520211-4'),('invoice.footer','Thank you for your business.'),('sample.data.v1','seeding'),('tax.defaultPct','0'),('taxRatePct','18'),('usdRate','296.5');

/*Table structure for table `app_user` */

DROP TABLE IF EXISTS `app_user`;

CREATE TABLE `app_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(128) NOT NULL,
  `role` varchar(32) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

/*Data for the table `app_user` */

insert  into `app_user`(`id`,`username`,`password_hash`,`full_name`,`role`,`active`) values (1,'owner','$2a$10$x2DS4Ba4jZrhY2L7wiO4AuSAzgl0g8Tf/CdH73IKLY5O9S4KBs9PC','Ch Afzal Fareed ','OWNER',1),(2,'accountant','$2a$10$vzZSqXpDj0r6MWnHSMA.d.Su0dMCl1k2I5ILJ7rlUwbtstEmdLJuK','Ahmed Mehmood Modi','ACCOUNTANT',1),(3,'sales','$2a$10$SMtVXy/qqjfLpC2Ez/5sbujN2K7C7NjCyYP2FwqWgC2/nolSm8h3.','Ibrar Butt','SALES_OFFICER',1),(4,'storekeeper','$2a$10$aPOJE0xsEmmPBfvVhhCw4OQ3cGXD.TeHoT/TMh94FvcbQddmGuCCy','Muhammad Bilal','STORE_KEEPER',1),(5,'importdesk','$2a$10$C1tL5NGbe7QmjbNpEvAHM.00WPajfSO4naLgGrgoG3l6m7.L7AUai','Shoider','IMPORT_DESK',1);

/*Table structure for table `chart_of_account` */

DROP TABLE IF EXISTS `chart_of_account`;

CREATE TABLE `chart_of_account` (
  `code` varchar(16) NOT NULL,
  `name` varchar(128) NOT NULL,
  `type` varchar(32) NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `chart_of_account` */

insert  into `chart_of_account`(`code`,`name`,`type`) values ('1100','Bank — Meezan current','ASSET'),('1200','Trade receivables','ASSET'),('1300','Inventory — container lots','ASSET'),('1310','Goods in transit','ASSET'),('1400','Sales tax input (import)','ASSET'),('2100','Trade payables — suppliers','LIABILITY'),('2200','Sales tax output','LIABILITY'),('3100','Owner capital & retained','EQUITY'),('4100','Sales revenue','REVENUE'),('5100','Cost of goods sold','EXPENSE'),('5200','Import & clearing expenses','EXPENSE'),('6100','Operating expenses','EXPENSE');

/*Table structure for table `container` */

DROP TABLE IF EXISTS `container`;

CREATE TABLE `container` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `container_no` varchar(32) NOT NULL,
  `supplier_id` bigint(20) NOT NULL,
  `bl_number` varchar(32) DEFAULT NULL,
  `gd_number` varchar(32) DEFAULT NULL,
  `size` varchar(16) NOT NULL,
  `eta` date DEFAULT NULL,
  `received_date` date DEFAULT NULL,
  `status` varchar(16) NOT NULL,
  `current_basis` varchar(16) NOT NULL DEFAULT 'VALUE',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_container_supplier` (`supplier_id`),
  CONSTRAINT `fk_container_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

/*Data for the table `container` */

insert  into `container`(`id`,`code`,`container_no`,`supplier_id`,`bl_number`,`gd_number`,`size`,`eta`,`received_date`,`status`,`current_basis`) values (1,'PSC-2601','MSKU-4471820',1,'BL-HKG-77412','KAPW-HC-118420','40\' HC','2026-07-10','2026-07-12','SELLING','VALUE'),(2,'PSC-2602','TGHU-9013355',2,'BL-NGB-30188','KAPW-HC-121004','40\' HC','2026-07-30','2026-08-02','SELLING','VALUE'),(3,'PSC-2603','CSNU-6628104',3,'BL-TAO-55290','KAPW-HC-124771','20\' GP','2026-08-26','2026-08-28','SELLING','VALUE'),(4,'PSC-2604','OOLU-2277431',4,'BL-SHA-91002',NULL,'40\' HC','2026-09-09',NULL,'IN_CLEARANCE','VALUE'),(5,'PSC-2605','MSKU-7710269',2,'BL-NGB-31644',NULL,'40\' HC','2026-09-22',NULL,'IN_TRANSIT','VALUE'),(6,'PSC-2606','NEW-2606',1,'BL-PO-2606',NULL,'40\' HC','2026-09-17',NULL,'IN_CLEARANCE','VALUE');

/*Table structure for table `container_cost` */

DROP TABLE IF EXISTS `container_cost`;

CREATE TABLE `container_cost` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `container_id` bigint(20) NOT NULL,
  `expense_head` varchar(128) NOT NULL,
  `amount_pkr` double NOT NULL,
  `basis` varchar(16) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_ccost_container` (`container_id`),
  CONSTRAINT `fk_ccost_container` FOREIGN KEY (`container_id`) REFERENCES `container` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4;

/*Data for the table `container_cost` */

insert  into `container_cost`(`id`,`container_id`,`expense_head`,`amount_pkr`,`basis`) values (1,1,'Ocean freight',1185000,'OVERALL'),(2,1,'Marine insurance',214000,'VALUE'),(3,1,'Customs duty 20%',2394000,'VALUE'),(4,1,'Port & terminal (KPT)',386000,'OVERALL'),(5,1,'Clearing agent',175000,'QUANTITY'),(6,1,'Inland transport',248000,'OVERALL'),(7,1,'Bank & LC charges',142000,'VALUE'),(8,2,'Ocean freight',1310000,'OVERALL'),(9,2,'Marine insurance',268000,'VALUE'),(10,2,'Customs duty 20%',3012000,'VALUE'),(11,2,'Port & terminal (KPT)',402000,'OVERALL'),(12,2,'Clearing agent',180000,'QUANTITY'),(13,2,'Inland transport',262000,'OVERALL'),(14,2,'Bank & LC charges',161000,'VALUE'),(15,3,'Ocean freight',690000,'OVERALL'),(16,3,'Marine insurance',118000,'VALUE'),(17,3,'Customs duty 20%',1485000,'VALUE'),(18,3,'Port & terminal (KPT)',240000,'OVERALL'),(19,3,'Clearing agent',150000,'QUANTITY'),(20,3,'Inland transport',146000,'OVERALL'),(21,3,'Bank & LC charges',88000,'VALUE'),(22,4,'Ocean freight',1272000,'OVERALL'),(23,4,'Marine insurance',231000,'VALUE'),(24,4,'Customs duty 20%',2640000,'VALUE'),(25,5,'Ocean freight',1240000,'OVERALL'),(26,6,'Ocean freight',623895,'OVERALL'),(27,6,'Marine insurance',110915,'VALUE'),(28,6,'Customs duty 20%',1386434,'VALUE'),(29,4,'New expense head',0,'OVERALL');

/*Table structure for table `container_line` */

DROP TABLE IF EXISTS `container_line`;

CREATE TABLE `container_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `container_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `qty` double NOT NULL,
  `fob_unit_price_usd` double NOT NULL,
  `weight_kg` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_cline_container` (`container_id`),
  KEY `fk_cline_item` (`item_id`),
  CONSTRAINT `fk_cline_container` FOREIGN KEY (`container_id`) REFERENCES `container` (`id`),
  CONSTRAINT `fk_cline_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4;

/*Data for the table `container_line` */

insert  into `container_line`(`id`,`container_id`,`item_id`,`qty`,`fob_unit_price_usd`,`weight_kg`) values (1,1,1,4800,1.95,4200),(2,1,2,900,7.4,6300),(3,1,8,420,21.5,3200),(4,2,4,1250,33,12500),(5,2,5,2600,6.1,3900),(6,2,3,560,26,4500),(7,3,6,1800,9.2,5400),(8,3,7,1400,12.8,7000),(9,4,5,3200,6.05,4800),(10,4,4,700,32.4,7000),(11,5,1,5200,2.02,4550),(12,5,2,1100,7.55,7700),(13,6,8,600,21.9,1920),(14,6,3,400,25.6,1280);

/*Table structure for table `customer` */

DROP TABLE IF EXISTS `customer`;

CREATE TABLE `customer` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `name` varchar(200) NOT NULL,
  `city` varchar(64) NOT NULL,
  `payment_terms` varchar(32) NOT NULL,
  `credit_limit` double NOT NULL DEFAULT '0',
  `standing_discount_pct` double NOT NULL DEFAULT '0',
  `salesman` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

/*Data for the table `customer` */

insert  into `customer`(`id`,`code`,`name`,`city`,`payment_terms`,`credit_limit`,`standing_discount_pct`,`salesman`) values (1,'C-01','Al-Madina Hardware','Karachi','30 days',4000000,0,'Imran Qadri'),(2,'C-02','Sindh Electric Traders','Hyderabad','45 days',2500000,2.5,'Imran Qadri'),(3,'C-03','Gulf Tools & Machinery','Lahore','Cash',1500000,5,'Naveed Alam'),(4,'C-04','Pak Plumbing Mart','Karachi','30 days',1000000,0,'Naveed Alam'),(5,'C-05','Continental Traders','Faisalabad','60 days',3000000,3,'Imran Qadri');

/*Table structure for table `flyway_schema_history` */

DROP TABLE IF EXISTS `flyway_schema_history`;

CREATE TABLE `flyway_schema_history` (
  `installed_rank` int(11) NOT NULL,
  `version` varchar(50) DEFAULT NULL,
  `description` varchar(200) NOT NULL,
  `type` varchar(20) NOT NULL,
  `script` varchar(1000) NOT NULL,
  `checksum` int(11) DEFAULT NULL,
  `installed_by` varchar(100) NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execution_time` int(11) NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`),
  KEY `flyway_schema_history_s_idx` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `flyway_schema_history` */

insert  into `flyway_schema_history`(`installed_rank`,`version`,`description`,`type`,`script`,`checksum`,`installed_by`,`installed_on`,`execution_time`,`success`) values (1,'1','<< Flyway Baseline >>','BASELINE','<< Flyway Baseline >>',NULL,'portside_app','2026-09-15 16:49:51',0,1),(2,'2','seed','SQL','V2__seed.sql',-587715348,'portside_app','2026-09-15 16:49:51',34,0);

/*Table structure for table `item` */

DROP TABLE IF EXISTS `item`;

CREATE TABLE `item` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `name` varchar(200) NOT NULL,
  `uom` varchar(16) NOT NULL,
  `category` varchar(64) NOT NULL,
  `reorder_level` double NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

/*Data for the table `item` */

insert  into `item`(`id`,`code`,`name`,`uom`,`category`,`reorder_level`) values (1,'HW-1001','Ball bearing 6204-2RS','pcs','Hardware',400),(2,'HW-1002','Hex bolt M12 x 80, box 100','box','Hardware',400),(3,'HW-1010','Angle grinder 850W','pcs','Power tools',400),(4,'EL-2003','Copper cable 2.5mm, roll 100m','roll','Electrical',400),(5,'EL-2007','LED panel light 36W','pcs','Electrical',400),(6,'PL-3001','PPRC elbow 32mm, box 50','box','Plumbing',400),(7,'PL-3004','Gate valve 2in brass','pcs','Plumbing',400),(8,'TL-4002','Impact drill 13mm','pcs','Power tools',400);

/*Table structure for table `journal_entry` */

DROP TABLE IF EXISTS `journal_entry`;

CREATE TABLE `journal_entry` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `voucher_no` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `narration` varchar(255) NOT NULL,
  `source_type` varchar(32) NOT NULL,
  `source_code` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `voucher_no` (`voucher_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `journal_entry` */

/*Table structure for table `journal_line` */

DROP TABLE IF EXISTS `journal_line`;

CREATE TABLE `journal_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `journal_entry_id` bigint(20) NOT NULL,
  `account_code` varchar(16) NOT NULL,
  `debit` double NOT NULL DEFAULT '0',
  `credit` double NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_jline_entry` (`journal_entry_id`),
  KEY `fk_jline_account` (`account_code`),
  CONSTRAINT `fk_jline_account` FOREIGN KEY (`account_code`) REFERENCES `chart_of_account` (`code`),
  CONSTRAINT `fk_jline_entry` FOREIGN KEY (`journal_entry_id`) REFERENCES `journal_entry` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `journal_line` */

/*Table structure for table `mis_account` */

DROP TABLE IF EXISTS `mis_account`;

CREATE TABLE `mis_account` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `account_number` varchar(64) DEFAULT NULL,
  `active` bit(1) NOT NULL,
  `head_code` varchar(16) DEFAULT NULL,
  `name` varchar(128) NOT NULL,
  `opening_balance` decimal(18,2) NOT NULL,
  `type` enum('BANK','CASH') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKq3dj3p8egr532fimg2kjfv77d` (`head_code`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

/*Data for the table `mis_account` */

insert  into `mis_account`(`id`,`account_number`,`active`,`head_code`,`name`,`opening_balance`,`type`) values (1,NULL,'','ACC-1','Cash in Hand','0.00','CASH'),(2,NULL,'','ACC-2','Main Bank Account','0.00','BANK'),(3,'PK36HABB0000123456702','','ACC-3','HBL Current - Lahore Main Branch','0.00','BANK'),(4,'PK12MEZN0001230101234567','','ACC-4','Meezan Bank - Gulberg Branch','0.00','BANK'),(5,'0127790052487','','ACC-5','Meezan Bank Limited','1500000.00','BANK');

/*Table structure for table `mis_attachment` */

DROP TABLE IF EXISTS `mis_attachment`;

CREATE TABLE `mis_attachment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `content_type` varchar(128) DEFAULT NULL,
  `file_name` varchar(255) NOT NULL,
  `owner_id` bigint(20) NOT NULL,
  `owner_type` varchar(24) NOT NULL,
  `size` bigint(20) NOT NULL,
  `stored_name` varchar(255) NOT NULL,
  `uploaded_at` datetime(6) DEFAULT NULL,
  `uploaded_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDXb391ykti8ykypg5crym67vx3q` (`owner_type`,`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `mis_attachment` */

/*Table structure for table `mis_batch` */

DROP TABLE IF EXISTS `mis_batch`;

CREATE TABLE `mis_batch` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `batch_no` varchar(64) NOT NULL,
  `entered_qty` decimal(18,4) NOT NULL,
  `entered_unit_cost` decimal(18,4) NOT NULL,
  `received_qty` decimal(18,4) NOT NULL,
  `unit_cost` decimal(18,4) NOT NULL,
  `entered_unit_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `shipment_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK1a8oubaptko08scbjlpnep7ba` (`batch_no`),
  KEY `FK91iicdqm0k94rncfsab8i9b44` (`entered_unit_id`),
  KEY `FKu5gmn0yqhpvrdsfwi14s1eq2` (`product_id`),
  KEY `FK6103tnlibn5bur2qi8wp7k29f` (`shipment_id`),
  CONSTRAINT `FK6103tnlibn5bur2qi8wp7k29f` FOREIGN KEY (`shipment_id`) REFERENCES `mis_shipment` (`id`),
  CONSTRAINT `FK91iicdqm0k94rncfsab8i9b44` FOREIGN KEY (`entered_unit_id`) REFERENCES `mis_unit` (`id`),
  CONSTRAINT `FKu5gmn0yqhpvrdsfwi14s1eq2` FOREIGN KEY (`product_id`) REFERENCES `mis_product` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=utf8;

/*Data for the table `mis_batch` */

insert  into `mis_batch`(`id`,`batch_no`,`entered_qty`,`entered_unit_cost`,`received_qty`,`unit_cost`,`entered_unit_id`,`product_id`,`shipment_id`) values (1,'MSKU4417823-01','80.0000','18500.0000','8000.0000','185.0000',3,1,1),(2,'MSKU4417823-02','30.0000','33000.0000','6000.0000','165.0000',3,2,1),(3,'MSKU4417823-03','12.0000','52000.0000','240.0000','2600.0000',3,3,1),(4,'MSKU4417823-04','10.0000','43000.0000','240.0000','1791.6667',3,4,1),(5,'TCLU8830912-01','90.0000','9800.0000','1080.0000','816.6667',3,5,2),(6,'TCLU8830912-02','40.0000','31000.0000','1920.0000','645.8333',3,6,2),(7,'TCLU8830912-03','50.0000','17500.0000','600.0000','1458.3333',3,7,2),(8,'TCLU8830912-04','25.0000','52000.0000','100.0000','13000.0000',3,8,2),(9,'CMAU2257741-01','70.0000','55000.0000','4200.0000','916.6667',3,9,3),(10,'CMAU2257741-02','45.0000','21500.0000','450.0000','2150.0000',3,10,3),(11,'HLXU6014389-01','30.0000','24500.0000','240.0000','3062.5000',3,13,4),(12,'HLXU6014389-02','160.0000','4300.0000','3840.0000','179.1667',3,14,4),(13,'OOLU3392760-01','12.0000','150000.0000','1728.0000','1041.6667',3,11,5),(14,'OOLU3392760-02','140.0000','11800.0000','1400.0000','1180.0000',3,12,5),(15,'MAEU5568124-01','220.0000','9200.0000','4400.0000','460.0000',3,15,6),(16,'MAEU5568124-02','120.0000','5500.0000','1440.0000','458.3333',3,16,6),(17,'EGHU9027153-01','60.0000','19200.0000','6000.0000','192.0000',3,1,7),(18,'EGHU9027153-02','25.0000','34500.0000','5000.0000','172.5000',3,2,7),(19,'EGHU9027153-03','10.0000','54000.0000','200.0000','2700.0000',3,3,7),(20,'EGHU9027153-04','8.0000','44500.0000','192.0000','1854.1667',3,4,7),(21,'ZIMU1473986-01','50.0000','10400.0000','600.0000','866.6667',3,5,8),(22,'ZIMU1473986-02','30.0000','32500.0000','1440.0000','677.0833',3,6,8),(23,'ZIMU1473986-03','30.0000','18400.0000','360.0000','1533.3333',3,7,8),(24,'ZIMU1473986-04','12.0000','55000.0000','48.0000','13750.0000',3,8,8),(25,'ABC-CONTAINER-01','25000.0000','600.0000','25000.0000','600.0000',1,2,9),(26,'ABC-CONTAINER-02','25000.0000','600.0000','25000.0000','600.0000',1,6,9),(27,'ABC-CONTAINER-03','60000.0000','600.0000','60000.0000','600.0000',1,1,9),(28,'CNT-005-01','2500.0000','260.0000','2500.0000','260.0000',1,1,10),(29,'CNT-005-02','200.0000','200.0000','200.0000','200.0000',1,2,10),(30,'CNT-005-03','100.0000','200.0000','100.0000','200.0000',1,1,10),(31,'CNT-005-04','10.0000','50.0000','10.0000','50.0000',1,5,10),(32,'LS-197-01','30000.0000','129.0000','30000.0000','129.0000',6,17,11),(33,'05-01','5000.0000','300.0000','5000.0000','300.0000',1,18,12),(34,'CTN-002-002-01','1250.0000','40000.0000','1250.0000','40000.0000',1,19,13);

/*Table structure for table `mis_cash_voucher` */

DROP TABLE IF EXISTS `mis_cash_voucher`;

CREATE TABLE `mis_cash_voucher` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `amount` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `kind` enum('PAYMENT','RECEIPT','TRANSFER') NOT NULL,
  `purpose` varchar(24) DEFAULT NULL,
  `voucher_date` date NOT NULL,
  `voucher_no` varchar(32) NOT NULL,
  `account_id` bigint(20) NOT NULL,
  `to_account_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKrn9x6w1lusl495436khyipheu` (`voucher_no`),
  KEY `FKd4kwuu8sojlr7f2bck1989nvc` (`account_id`),
  KEY `FK50o6c8c7r49i7bykqpnu97n9e` (`to_account_id`),
  CONSTRAINT `FK50o6c8c7r49i7bykqpnu97n9e` FOREIGN KEY (`to_account_id`) REFERENCES `mis_account` (`id`),
  CONSTRAINT `FKd4kwuu8sojlr7f2bck1989nvc` FOREIGN KEY (`account_id`) REFERENCES `mis_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

/*Data for the table `mis_cash_voucher` */

insert  into `mis_cash_voucher`(`id`,`amount`,`created_at`,`created_by`,`description`,`kind`,`purpose`,`voucher_date`,`voucher_no`,`account_id`,`to_account_id`) values (1,'60000000.00','2026-10-27 17:09:05.777669',NULL,'Owner capital introduced to fund container imports','RECEIPT','CAPITAL_INTRODUCED','2026-06-14','CR-000001',2,NULL),(2,'1500000.00','2026-10-27 17:09:05.810182',NULL,'Float for the shop till','TRANSFER',NULL,'2026-06-14','TRF-000002',2,1),(3,'150000.00','2026-10-27 17:09:10.874317',NULL,'Owner drawings','PAYMENT','DRAWINGS','2026-10-19','CP-000003',2,NULL),(4,'35000.00','2026-10-27 17:09:10.964040',NULL,'Scrap sale - packing material','RECEIPT','OTHER_INCOME','2026-10-21','CR-000004',2,NULL);

/*Table structure for table `mis_customer` */

DROP TABLE IF EXISTS `mis_customer`;

CREATE TABLE `mis_customer` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `active` bit(1) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `code` varchar(32) NOT NULL,
  `credit_days` int(11) NOT NULL,
  `credit_limit` decimal(18,2) NOT NULL,
  `name` varchar(200) NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `opening_balance` decimal(18,2) NOT NULL,
  `phone` varchar(64) DEFAULT NULL,
  `type` enum('RETAIL','WHOLESALE') NOT NULL,
  `walk_in` bit(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKss3ql2effredubp17k562vfj0` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

/*Data for the table `mis_customer` */

insert  into `mis_customer`(`id`,`active`,`address`,`code`,`credit_days`,`credit_limit`,`name`,`notes`,`opening_balance`,`phone`,`type`,`walk_in`) values (1,'',NULL,'WALKIN',0,'0.00','Walk-in Customer',NULL,'0.00',NULL,'RETAIL',''),(2,'','Shop 22, Azam Cloth Market, Lahore','CUS-AMT',30,'2500000.00','Al-Madina Traders','Textiles and household buyer; pays on the 1st of every month.','85000.00','0300-4412876','WHOLESALE','\0'),(3,'','Shah Alam Market, Lahore','CUS-SAE',21,'3000000.00','Shah Alam Electronics Centre','Large electronics reseller.','0.00','0321-4410098','WHOLESALE','\0'),(4,'','Hafeez Centre, Gulberg III, Lahore','CUS-HMA',14,'1500000.00','Hafeez Mobile Accessories','Cables, power banks and speakers.','0.00','0333-4287761','WHOLESALE','\0'),(5,'','Liberty Market, Gulberg, Lahore','CUS-LHS',30,'2000000.00','Liberty Home Store',NULL,'0.00','042-35761208','WHOLESALE','\0'),(6,'','Lohari Gate, Lahore','CUS-RGS',30,'1000000.00','Rehmat General Store',NULL,'42500.00','0345-4509912','WHOLESALE','\0'),(7,'','Brandreth Road, Lahore','CUS-BRK',21,'1800000.00','Brandreth Road Kitchenware','Steel, non-stick and ceramic ware.','0.00','0300-4398120','WHOLESALE','\0'),(8,'','Ferozepur Road near Ichhra Bazaar, Lahore','CUS-ISM',30,'1200000.00','Ichhra Super Mart','Grocery chain, two outlets.','0.00','0322-4471109','WHOLESALE','\0'),(9,'','Link Road, Model Town, Lahore','CUS-MTG',15,'800000.00','Model Town Grocers',NULL,'0.00','042-35832245','WHOLESALE','\0'),(10,'','Chowk Rang Mahal, Walled City, Lahore','CUS-ANA',15,'600000.00','Al-Noor Attar House','Perfume and dates.','0.00','0301-4466720','WHOLESALE','\0'),(11,'','Mozang Chungi, Lahore','CUS-FKW',21,'900000.00','Faisal Kitchen Ware',NULL,'0.00','0314-4452307','WHOLESALE','\0'),(12,'','Phase 5, DHA, Lahore','CUS-DCC',7,'400000.00','DHA Cash & Carry','Walk-in retail with a running account.','0.00','0321-4423319','RETAIL','\0'),(13,'','Block R1, Johar Town, Lahore','CUS-JTC',30,'1000000.00','Johar Town Bedding Centre',NULL,'0.00','0332-4415566','WHOLESALE','\0'),(14,'','09-Street Garhi Shahu Lahorew','CUS-000001',30,'300000.00','Charag Deen Enterprises',NULL,'50000.00','03214246922','WHOLESALE','\0');

/*Table structure for table `mis_expense` */

DROP TABLE IF EXISTS `mis_expense`;

CREATE TABLE `mis_expense` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `amount` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `expense_date` date NOT NULL,
  `expense_no` varchar(32) NOT NULL,
  `method` varchar(32) DEFAULT NULL,
  `nature` enum('NON_OPERATING','OPERATING') NOT NULL,
  `account_id` bigint(20) NOT NULL,
  `category_id` bigint(20) NOT NULL,
  `shipment_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKp9qcrt1m815rvu69rm9vex7x0` (`expense_no`),
  KEY `FKigrs4mr0giomxbvs9mvgbatgf` (`account_id`),
  KEY `FK9a2mfkseca8m9o361i9r1u1br` (`category_id`),
  KEY `FKpyp8up1bj9qgu2higp54p2i58` (`shipment_id`),
  CONSTRAINT `FK9a2mfkseca8m9o361i9r1u1br` FOREIGN KEY (`category_id`) REFERENCES `mis_expense_category` (`id`),
  CONSTRAINT `FKigrs4mr0giomxbvs9mvgbatgf` FOREIGN KEY (`account_id`) REFERENCES `mis_account` (`id`),
  CONSTRAINT `FKpyp8up1bj9qgu2higp54p2i58` FOREIGN KEY (`shipment_id`) REFERENCES `mis_shipment` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;

/*Data for the table `mis_expense` */

insert  into `mis_expense`(`id`,`amount`,`created_at`,`created_by`,`description`,`expense_date`,`expense_no`,`method`,`nature`,`account_id`,`category_id`,`shipment_id`) values (1,'185000.00','2026-10-27 17:09:05.841301',NULL,'Warehouse and shop rent','2026-06-26','EXP-000001','BANK_TRANSFER','OPERATING',2,4,NULL),(2,'420000.00','2026-10-27 17:09:05.863420',NULL,'Staff salaries (9 employees)','2026-06-26','EXP-000002','BANK_TRANSFER','OPERATING',2,2,NULL),(3,'68494.00','2026-10-27 17:09:05.887511',NULL,'LESCO bill - warehouse','2026-06-26','EXP-000003','CASH','OPERATING',1,3,NULL),(4,'1150000.00','2026-10-27 17:09:06.063957',NULL,'Customs duty and taxes - IMP-001','2026-07-01','NOP-000004','BANK_TRANSFER','NON_OPERATING',2,13,1),(5,'235000.00','2026-10-27 17:09:06.096515',NULL,'Clearing agent, terminal and demurrage - IMP-001','2026-07-01','NOP-000005','BANK_TRANSFER','NON_OPERATING',2,14,1),(6,'48767.00','2026-10-27 17:09:06.121631',NULL,'Local delivery - Suzuki and Shehzore hire','2026-07-01','EXP-000006','CASH','OPERATING',1,5,NULL),(7,'26551.00','2026-10-27 17:09:06.143819',NULL,'Labour for container unloading','2026-07-01','EXP-000007','CASH','OPERATING',1,7,NULL),(8,'12301.00','2026-10-27 17:09:06.165847',NULL,'Stationery, tea and internet','2026-07-01','EXP-000008','CASH','OPERATING',1,8,NULL),(9,'1420000.00','2026-10-27 17:09:06.487590',NULL,'Customs duty and taxes - IMP-002','2026-07-16','NOP-000009','BANK_TRANSFER','NON_OPERATING',2,13,2),(10,'310000.00','2026-10-27 17:09:06.511751',NULL,'Clearing agent, terminal and demurrage - IMP-002','2026-07-16','NOP-000010','BANK_TRANSFER','NON_OPERATING',2,14,2),(11,'185000.00','2026-10-27 17:09:06.941846',NULL,'Warehouse and shop rent','2026-07-26','EXP-000011','BANK_TRANSFER','OPERATING',2,4,NULL),(12,'420000.00','2026-10-27 17:09:06.957771',NULL,'Staff salaries (9 employees)','2026-07-26','EXP-000012','BANK_TRANSFER','OPERATING',2,2,NULL),(13,'70113.00','2026-10-27 17:09:06.975784',NULL,'LESCO bill - warehouse','2026-07-26','EXP-000013','CASH','OPERATING',1,3,NULL),(14,'1680000.00','2026-10-27 17:09:07.141423',NULL,'Customs duty and taxes - IMP-003','2026-07-31','NOP-000014','BANK_TRANSFER','NON_OPERATING',2,13,3),(15,'350000.00','2026-10-27 17:09:07.156029',NULL,'Clearing agent, terminal and demurrage - IMP-003','2026-07-31','NOP-000015','BANK_TRANSFER','NON_OPERATING',2,14,3),(16,'41884.00','2026-10-27 17:09:07.257228',NULL,'Local delivery - Suzuki and Shehzore hire','2026-07-31','EXP-000016','CASH','OPERATING',1,5,NULL),(17,'24146.00','2026-10-27 17:09:07.274239',NULL,'Labour for container unloading','2026-07-31','EXP-000017','CASH','OPERATING',1,7,NULL),(18,'10868.00','2026-10-27 17:09:07.293789',NULL,'Stationery, tea and internet','2026-07-31','EXP-000018','CASH','OPERATING',1,8,NULL),(19,'760000.00','2026-10-27 17:09:08.005878',NULL,'Customs duty and taxes - IMP-004','2026-08-15','NOP-000019','BANK_TRANSFER','NON_OPERATING',2,13,4),(20,'190000.00','2026-10-27 17:09:08.026888',NULL,'Clearing agent, terminal and demurrage - IMP-004','2026-08-15','NOP-000020','BANK_TRANSFER','NON_OPERATING',2,14,4),(21,'185000.00','2026-10-27 17:09:08.279562',NULL,'Warehouse and shop rent','2026-08-25','EXP-000021','BANK_TRANSFER','OPERATING',2,4,NULL),(22,'420000.00','2026-10-27 17:09:08.288673',NULL,'Staff salaries (9 employees)','2026-08-25','EXP-000022','BANK_TRANSFER','OPERATING',2,2,NULL),(23,'77171.00','2026-10-27 17:09:08.300207',NULL,'LESCO bill - warehouse','2026-08-25','EXP-000023','CASH','OPERATING',1,3,NULL),(24,'940000.00','2026-10-27 17:09:08.440285',NULL,'Customs duty and taxes - IMP-005','2026-08-30','NOP-000024','BANK_TRANSFER','NON_OPERATING',2,13,5),(25,'205000.00','2026-10-27 17:09:08.453976',NULL,'Clearing agent, terminal and demurrage - IMP-005','2026-08-30','NOP-000025','BANK_TRANSFER','NON_OPERATING',2,14,5),(26,'48531.00','2026-10-27 17:09:08.551186',NULL,'Local delivery - Suzuki and Shehzore hire','2026-08-30','EXP-000026','CASH','OPERATING',1,5,NULL),(27,'28842.00','2026-10-27 17:09:08.560698',NULL,'Labour for container unloading','2026-08-30','EXP-000027','CASH','OPERATING',1,7,NULL),(28,'13071.00','2026-10-27 17:09:08.569216',NULL,'Stationery, tea and internet','2026-08-30','EXP-000028','CASH','OPERATING',1,8,NULL),(29,'1050000.00','2026-10-27 17:09:09.147308',NULL,'Customs duty and taxes - IMP-006','2026-09-14','NOP-000029','BANK_TRANSFER','NON_OPERATING',2,13,6),(30,'260000.00','2026-10-27 17:09:09.161677',NULL,'Clearing agent, terminal and demurrage - IMP-006','2026-09-14','NOP-000030','BANK_TRANSFER','NON_OPERATING',2,14,6),(31,'185000.00','2026-10-27 17:09:09.587237',NULL,'Warehouse and shop rent','2026-09-24','EXP-000031','BANK_TRANSFER','OPERATING',2,4,NULL),(32,'420000.00','2026-10-27 17:09:09.597240',NULL,'Staff salaries (9 employees)','2026-09-24','EXP-000032','BANK_TRANSFER','OPERATING',2,2,NULL),(33,'69894.00','2026-10-27 17:09:09.605821',NULL,'LESCO bill - warehouse','2026-09-24','EXP-000033','CASH','OPERATING',1,3,NULL),(34,'52720.00','2026-10-27 17:09:09.940719',NULL,'Local delivery - Suzuki and Shehzore hire','2026-09-29','EXP-000034','CASH','OPERATING',1,5,NULL),(35,'25812.00','2026-10-27 17:09:09.951254',NULL,'Labour for container unloading','2026-09-29','EXP-000035','CASH','OPERATING',1,7,NULL),(36,'13335.00','2026-10-27 17:09:09.959147',NULL,'Stationery, tea and internet','2026-09-29','EXP-000036','CASH','OPERATING',1,8,NULL),(37,'28000.00','2026-10-27 17:09:10.268886',NULL,'Forklift service','2026-10-07','EXP-000037','CASH','OPERATING',1,9,NULL),(38,'6800.00','2026-10-27 17:09:10.707454',NULL,'TT and LC charges','2026-10-17','EXP-000038','BANK_TRANSFER','OPERATING',2,11,NULL),(39,'185000.00','2026-10-27 17:09:11.061441',NULL,'Warehouse and shop rent','2026-10-24','EXP-000039','BANK_TRANSFER','OPERATING',2,4,NULL),(40,'420000.00','2026-10-27 17:09:11.070441',NULL,'Staff salaries (9 employees)','2026-10-24','EXP-000040','BANK_TRANSFER','OPERATING',2,2,NULL),(41,'75191.00','2026-10-27 17:09:11.078441',NULL,'LESCO bill - warehouse','2026-10-24','EXP-000041','CASH','OPERATING',1,3,NULL),(42,'40349.00','2026-10-27 17:09:11.139416',NULL,'Local delivery - Suzuki and Shehzore hire','2026-10-29','EXP-000042','CASH','OPERATING',1,5,NULL),(43,'25277.00','2026-10-27 17:09:11.145480',NULL,'Labour for container unloading','2026-10-29','EXP-000043','CASH','OPERATING',1,7,NULL),(44,'10531.00','2026-10-27 17:09:11.155402',NULL,'Stationery, tea and internet','2026-10-29','EXP-000044','CASH','OPERATING',1,8,NULL),(45,'60000000.00','2026-10-27 17:14:03.690843','owner',NULL,'2026-10-27','NOP-000045','CASH','NON_OPERATING',1,13,9),(46,'50000.00','2026-10-30 16:53:07.118430','owner',NULL,'2026-10-30','NOP-000046','CASH','NON_OPERATING',1,13,11),(47,'200000.00','2026-10-30 19:32:06.067074','owner',NULL,'2026-10-31','EXP-000047','CASH','OPERATING',1,2,NULL),(48,'5000.00','2026-11-05 16:08:33.770711','owner',NULL,'2026-11-05','NOP-000048','CASH','NON_OPERATING',1,13,13);

/*Table structure for table `mis_expense_category` */

DROP TABLE IF EXISTS `mis_expense_category`;

CREATE TABLE `mis_expense_category` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `active` bit(1) NOT NULL,
  `head_code` varchar(16) DEFAULT NULL,
  `name` varchar(96) NOT NULL,
  `nature` enum('NON_OPERATING','OPERATING') NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKls5miryh96k5f105n1iar0q82` (`head_code`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;

/*Data for the table `mis_expense_category` */

insert  into `mis_expense_category`(`id`,`active`,`head_code`,`name`,`nature`) values (1,'','EXP-1','Warehouse expenses','OPERATING'),(2,'','EXP-2','Salaries','OPERATING'),(3,'','EXP-3','Electricity','OPERATING'),(4,'','EXP-4','Rent','OPERATING'),(5,'','EXP-5','Transport','OPERATING'),(6,'','EXP-6','Packing','OPERATING'),(7,'','EXP-7','Loading / unloading','OPERATING'),(8,'','EXP-8','Office expenses','OPERATING'),(9,'','EXP-9','Repairs','OPERATING'),(10,'','EXP-10','Commission','OPERATING'),(11,'','EXP-11','Bank charges','OPERATING'),(12,'','EXP-12','Other expenses','OPERATING'),(13,'',NULL,'Customs duty','NON_OPERATING'),(14,'',NULL,'Port & clearing charges','NON_OPERATING'),(15,'',NULL,'Freight / shipping','NON_OPERATING'),(16,'',NULL,'Other shipment payment','NON_OPERATING'),(17,'',NULL,'Capital / non-operating payment','NON_OPERATING');

/*Table structure for table `mis_head` */

DROP TABLE IF EXISTS `mis_head`;

CREATE TABLE `mis_head` (
  `code` varchar(16) NOT NULL,
  `name` varchar(128) NOT NULL,
  `type` enum('ASSET','COST_OF_SALES','EQUITY','EXPENSE','INCOME','LIABILITY') NOT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `mis_head` */

insert  into `mis_head`(`code`,`name`,`type`) values ('1200','Accounts receivable (customers)','ASSET'),('1300','Inventory','ASSET'),('1400','Shipment / non-operating payments (not in P&L)','ASSET'),('2100','Accounts payable (suppliers)','LIABILITY'),('2200','Sales tax payable','LIABILITY'),('3100','Imported stock introduced (import settled outside system)','EQUITY'),('3200','Owner capital','EQUITY'),('3300','Owner drawings','EQUITY'),('3900','Opening balance equity','EQUITY'),('4000','Sales','INCOME'),('4100','Sales returns','INCOME'),('4900','Other income','INCOME'),('5000','Cost of goods sold','COST_OF_SALES'),('5100','Stock losses & adjustments','COST_OF_SALES'),('6900','Other expenses','EXPENSE'),('ACC-1','Cash - Cash in Hand','ASSET'),('ACC-2','Bank - Main Bank Account','ASSET'),('ACC-3','Bank - HBL Current - Lahore Main Branch','ASSET'),('ACC-4','Bank - Meezan Bank - Gulberg Branch','ASSET'),('ACC-5','Bank - Meezan Bank Limited','ASSET'),('EXP-1','Warehouse expenses','EXPENSE'),('EXP-10','Commission','EXPENSE'),('EXP-11','Bank charges','EXPENSE'),('EXP-12','Other expenses','EXPENSE'),('EXP-2','Salaries','EXPENSE'),('EXP-3','Electricity','EXPENSE'),('EXP-4','Rent','EXPENSE'),('EXP-5','Transport','EXPENSE'),('EXP-6','Packing','EXPENSE'),('EXP-7','Loading / unloading','EXPENSE'),('EXP-8','Office expenses','EXPENSE'),('EXP-9','Repairs','EXPENSE');

/*Table structure for table `mis_journal` */

DROP TABLE IF EXISTS `mis_journal`;

CREATE TABLE `mis_journal` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `journal_date` date NOT NULL,
  `narration` varchar(255) NOT NULL,
  `source_no` varchar(48) NOT NULL,
  `source_type` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `IDX50he4m9asin2d02l04l7lnx7g` (`source_type`,`source_no`),
  KEY `IDXhaf3bhq3faeixv714qis5sttx` (`journal_date`)
) ENGINE=InnoDB AUTO_INCREMENT=209 DEFAULT CHARSET=utf8;

/*Data for the table `mis_journal` */

insert  into `mis_journal`(`id`,`journal_date`,`narration`,`source_no`,`source_type`) values (1,'2026-10-27','Opening balance - Al-Madina Traders','CUS-AMT','OPENING_CUSTOMER'),(2,'2026-10-27','Opening balance - Rehmat General Store','CUS-RGS','OPENING_CUSTOMER'),(3,'2026-06-14','Cash/bank received - capital introduced: Owner capital introduced to fund container imports','CR-000001','VOUCHER'),(4,'2026-06-14','Transfer Main Bank Account to Cash in Hand','TRF-000002','VOUCHER'),(5,'2026-06-26','Expense - Rent','EXP-000001','EXPENSE'),(6,'2026-06-26','Expense - Salaries','EXP-000002','EXPENSE'),(7,'2026-06-26','Expense - Electricity','EXP-000003','EXPENSE'),(8,'2026-06-29','Stock received IMP-001 from Shenzhen Brightway Electronics Co., Ltd','IMP-001','SHIPMENT'),(9,'2026-07-01','Non-operating payment - Customs duty (IMP-001)','NOP-000004','EXPENSE'),(10,'2026-07-01','Non-operating payment - Port & clearing charges (IMP-001)','NOP-000005','EXPENSE'),(11,'2026-07-01','Expense - Transport','EXP-000006','EXPENSE'),(12,'2026-07-01','Expense - Loading / unloading','EXP-000007','EXPENSE'),(13,'2026-07-01','Expense - Office expenses','EXP-000008','EXPENSE'),(14,'2026-07-07','Sale INV-000001 - Ichhra Super Mart','INV-000001','SALE'),(15,'2026-07-11','Sale INV-000002 - Walk-in Customer','INV-000002','SALE'),(16,'2026-07-14','Stock received IMP-002 from Guangzhou Greenfield Houseware Trading','IMP-002','SHIPMENT'),(17,'2026-07-15','Sale INV-000003 - Walk-in Customer','INV-000003','SALE'),(18,'2026-07-16','Non-operating payment - Customs duty (IMP-002)','NOP-000009','EXPENSE'),(19,'2026-07-16','Non-operating payment - Port & clearing charges (IMP-002)','NOP-000010','EXPENSE'),(20,'2026-07-17','Sale INV-000004 - Walk-in Customer','INV-000004','SALE'),(21,'2026-07-17','Sale INV-000005 - Faisal Kitchen Ware','INV-000005','SALE'),(22,'2026-10-27','Payment to supplier Shenzhen Brightway Electronics Co., Ltd','SPY-000001','SUPPLIER_PAYMENT'),(23,'2026-07-21','Sale INV-000006 - Ichhra Super Mart','INV-000006','SALE'),(24,'2026-07-21','Sale INV-000007 - Liberty Home Store','INV-000007','SALE'),(25,'2026-07-23','Sale INV-000008 - Ichhra Super Mart','INV-000008','SALE'),(26,'2026-07-23','Sale INV-000009 - Faisal Kitchen Ware','INV-000009','SALE'),(27,'2026-07-25','Sale INV-000010 - Walk-in Customer','INV-000010','SALE'),(28,'2026-07-25','Sale INV-000011 - Shah Alam Electronics Centre','INV-000011','SALE'),(29,'2026-07-26','Expense - Rent','EXP-000011','EXPENSE'),(30,'2026-07-26','Expense - Salaries','EXP-000012','EXPENSE'),(31,'2026-07-26','Expense - Electricity','EXP-000013','EXPENSE'),(32,'2026-07-27','Sale INV-000012 - Walk-in Customer','INV-000012','SALE'),(33,'2026-07-29','Stock received IMP-003 from Bosphorus Home Textiles A.S.','IMP-003','SHIPMENT'),(34,'2026-07-29','Sale INV-000013 - Liberty Home Store','INV-000013','SALE'),(35,'2026-07-29','Sale INV-000014 - Walk-in Customer','INV-000014','SALE'),(36,'2026-07-31','Non-operating payment - Customs duty (IMP-003)','NOP-000014','EXPENSE'),(37,'2026-07-31','Non-operating payment - Port & clearing charges (IMP-003)','NOP-000015','EXPENSE'),(38,'2026-07-31','Sale INV-000015 - Walk-in Customer','INV-000015','SALE'),(39,'2026-07-31','Sale INV-000016 - Hafeez Mobile Accessories','INV-000016','SALE'),(40,'2026-07-31','Expense - Transport','EXP-000016','EXPENSE'),(41,'2026-07-31','Expense - Loading / unloading','EXP-000017','EXPENSE'),(42,'2026-07-31','Expense - Office expenses','EXP-000018','EXPENSE'),(43,'2026-08-02','Sale INV-000017 - Walk-in Customer','INV-000017','SALE'),(44,'2026-08-04','Sale INV-000018 - Al-Madina Traders','INV-000018','SALE'),(45,'2026-08-04','Sale INV-000019 - Model Town Grocers','INV-000019','SALE'),(46,'2026-08-06','Sale INV-000020 - DHA Cash & Carry','INV-000020','SALE'),(47,'2026-08-06','Sale INV-000021 - Walk-in Customer','INV-000021','SALE'),(48,'2026-08-06','Sale INV-000022 - Brandreth Road Kitchenware','INV-000022','SALE'),(49,'2026-08-08','Sale INV-000023 - DHA Cash & Carry','INV-000023','SALE'),(50,'2026-08-08','Payment received from Al-Madina Traders','RCP-000001','RECEIPT'),(51,'2026-08-10','Sale INV-000024 - Walk-in Customer','INV-000024','SALE'),(52,'2026-08-10','Sale INV-000025 - Rehmat General Store','INV-000025','SALE'),(53,'2026-08-12','Sale INV-000026 - Hafeez Mobile Accessories','INV-000026','SALE'),(54,'2026-08-13','Stock received IMP-004 from Siam Living Products Co., Ltd','IMP-004','SHIPMENT'),(55,'2026-08-14','Sale INV-000027 - Walk-in Customer','INV-000027','SALE'),(56,'2026-08-14','Sale INV-000028 - Walk-in Customer','INV-000028','SALE'),(57,'2026-08-15','Non-operating payment - Customs duty (IMP-004)','NOP-000019','EXPENSE'),(58,'2026-08-15','Non-operating payment - Port & clearing charges (IMP-004)','NOP-000020','EXPENSE'),(59,'2026-08-16','Sale INV-000029 - Walk-in Customer','INV-000029','SALE'),(60,'2026-10-27','Payment to supplier Bosphorus Home Textiles A.S.','SPY-000002','SUPPLIER_PAYMENT'),(61,'2026-08-18','Sale INV-000030 - Al-Madina Traders','INV-000030','SALE'),(62,'2026-08-18','Sale INV-000031 - Walk-in Customer','INV-000031','SALE'),(63,'2026-08-20','Sale INV-000032 - Walk-in Customer','INV-000032','SALE'),(64,'2026-08-20','Sale INV-000033 - Walk-in Customer','INV-000033','SALE'),(65,'2026-08-20','Sale INV-000034 - Walk-in Customer','INV-000034','SALE'),(66,'2026-08-22','Sale INV-000035 - Brandreth Road Kitchenware','INV-000035','SALE'),(67,'2026-08-25','Expense - Rent','EXP-000021','EXPENSE'),(68,'2026-08-25','Expense - Salaries','EXP-000022','EXPENSE'),(69,'2026-08-25','Expense - Electricity','EXP-000023','EXPENSE'),(70,'2026-08-26','Sale INV-000036 - Walk-in Customer','INV-000036','SALE'),(71,'2026-08-28','Stock received IMP-005 from Al Safa General Trading LLC','IMP-005','SHIPMENT'),(72,'2026-08-28','Sale INV-000037 - Johar Town Bedding Centre','INV-000037','SALE'),(73,'2026-08-28','Payment received from Shah Alam Electronics Centre','RCP-000002','RECEIPT'),(74,'2026-08-30','Non-operating payment - Customs duty (IMP-005)','NOP-000024','EXPENSE'),(75,'2026-08-30','Non-operating payment - Port & clearing charges (IMP-005)','NOP-000025','EXPENSE'),(76,'2026-08-30','Sale INV-000038 - Shah Alam Electronics Centre','INV-000038','SALE'),(77,'2026-08-30','Sale INV-000039 - Model Town Grocers','INV-000039','SALE'),(78,'2026-08-30','Sale INV-000040 - Walk-in Customer','INV-000040','SALE'),(79,'2026-08-30','Expense - Transport','EXP-000026','EXPENSE'),(80,'2026-08-30','Expense - Loading / unloading','EXP-000027','EXPENSE'),(81,'2026-08-30','Expense - Office expenses','EXP-000028','EXPENSE'),(82,'2026-09-01','Sale INV-000041 - Walk-in Customer','INV-000041','SALE'),(83,'2026-09-01','Sale INV-000042 - Rehmat General Store','INV-000042','SALE'),(84,'2026-09-01','Sale INV-000043 - Walk-in Customer','INV-000043','SALE'),(85,'2026-09-03','Sale INV-000044 - Walk-in Customer','INV-000044','SALE'),(86,'2026-09-03','Sale INV-000045 - Shah Alam Electronics Centre','INV-000045','SALE'),(87,'2026-09-05','Sale INV-000046 - Brandreth Road Kitchenware','INV-000046','SALE'),(88,'2026-09-05','Sale INV-000047 - Rehmat General Store','INV-000047','SALE'),(89,'2026-09-07','Sale INV-000048 - Hafeez Mobile Accessories','INV-000048','SALE'),(90,'2026-09-07','Payment received from Liberty Home Store','RCP-000003','RECEIPT'),(91,'2026-09-09','Sale INV-000049 - Walk-in Customer','INV-000049','SALE'),(92,'2026-09-09','Sale INV-000050 - Shah Alam Electronics Centre','INV-000050','SALE'),(93,'2026-09-11','Sale INV-000051 - Walk-in Customer','INV-000051','SALE'),(94,'2026-09-11','Sale INV-000052 - Walk-in Customer','INV-000052','SALE'),(95,'2026-09-12','Stock received IMP-006 from Pinnacle Oleo & Home Care Sdn Bhd','IMP-006','SHIPMENT'),(96,'2026-09-13','Sale INV-000053 - Model Town Grocers','INV-000053','SALE'),(97,'2026-09-13','Sale INV-000054 - Brandreth Road Kitchenware','INV-000054','SALE'),(98,'2026-09-13','Sale INV-000055 - Walk-in Customer','INV-000055','SALE'),(99,'2026-09-14','Non-operating payment - Customs duty (IMP-006)','NOP-000029','EXPENSE'),(100,'2026-09-14','Non-operating payment - Port & clearing charges (IMP-006)','NOP-000030','EXPENSE'),(101,'2026-09-15','Sale INV-000056 - Walk-in Customer','INV-000056','SALE'),(102,'2026-09-15','Sale INV-000057 - Shah Alam Electronics Centre','INV-000057','SALE'),(103,'2026-09-15','Sale INV-000058 - Shah Alam Electronics Centre','INV-000058','SALE'),(104,'2026-09-15','Payment received from Brandreth Road Kitchenware','RCP-000004','RECEIPT'),(105,'2026-10-27','Payment to supplier Al Safa General Trading LLC','SPY-000003','SUPPLIER_PAYMENT'),(106,'2026-09-17','Sale INV-000059 - Walk-in Customer','INV-000059','SALE'),(107,'2026-09-17','Sale INV-000060 - Hafeez Mobile Accessories','INV-000060','SALE'),(108,'2026-09-17','Stock adjustment (damaged) TCLU8830912-04: 3 sets broken during unloading from container','ADJ-000001','STOCK_ADJ'),(109,'2026-09-19','Sale INV-000061 - Model Town Grocers','INV-000061','SALE'),(110,'2026-09-19','Sale INV-000062 - Model Town Grocers','INV-000062','SALE'),(111,'2026-09-19','Sale INV-000063 - Walk-in Customer','INV-000063','SALE'),(112,'2026-09-19','Stock adjustment (missing) OOLU3392760-02: Shortage found on counting - 8 kg short against packing list','ADJ-000002','STOCK_ADJ'),(113,'2026-09-21','Sale INV-000064 - Walk-in Customer','INV-000064','SALE'),(114,'2026-09-21','Sale INV-000065 - Walk-in Customer','INV-000065','SALE'),(115,'2026-09-23','Sale INV-000066 - Walk-in Customer','INV-000066','SALE'),(116,'2026-09-23','Sale INV-000067 - Faisal Kitchen Ware','INV-000067','SALE'),(117,'2026-09-24','Payment received from Al-Madina Traders','RCP-000005','RECEIPT'),(118,'2026-09-24','Expense - Rent','EXP-000031','EXPENSE'),(119,'2026-09-24','Expense - Salaries','EXP-000032','EXPENSE'),(120,'2026-09-24','Expense - Electricity','EXP-000033','EXPENSE'),(121,'2026-09-25','Sale INV-000068 - Shah Alam Electronics Centre','INV-000068','SALE'),(122,'2026-09-25','Sale INV-000069 - Walk-in Customer','INV-000069','SALE'),(123,'2026-09-27','Sale INV-000070 - Rehmat General Store','INV-000070','SALE'),(124,'2026-09-27','Sale INV-000071 - DHA Cash & Carry','INV-000071','SALE'),(125,'2026-09-27','Sale INV-000072 - Liberty Home Store','INV-000072','SALE'),(126,'2026-09-27','Sales return SRN-000001 against INV-000030','SRN-000001','RETURN'),(127,'2026-09-29','Sale INV-000073 - Al-Noor Attar House','INV-000073','SALE'),(128,'2026-09-29','Sale INV-000074 - Walk-in Customer','INV-000074','SALE'),(129,'2026-09-29','Sale INV-000075 - Hafeez Mobile Accessories','INV-000075','SALE'),(130,'2026-09-29','Payment received from Hafeez Mobile Accessories','RCP-000006','RECEIPT'),(131,'2026-09-29','Expense - Transport','EXP-000034','EXPENSE'),(132,'2026-09-29','Expense - Loading / unloading','EXP-000035','EXPENSE'),(133,'2026-09-29','Expense - Office expenses','EXP-000036','EXPENSE'),(134,'2026-10-01','Sale INV-000076 - Walk-in Customer','INV-000076','SALE'),(135,'2026-10-01','Sale INV-000077 - Faisal Kitchen Ware','INV-000077','SALE'),(136,'2026-10-01','Sale INV-000078 - Johar Town Bedding Centre','INV-000078','SALE'),(137,'2026-10-02','Stock received IMP-007 from Shenzhen Brightway Electronics Co., Ltd','IMP-007','SHIPMENT'),(138,'2026-10-03','Sale INV-000079 - DHA Cash & Carry','INV-000079','SALE'),(139,'2026-10-03','Sale INV-000080 - Walk-in Customer','INV-000080','SALE'),(140,'2026-10-03','Sale INV-000081 - Model Town Grocers','INV-000081','SALE'),(141,'2026-10-05','Sale INV-000082 - Brandreth Road Kitchenware','INV-000082','SALE'),(142,'2026-10-05','Sale INV-000083 - Rehmat General Store','INV-000083','SALE'),(143,'2026-10-07','Sale INV-000084 - Brandreth Road Kitchenware','INV-000084','SALE'),(144,'2026-10-07','Sale INV-000085 - Walk-in Customer','INV-000085','SALE'),(145,'2026-10-07','Expense - Repairs','EXP-000037','EXPENSE'),(146,'2026-10-09','Sale INV-000086 - Rehmat General Store','INV-000086','SALE'),(147,'2026-10-09','Sale INV-000087 - Liberty Home Store','INV-000087','SALE'),(148,'2026-10-09','Sale INV-000088 - Walk-in Customer','INV-000088','SALE'),(149,'2026-10-11','Sale INV-000089 - Al-Madina Traders','INV-000089','SALE'),(150,'2026-10-11','Sale INV-000090 - Shah Alam Electronics Centre','INV-000090','SALE'),(151,'2026-10-27','Payment to supplier Pinnacle Oleo & Home Care Sdn Bhd','SPY-000004','SUPPLIER_PAYMENT'),(152,'2026-10-13','Sale INV-000091 - Liberty Home Store','INV-000091','SALE'),(153,'2026-10-13','Sale INV-000092 - Model Town Grocers','INV-000092','SALE'),(154,'2026-10-13','Payment received from Shah Alam Electronics Centre','RCP-000007','RECEIPT'),(155,'2026-10-15','Stock received IMP-008 from Guangzhou Greenfield Houseware Trading','IMP-008','SHIPMENT'),(156,'2026-10-15','Sale INV-000093 - Walk-in Customer','INV-000093','SALE'),(157,'2026-10-15','Sale INV-000094 - Walk-in Customer','INV-000094','SALE'),(158,'2026-10-15','Sale INV-000095 - Walk-in Customer','INV-000095','SALE'),(159,'2026-10-17','Sale INV-000096 - Walk-in Customer','INV-000096','SALE'),(160,'2026-10-17','Sale INV-000097 - Shah Alam Electronics Centre','INV-000097','SALE'),(161,'2026-10-17','Sale INV-000098 - Brandreth Road Kitchenware','INV-000098','SALE'),(162,'2026-10-17','Expense - Bank charges','EXP-000038','EXPENSE'),(163,'2026-10-18','Payment received from Rehmat General Store','RCP-000008','RECEIPT'),(164,'2026-10-19','Sale INV-000099 - Ichhra Super Mart','INV-000099','SALE'),(165,'2026-10-19','Sale INV-000100 - Rehmat General Store','INV-000100','SALE'),(166,'2026-10-19','Cash/bank paid - drawings: Owner drawings','CP-000003','VOUCHER'),(167,'2026-10-21','Sale INV-000101 - Johar Town Bedding Centre','INV-000101','SALE'),(168,'2026-10-21','Sale INV-000102 - Walk-in Customer','INV-000102','SALE'),(169,'2026-10-21','Sale INV-000103 - Al-Madina Traders','INV-000103','SALE'),(170,'2026-10-21','Cash/bank received - other income: Scrap sale - packing material','CR-000004','VOUCHER'),(171,'2026-10-22','Payment received from Johar Town Bedding Centre','RCP-000009','RECEIPT'),(172,'2026-10-23','Sale INV-000104 - Johar Town Bedding Centre','INV-000104','SALE'),(173,'2026-10-23','Sale INV-000105 - Faisal Kitchen Ware','INV-000105','SALE'),(174,'2026-10-23','Sale INV-000106 - Johar Town Bedding Centre','INV-000106','SALE'),(175,'2026-10-24','Expense - Rent','EXP-000039','EXPENSE'),(176,'2026-10-24','Expense - Salaries','EXP-000040','EXPENSE'),(177,'2026-10-24','Expense - Electricity','EXP-000041','EXPENSE'),(178,'2026-10-25','Sale INV-000107 - Al-Madina Traders','INV-000107','SALE'),(179,'2026-10-25','Sale INV-000108 - Al-Noor Attar House','INV-000108','SALE'),(180,'2026-10-29','Expense - Transport','EXP-000042','EXPENSE'),(181,'2026-10-29','Expense - Loading / unloading','EXP-000043','EXPENSE'),(182,'2026-10-29','Expense - Office expenses','EXP-000044','EXPENSE'),(183,'2026-10-27','Stock received SHP-000001 from Guangzhou Greenfield Houseware Trading','SHP-000001','SHIPMENT'),(184,'2026-10-27','Non-operating payment - Customs duty (SHP-000001)','NOP-000045','EXPENSE'),(185,'2026-10-27','Sale INV-000109 - Walk-in Customer','INV-000109','SALE'),(186,'2026-10-30','Stock received RN00212 from Al Safa General Trading LLC','RN00212','SHIPMENT'),(187,'2026-10-30','Sale INV-000110 - Liberty Home Store','INV-000110','SALE'),(188,'2026-10-30','Sales return SRN-000002 against INV-000110','SRN-000002','RETURN'),(189,'2026-10-30','Sale INV-000111 - Walk-in Customer','INV-000111','SALE'),(190,'2026-10-30','Stock received BOL-20235 from Al Safa General Trading LLC','BOL-20235','SHIPMENT'),(191,'2026-10-30','Non-operating payment - Customs duty (BOL-20235)','NOP-000046','EXPENSE'),(192,'2026-10-30','Sale INV-000112 - Al-Madina Traders','INV-000112','SALE'),(193,'2026-10-30','Sales return SRN-000003 against INV-000112','SRN-000003','RETURN'),(194,'2026-10-30','Payment received from Al-Madina Traders','RCP-000010','RECEIPT'),(195,'2026-10-30','Stock received BL-007 from Al Safa General Trading LLC','BL-007','SHIPMENT'),(196,'2026-10-30','Stock adjustment (correction) 05-01: Stock Counting was revalued','ADJ-000003','STOCK_ADJ'),(197,'2026-10-27','Opening balance - Charag Deen Enterprises','CUS-000001','OPENING_CUSTOMER'),(198,'2026-10-30','Sale INV-000113 - Charag Deen Enterprises','INV-000113','SALE'),(199,'2026-10-30','Sales return SRN-000004 against INV-000113','SRN-000004','RETURN'),(200,'2026-10-31','Sale INV-000114 - Charag Deen Enterprises','INV-000114','SALE'),(201,'2026-10-31','Sales return SRN-000005 against INV-000114','SRN-000005','RETURN'),(202,'2026-10-31','Payment to supplier Al Safa General Trading LLC','SPY-000005','SUPPLIER_PAYMENT'),(203,'2026-10-31','Payment to supplier Al Safa General Trading LLC','SPY-000006','SUPPLIER_PAYMENT'),(204,'2026-10-31','Expense - Salaries','EXP-000047','EXPENSE'),(205,'2026-10-27','Opening balance - Meezan Bank Limited','ACC-5','OPENING_ACCOUNT'),(206,'2026-11-05','Stock received SHP-002 from Shenzhen Brightway Electronics Co., Ltd','SHP-002','SHIPMENT'),(207,'2026-11-05','Non-operating payment - Customs duty (SHP-002)','NOP-000048','EXPENSE'),(208,'2026-11-05','Sale INV-000115 - Walk-in Customer','INV-000115','SALE');

/*Table structure for table `mis_journal_line` */

DROP TABLE IF EXISTS `mis_journal_line`;

CREATE TABLE `mis_journal_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `credit` decimal(18,2) NOT NULL,
  `debit` decimal(18,2) NOT NULL,
  `head_code` varchar(16) NOT NULL,
  `journal_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `IDXt4ypivvu7ayl0bw7vi8yb3dxu` (`head_code`),
  KEY `FK230ba8r2ctywgf7tasyut4lef` (`journal_id`),
  CONSTRAINT `FK230ba8r2ctywgf7tasyut4lef` FOREIGN KEY (`journal_id`) REFERENCES `mis_journal` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=693 DEFAULT CHARSET=utf8;

/*Data for the table `mis_journal_line` */

insert  into `mis_journal_line`(`id`,`credit`,`debit`,`head_code`,`journal_id`) values (1,'0.00','85000.00','1200',1),(2,'85000.00','0.00','3900',1),(3,'0.00','42500.00','1200',2),(4,'42500.00','0.00','3900',2),(5,'0.00','60000000.00','ACC-2',3),(6,'60000000.00','0.00','3200',3),(7,'0.00','1500000.00','ACC-1',4),(8,'1500000.00','0.00','ACC-2',4),(9,'0.00','185000.00','EXP-4',5),(10,'185000.00','0.00','ACC-2',5),(11,'0.00','420000.00','EXP-2',6),(12,'420000.00','0.00','ACC-2',6),(13,'0.00','68494.00','EXP-3',7),(14,'68494.00','0.00','ACC-1',7),(15,'0.00','3524000.00','1300',8),(16,'1800000.00','0.00','2100',8),(17,'1724000.00','0.00','3100',8),(18,'0.00','1150000.00','1400',9),(19,'1150000.00','0.00','ACC-2',9),(20,'0.00','235000.00','1400',10),(21,'235000.00','0.00','ACC-2',10),(22,'0.00','48767.00','EXP-5',11),(23,'48767.00','0.00','ACC-1',11),(24,'0.00','26551.00','EXP-7',12),(25,'26551.00','0.00','ACC-1',12),(26,'0.00','12301.00','EXP-8',13),(27,'12301.00','0.00','ACC-1',13),(28,'0.00','212000.00','ACC-1',14),(29,'212000.00','0.00','4000',14),(30,'0.00','208000.00','5000',14),(31,'208000.00','0.00','1300',14),(32,'0.00','580.00','ACC-1',15),(33,'580.00','0.00','4000',15),(34,'0.00','370.00','5000',15),(35,'370.00','0.00','1300',15),(36,'0.00','4297000.00','1300',16),(37,'4297000.00','0.00','3100',16),(38,'0.00','1350.00','ACC-1',17),(39,'1350.00','0.00','4000',17),(40,'0.00','495.00','5000',17),(41,'495.00','0.00','1300',17),(42,'0.00','1420000.00','1400',18),(43,'1420000.00','0.00','ACC-2',18),(44,'0.00','310000.00','1400',19),(45,'310000.00','0.00','ACC-2',19),(46,'0.00','1800.00','ACC-1',20),(47,'1800.00','0.00','4000',20),(48,'0.00','660.00','5000',20),(49,'660.00','0.00','1300',20),(50,'0.00','110400.00','ACC-1',21),(51,'0.00','110400.00','1200',21),(52,'220800.00','0.00','4000',21),(53,'0.00','172000.00','5000',21),(54,'172000.00','0.00','1300',21),(55,'0.00','1000000.00','2100',22),(56,'1000000.00','0.00','ACC-2',22),(57,'0.00','98000.00','ACC-1',23),(58,'98000.00','0.00','4000',23),(59,'0.00','74000.00','5000',23),(60,'74000.00','0.00','1300',23),(61,'0.00','99600.00','1200',24),(62,'99600.00','0.00','4000',24),(63,'0.00','156000.00','5000',24),(64,'156000.00','0.00','1300',24),(65,'0.00','23400.00','ACC-2',25),(66,'23400.00','0.00','4000',25),(67,'0.00','17500.00','5000',25),(68,'17500.00','0.00','1300',25),(69,'0.00','47700.00','ACC-1',26),(70,'0.00','111300.00','1200',26),(71,'159000.00','0.00','4000',26),(72,'0.00','156000.00','5000',26),(73,'156000.00','0.00','1300',26),(74,'0.00','2700.00','ACC-1',27),(75,'2700.00','0.00','4000',27),(76,'0.00','1291.67','5000',27),(77,'1291.67','0.00','1300',27),(78,'0.00','15900.00','ACC-2',28),(79,'0.00','37100.00','1200',28),(80,'53000.00','0.00','4000',28),(81,'0.00','52000.00','5000',28),(82,'52000.00','0.00','1300',28),(83,'0.00','185000.00','EXP-4',29),(84,'185000.00','0.00','ACC-2',29),(85,'0.00','420000.00','EXP-2',30),(86,'420000.00','0.00','ACC-2',30),(87,'0.00','70113.00','EXP-3',31),(88,'70113.00','0.00','ACC-1',31),(89,'0.00','1350.00','ACC-2',32),(90,'1350.00','0.00','4000',32),(91,'0.00','495.00','5000',32),(92,'495.00','0.00','1300',32),(93,'0.00','4817500.00','1300',33),(94,'2500000.00','0.00','2100',33),(95,'2317500.00','0.00','3100',33),(96,'0.00','53000.00','ACC-2',34),(97,'53000.00','0.00','4000',34),(98,'0.00','52000.00','5000',34),(99,'52000.00','0.00','1300',34),(100,'0.00','1350.00','ACC-2',35),(101,'1350.00','0.00','4000',35),(102,'0.00','645.83','5000',35),(103,'645.83','0.00','1300',35),(104,'0.00','1680000.00','1400',36),(105,'1680000.00','0.00','ACC-2',36),(106,'0.00','350000.00','1400',37),(107,'350000.00','0.00','ACC-2',37),(108,'0.00','9600.00','ACC-2',38),(109,'9600.00','0.00','4000',38),(110,'0.00','7800.00','5000',38),(111,'7800.00','0.00','1300',38),(112,'0.00','62100.00','ACC-1',39),(113,'0.00','144900.00','1200',39),(114,'207000.00','0.00','4000',39),(115,'0.00','165000.01','5000',39),(116,'165000.01','0.00','1300',39),(117,'0.00','41884.00','EXP-5',40),(118,'41884.00','0.00','ACC-1',40),(119,'0.00','24146.00','EXP-7',41),(120,'24146.00','0.00','ACC-1',41),(121,'0.00','10868.00','EXP-8',42),(122,'10868.00','0.00','ACC-1',42),(123,'0.00','12800.00','ACC-1',43),(124,'12800.00','0.00','4000',43),(125,'0.00','10400.00','5000',43),(126,'10400.00','0.00','1300',43),(127,'0.00','32000.00','1200',44),(128,'32000.00','0.00','4000',44),(129,'0.00','21500.00','5000',44),(130,'21500.00','0.00','1300',44),(131,'0.00','138000.00','1200',45),(132,'138000.00','0.00','4000',45),(133,'0.00','110000.00','5000',45),(134,'110000.00','0.00','1300',45),(135,'0.00','31800.00','ACC-1',46),(136,'0.00','74200.00','1200',46),(137,'106000.00','0.00','4000',46),(138,'0.00','104000.00','5000',46),(139,'104000.00','0.00','1300',46),(140,'0.00','900.00','ACC-2',47),(141,'900.00','0.00','4000',47),(142,'0.00','330.00','5000',47),(143,'330.00','0.00','1300',47),(144,'0.00','33200.00','1200',48),(145,'33200.00','0.00','4000',48),(146,'0.00','52000.00','5000',48),(147,'52000.00','0.00','1300',48),(148,'0.00','66930.00','1200',49),(149,'66930.00','0.00','4000',49),(150,'0.00','55000.00','5000',49),(151,'55000.00','0.00','1300',49),(152,'0.00','117000.00','ACC-2',50),(153,'117000.00','0.00','1200',50),(154,'0.00','870.00','ACC-2',51),(155,'870.00','0.00','4000',51),(156,'0.00','555.00','5000',51),(157,'555.00','0.00','1300',51),(158,'0.00','128816.00','ACC-1',52),(159,'128816.00','0.00','4000',52),(160,'0.00','208000.00','5000',52),(161,'208000.00','0.00','1300',52),(162,'0.00','6809.00','ACC-1',53),(163,'0.00','15889.00','1200',53),(164,'22698.00','0.00','4000',53),(165,'0.00','17500.00','5000',53),(166,'17500.00','0.00','1300',53),(167,'0.00','1423000.00','1300',54),(168,'1423000.00','0.00','3100',54),(169,'0.00','1160.00','ACC-2',55),(170,'1160.00','0.00','4000',55),(171,'0.00','740.00','5000',55),(172,'740.00','0.00','1300',55),(173,'0.00','9600.00','ACC-2',56),(174,'9600.00','0.00','4000',56),(175,'0.00','7800.00','5000',56),(176,'7800.00','0.00','1300',56),(177,'0.00','760000.00','1400',57),(178,'760000.00','0.00','ACC-2',57),(179,'0.00','190000.00','1400',58),(180,'190000.00','0.00','ACC-2',58),(181,'0.00','2800.00','ACC-1',59),(182,'2800.00','0.00','4000',59),(183,'0.00','1791.67','5000',59),(184,'1791.67','0.00','1300',59),(185,'0.00','1500000.00','2100',60),(186,'1500000.00','0.00','ACC-2',60),(187,'0.00','23400.00','ACC-1',61),(188,'0.00','23400.00','1200',61),(189,'46800.00','0.00','4000',61),(190,'0.00','35000.00','5000',61),(191,'35000.00','0.00','1300',61),(192,'0.00','6400.00','ACC-2',62),(193,'6400.00','0.00','4000',62),(194,'0.00','5200.00','5000',62),(195,'5200.00','0.00','1300',62),(196,'0.00','450.00','ACC-2',63),(197,'450.00','0.00','4000',63),(198,'0.00','165.00','5000',63),(199,'165.00','0.00','1300',63),(200,'0.00','9600.00','ACC-1',64),(201,'9600.00','0.00','4000',64),(202,'0.00','5833.33','5000',64),(203,'5833.33','0.00','1300',64),(204,'0.00','3450.00','ACC-1',65),(205,'3450.00','0.00','4000',65),(206,'0.00','2450.00','5000',65),(207,'2450.00','0.00','1300',65),(208,'0.00','32640.00','1200',66),(209,'32640.00','0.00','4000',66),(210,'0.00','17200.00','5000',66),(211,'17200.00','0.00','1300',66),(212,'0.00','185000.00','EXP-4',67),(213,'185000.00','0.00','ACC-2',67),(214,'0.00','420000.00','EXP-2',68),(215,'420000.00','0.00','ACC-2',68),(216,'0.00','77171.00','EXP-3',69),(217,'77171.00','0.00','ACC-1',69),(218,'0.00','1160.00','ACC-1',70),(219,'1160.00','0.00','4000',70),(220,'0.00','740.00','5000',70),(221,'740.00','0.00','1300',70),(222,'0.00','3452000.00','1300',71),(223,'900000.00','0.00','2100',71),(224,'2552000.00','0.00','3100',71),(225,'0.00','103680.00','ACC-2',72),(226,'0.00','103680.00','1200',72),(227,'207360.00','0.00','4000',72),(228,'0.00','123999.99','5000',72),(229,'123999.99','0.00','1300',72),(230,'0.00','37100.00','ACC-2',73),(231,'37100.00','0.00','1200',73),(232,'0.00','940000.00','1400',74),(233,'940000.00','0.00','ACC-2',74),(234,'0.00','205000.00','1400',75),(235,'205000.00','0.00','ACC-2',75),(236,'0.00','31661.00','ACC-1',76),(237,'31661.00','0.00','4000',76),(238,'0.00','17200.00','5000',76),(239,'17200.00','0.00','1300',76),(240,'0.00','720000.00','ACC-2',77),(241,'720000.00','0.00','4000',77),(242,'0.00','600000.02','5000',77),(243,'600000.02','0.00','1300',77),(244,'0.00','290.00','ACC-2',78),(245,'290.00','0.00','4000',78),(246,'0.00','185.00','5000',78),(247,'185.00','0.00','1300',78),(248,'0.00','48531.00','EXP-5',79),(249,'48531.00','0.00','ACC-1',79),(250,'0.00','28842.00','EXP-7',80),(251,'28842.00','0.00','ACC-1',80),(252,'0.00','13071.00','EXP-8',81),(253,'13071.00','0.00','ACC-1',81),(254,'0.00','15600.00','ACC-2',82),(255,'15600.00','0.00','4000',82),(256,'0.00','8600.00','5000',82),(257,'8600.00','0.00','1300',82),(258,'0.00','32000.00','ACC-1',83),(259,'32000.00','0.00','4000',83),(260,'0.00','21500.00','5000',83),(261,'21500.00','0.00','1300',83),(262,'0.00','7200.00','ACC-2',84),(263,'7200.00','0.00','4000',84),(264,'0.00','4375.00','5000',84),(265,'4375.00','0.00','1300',84),(266,'0.00','4600.00','ACC-1',85),(267,'4600.00','0.00','4000',85),(268,'0.00','3062.50','5000',85),(269,'3062.50','0.00','1300',85),(270,'0.00','35100.00','ACC-2',86),(271,'0.00','35100.00','1200',86),(272,'70200.00','0.00','4000',86),(273,'0.00','52500.00','5000',86),(274,'52500.00','0.00','1300',86),(275,'0.00','49000.00','1200',87),(276,'49000.00','0.00','4000',87),(277,'0.00','37000.00','5000',87),(278,'37000.00','0.00','1300',87),(279,'0.00','108000.00','ACC-1',88),(280,'0.00','252000.00','1200',88),(281,'360000.00','0.00','4000',88),(282,'0.00','300000.01','5000',88),(283,'300000.01','0.00','1300',88),(284,'0.00','133860.00','ACC-1',89),(285,'133860.00','0.00','4000',89),(286,'0.00','110000.00','5000',89),(287,'110000.00','0.00','1300',89),(288,'0.00','99600.00','ACC-2',90),(289,'99600.00','0.00','1200',90),(290,'0.00','1800.00','ACC-1',91),(291,'1800.00','0.00','4000',91),(292,'0.00','660.00','5000',91),(293,'660.00','0.00','1300',91),(294,'0.00','96612.00','1200',92),(295,'96612.00','0.00','4000',92),(296,'0.00','156000.00','5000',92),(297,'156000.00','0.00','1300',92),(298,'0.00','15600.00','ACC-1',93),(299,'15600.00','0.00','4000',93),(300,'0.00','8600.00','5000',93),(301,'8600.00','0.00','1300',93),(302,'0.00','4600.00','ACC-1',94),(303,'4600.00','0.00','4000',94),(304,'0.00','3062.50','5000',94),(305,'3062.50','0.00','1300',94),(306,'0.00','2684000.00','1300',95),(307,'1200000.00','0.00','2100',95),(308,'1484000.00','0.00','3100',95),(309,'0.00','24480.00','ACC-1',96),(310,'24480.00','0.00','4000',96),(311,'0.00','12900.00','5000',96),(312,'12900.00','0.00','1300',96),(313,'0.00','23400.00','ACC-2',97),(314,'23400.00','0.00','4000',97),(315,'0.00','17500.00','5000',97),(316,'17500.00','0.00','1300',97),(317,'0.00','29400.00','ACC-1',98),(318,'29400.00','0.00','4000',98),(319,'0.00','39000.00','5000',98),(320,'39000.00','0.00','1300',98),(321,'0.00','1050000.00','1400',99),(322,'1050000.00','0.00','ACC-2',99),(323,'0.00','260000.00','1400',100),(324,'260000.00','0.00','ACC-2',100),(325,'0.00','7400.00','ACC-2',101),(326,'7400.00','0.00','4000',101),(327,'0.00','4720.00','5000',101),(328,'4720.00','0.00','1300',101),(329,'0.00','32000.00','ACC-2',102),(330,'0.00','32000.00','1200',102),(331,'64000.00','0.00','4000',102),(332,'0.00','43000.00','5000',102),(333,'43000.00','0.00','1300',102),(334,'0.00','5820.00','ACC-1',103),(335,'5820.00','0.00','4000',103),(336,'0.00','5500.00','5000',103),(337,'5500.00','0.00','1300',103),(338,'0.00','114840.00','ACC-1',104),(339,'114840.00','0.00','1200',104),(340,'0.00','500000.00','2100',105),(341,'500000.00','0.00','ACC-2',105),(342,'0.00','2360.00','ACC-1',106),(343,'2360.00','0.00','4000',106),(344,'0.00','1833.33','5000',106),(345,'1833.33','0.00','1300',106),(346,'0.00','32000.00','ACC-2',107),(347,'0.00','32000.00','1200',107),(348,'64000.00','0.00','4000',107),(349,'0.00','43000.00','5000',107),(350,'43000.00','0.00','1300',107),(351,'0.00','39000.00','5100',108),(352,'39000.00','0.00','1300',108),(353,'0.00','22080.00','ACC-2',109),(354,'22080.00','0.00','4000',109),(355,'0.00','19600.00','5000',109),(356,'19600.00','0.00','1300',109),(357,'0.00','24500.00','1200',110),(358,'24500.00','0.00','4000',110),(359,'0.00','18500.00','5000',110),(360,'18500.00','0.00','1300',110),(361,'0.00','5400.00','ACC-2',111),(362,'5400.00','0.00','4000',111),(363,'0.00','2583.33','5000',111),(364,'2583.33','0.00','1300',111),(365,'0.00','9440.00','5100',112),(366,'9440.00','0.00','1300',112),(367,'0.00','4350.00','ACC-2',113),(368,'4350.00','0.00','4000',113),(369,'0.00','2750.00','5000',113),(370,'2750.00','0.00','1300',113),(371,'0.00','11700.00','ACC-1',114),(372,'11700.00','0.00','4000',114),(373,'0.00','6450.00','5000',114),(374,'6450.00','0.00','1300',114),(375,'0.00','2700.00','ACC-1',115),(376,'2700.00','0.00','4000',115),(377,'0.00','1291.67','5000',115),(378,'1291.67','0.00','1300',115),(379,'0.00','121600.00','1200',116),(380,'121600.00','0.00','4000',116),(381,'0.00','98000.00','5000',116),(382,'98000.00','0.00','1300',116),(383,'0.00','23400.00','ACC-2',117),(384,'23400.00','0.00','1200',117),(385,'0.00','185000.00','EXP-4',118),(386,'185000.00','0.00','ACC-2',118),(387,'0.00','420000.00','EXP-2',119),(388,'420000.00','0.00','ACC-2',119),(389,'0.00','69894.00','EXP-3',120),(390,'69894.00','0.00','ACC-1',120),(391,'0.00','17460.00','1200',121),(392,'17460.00','0.00','4000',121),(393,'0.00','16500.00','5000',121),(394,'16500.00','0.00','1300',121),(395,'0.00','5800.00','ACC-1',122),(396,'5800.00','0.00','4000',122),(397,'0.00','3666.67','5000',122),(398,'3666.67','0.00','1300',122),(399,'0.00','24500.00','1200',123),(400,'24500.00','0.00','4000',123),(401,'0.00','18500.00','5000',123),(402,'18500.00','0.00','1300',123),(403,'0.00','288000.00','ACC-1',124),(404,'288000.00','0.00','4000',124),(405,'0.00','132000.00','5000',124),(406,'132000.00','0.00','1300',124),(407,'0.00','276000.00','1200',125),(408,'276000.00','0.00','4000',125),(409,'0.00','220000.01','5000',125),(410,'220000.01','0.00','1300',125),(411,'0.00','23400.00','4100',126),(412,'23400.00','0.00','1200',126),(413,'0.00','17500.00','1300',126),(414,'17500.00','0.00','5000',126),(415,'0.00','18240.00','ACC-2',127),(416,'0.00','42560.00','1200',127),(417,'60800.00','0.00','4000',127),(418,'0.00','49000.00','5000',127),(419,'49000.00','0.00','1300',127),(420,'0.00','290.00','ACC-1',128),(421,'290.00','0.00','4000',128),(422,'0.00','185.00','5000',128),(423,'185.00','0.00','1300',128),(424,'0.00','15500.00','ACC-1',129),(425,'0.00','15500.00','1200',129),(426,'31000.00','0.00','4000',129),(427,'0.00','23600.00','5000',129),(428,'23600.00','0.00','1300',129),(429,'0.00','120000.00','ACC-2',130),(430,'120000.00','0.00','1200',130),(431,'0.00','52720.00','EXP-5',131),(432,'52720.00','0.00','ACC-1',131),(433,'0.00','25812.00','EXP-7',132),(434,'25812.00','0.00','ACC-1',132),(435,'0.00','13335.00','EXP-8',133),(436,'13335.00','0.00','ACC-1',133),(437,'0.00','590.00','ACC-1',134),(438,'590.00','0.00','4000',134),(439,'0.00','458.33','5000',134),(440,'458.33','0.00','1300',134),(441,'0.00','90000.00','ACC-2',135),(442,'0.00','90000.00','1200',135),(443,'180000.00','0.00','4000',135),(444,'0.00','150000.00','5000',135),(445,'150000.00','0.00','1300',135),(446,'0.00','4080.00','ACC-2',136),(447,'0.00','4080.00','1200',136),(448,'8160.00','0.00','4000',136),(449,'0.00','4300.00','5000',136),(450,'4300.00','0.00','1300',136),(451,'0.00','2910500.00','1300',137),(452,'2910500.00','0.00','3100',137),(453,'0.00','51840.00','ACC-2',138),(454,'0.00','51840.00','1200',138),(455,'103680.00','0.00','4000',138),(456,'0.00','62000.00','5000',138),(457,'62000.00','0.00','1300',138),(458,'0.00','4050.00','ACC-2',139),(459,'4050.00','0.00','4000',139),(460,'0.00','1937.50','5000',139),(461,'1937.50','0.00','1300',139),(462,'0.00','48000.00','ACC-1',140),(463,'0.00','48000.00','1200',140),(464,'96000.00','0.00','4000',140),(465,'0.00','64500.00','5000',140),(466,'64500.00','0.00','1300',140),(467,'0.00','7750.00','ACC-2',141),(468,'0.00','7750.00','1200',141),(469,'15500.00','0.00','4000',141),(470,'0.00','11800.00','5000',141),(471,'11800.00','0.00','1300',141),(472,'0.00','23280.00','ACC-2',142),(473,'23280.00','0.00','4000',142),(474,'0.00','22000.00','5000',142),(475,'22000.00','0.00','1300',142),(476,'0.00','55200.00','ACC-1',143),(477,'55200.00','0.00','4000',143),(478,'0.00','43000.00','5000',143),(479,'43000.00','0.00','1300',143),(480,'0.00','5400.00','ACC-2',144),(481,'5400.00','0.00','4000',144),(482,'0.00','2583.33','5000',144),(483,'2583.33','0.00','1300',144),(484,'0.00','28000.00','EXP-9',145),(485,'28000.00','0.00','ACC-1',145),(486,'0.00','108000.00','ACC-1',146),(487,'0.00','252000.00','1200',146),(488,'360000.00','0.00','4000',146),(489,'0.00','300000.01','5000',146),(490,'300000.01','0.00','1300',146),(491,'0.00','53000.00','ACC-2',147),(492,'53000.00','0.00','4000',147),(493,'0.00','54000.00','5000',147),(494,'54000.00','0.00','1300',147),(495,'0.00','39200.00','ACC-1',148),(496,'39200.00','0.00','4000',148),(497,'0.00','52000.00','5000',148),(498,'52000.00','0.00','1300',148),(499,'0.00','110400.00','ACC-1',149),(500,'110400.00','0.00','4000',149),(501,'0.00','86000.00','5000',149),(502,'86000.00','0.00','1300',149),(503,'0.00','207000.00','ACC-1',150),(504,'207000.00','0.00','4000',150),(505,'0.00','165000.01','5000',150),(506,'165000.01','0.00','1300',150),(507,'0.00','700000.00','2100',151),(508,'700000.00','0.00','ACC-2',151),(509,'0.00','33200.00','ACC-1',152),(510,'33200.00','0.00','4000',152),(511,'0.00','52000.00','5000',152),(512,'52000.00','0.00','1300',152),(513,'0.00','7750.00','ACC-1',153),(514,'0.00','7750.00','1200',153),(515,'15500.00','0.00','4000',153),(516,'0.00','11800.00','5000',153),(517,'11800.00','0.00','1300',153),(518,'0.00','181172.00','ACC-2',154),(519,'181172.00','0.00','1200',154),(520,'0.00','2707000.00','1300',155),(521,'1100000.00','0.00','2100',155),(522,'1607000.00','0.00','3100',155),(523,'0.00','4950.00','ACC-1',156),(524,'4950.00','0.00','4000',156),(525,'0.00','3125.00','5000',156),(526,'3125.00','0.00','1300',156),(527,'0.00','1260.00','ACC-2',157),(528,'1260.00','0.00','4000',157),(529,'0.00','537.50','5000',157),(530,'537.50','0.00','1300',157),(531,'0.00','5800.00','ACC-1',158),(532,'5800.00','0.00','4000',158),(533,'0.00','3666.67','5000',158),(534,'3666.67','0.00','1300',158),(535,'0.00','8400.00','ACC-2',159),(536,'8400.00','0.00','4000',159),(537,'0.00','5375.00','5000',159),(538,'5375.00','0.00','1300',159),(539,'0.00','9300.00','ACC-2',160),(540,'0.00','21700.00','1200',160),(541,'31000.00','0.00','4000',160),(542,'0.00','23600.00','5000',160),(543,'23600.00','0.00','1300',160),(544,'0.00','11040.00','1200',161),(545,'11040.00','0.00','4000',161),(546,'0.00','9800.00','5000',161),(547,'9800.00','0.00','1300',161),(548,'0.00','6800.00','EXP-11',162),(549,'6800.00','0.00','ACC-2',162),(550,'0.00','42500.00','ACC-1',163),(551,'42500.00','0.00','1200',163),(552,'0.00','212000.00','ACC-2',164),(553,'212000.00','0.00','4000',164),(554,'0.00','216000.00','5000',164),(555,'216000.00','0.00','1300',164),(556,'0.00','50285.00','ACC-1',165),(557,'50285.00','0.00','4000',165),(558,'0.00','31000.00','5000',165),(559,'31000.00','0.00','1300',165),(560,'0.00','150000.00','3300',166),(561,'150000.00','0.00','ACC-2',166),(562,'0.00','93600.00','ACC-1',167),(563,'93600.00','0.00','4000',167),(564,'0.00','70000.00','5000',167),(565,'70000.00','0.00','1300',167),(566,'0.00','18400.00','ACC-1',168),(567,'18400.00','0.00','4000',168),(568,'0.00','12250.00','5000',168),(569,'12250.00','0.00','1300',168),(570,'0.00','13650.00','ACC-1',169),(571,'0.00','13650.00','1200',169),(572,'27300.00','0.00','4000',169),(573,'0.00','27600.00','5000',169),(574,'27600.00','0.00','1300',169),(575,'0.00','35000.00','ACC-2',170),(576,'35000.00','0.00','4900',170),(577,'0.00','75000.00','ACC-1',171),(578,'75000.00','0.00','1200',171),(579,'0.00','9100.00','1200',172),(580,'9100.00','0.00','4000',172),(581,'0.00','9200.00','5000',172),(582,'9200.00','0.00','1300',172),(583,'0.00','30400.00','1200',173),(584,'30400.00','0.00','4000',173),(585,'0.00','24500.00','5000',173),(586,'24500.00','0.00','1300',173),(587,'0.00','201139.00','ACC-1',174),(588,'201139.00','0.00','4000',174),(589,'0.00','123999.99','5000',174),(590,'123999.99','0.00','1300',174),(591,'0.00','185000.00','EXP-4',175),(592,'185000.00','0.00','ACC-2',175),(593,'0.00','420000.00','EXP-2',176),(594,'420000.00','0.00','ACC-2',176),(595,'0.00','75191.00','EXP-3',177),(596,'75191.00','0.00','ACC-1',177),(597,'0.00','36400.00','1200',178),(598,'36400.00','0.00','4000',178),(599,'0.00','36800.00','5000',178),(600,'36800.00','0.00','1300',178),(601,'0.00','66240.00','ACC-1',179),(602,'0.00','154560.00','1200',179),(603,'220800.00','0.00','4000',179),(604,'0.00','178000.00','5000',179),(605,'178000.00','0.00','1300',179),(606,'0.00','40349.00','EXP-5',180),(607,'40349.00','0.00','ACC-1',180),(608,'0.00','25277.00','EXP-7',181),(609,'25277.00','0.00','ACC-1',181),(610,'0.00','10531.00','EXP-8',182),(611,'10531.00','0.00','ACC-1',182),(612,'0.00','66000000.00','1300',183),(613,'66000000.00','0.00','3100',183),(614,'0.00','60000000.00','1400',184),(615,'60000000.00','0.00','ACC-1',184),(616,'0.00','17400000.00','ACC-1',185),(617,'17400000.00','0.00','4000',185),(618,'0.00','36000000.00','5000',185),(619,'36000000.00','0.00','1300',185),(620,'0.00','710500.00','1300',186),(621,'710500.00','0.00','3100',186),(622,'0.00','2450.00','1200',187),(623,'2450.00','0.00','4000',187),(624,'0.00','2600.00','5000',187),(625,'2600.00','0.00','1300',187),(626,'0.00','1225.00','4100',188),(627,'1225.00','0.00','1200',188),(628,'0.00','1300.00','1300',188),(629,'1300.00','0.00','5000',188),(630,'0.00','71050.00','ACC-1',189),(631,'71050.00','0.00','4000',189),(632,'0.00','38025.00','5000',189),(633,'38025.00','0.00','1300',189),(634,'0.00','3870000.00','1300',190),(635,'3870000.00','0.00','3100',190),(636,'0.00','50000.00','1400',191),(637,'50000.00','0.00','ACC-1',191),(638,'0.00','1400000.00','ACC-1',192),(639,'0.00','50000.00','1200',192),(640,'1450000.00','0.00','4000',192),(641,'0.00','1290000.00','5000',192),(642,'1290000.00','0.00','1300',192),(643,'0.00','145000.00','4100',193),(644,'145000.00','0.00','1200',193),(645,'0.00','129000.00','1300',193),(646,'129000.00','0.00','5000',193),(647,'0.00','125000.00','1200',193),(648,'125000.00','0.00','ACC-1',193),(649,'0.00','56650.00','ACC-3',194),(650,'56650.00','0.00','1200',194),(651,'0.00','1500000.00','1300',195),(652,'100000.00','0.00','2100',195),(653,'1400000.00','0.00','3100',195),(654,'0.00','150000.00','5100',196),(655,'150000.00','0.00','1300',196),(656,'0.00','50000.00','1200',197),(657,'50000.00','0.00','3900',197),(658,'0.00','199975.00','1200',198),(659,'199975.00','0.00','4000',198),(660,'0.00','150000.00','5000',198),(661,'150000.00','0.00','1300',198),(662,'0.00','199975.00','4100',199),(663,'199975.00','0.00','1200',199),(664,'0.00','150000.00','1300',199),(665,'150000.00','0.00','5000',199),(666,'0.00','100000.00','ACC-1',200),(667,'0.00','100000.00','1200',200),(668,'200000.00','0.00','4000',200),(669,'0.00','150000.00','5000',200),(670,'150000.00','0.00','1300',200),(671,'0.00','40000.00','4100',201),(672,'40000.00','0.00','1200',201),(673,'0.00','30000.00','1300',201),(674,'30000.00','0.00','5000',201),(675,'0.00','20000.00','1200',201),(676,'20000.00','0.00','ACC-1',201),(677,'0.00','100000.00','2100',202),(678,'100000.00','0.00','ACC-3',202),(679,'0.00','200000.00','2100',203),(680,'200000.00','0.00','ACC-2',203),(681,'0.00','200000.00','EXP-2',204),(682,'200000.00','0.00','ACC-1',204),(683,'0.00','1500000.00','ACC-5',205),(684,'1500000.00','0.00','3900',205),(685,'0.00','50000000.00','1300',206),(686,'50000000.00','0.00','3100',206),(687,'0.00','5000.00','1400',207),(688,'5000.00','0.00','ACC-1',207),(689,'0.00','81252750.00','ACC-1',208),(690,'81252750.00','0.00','4000',208),(691,'0.00','50001798.34','5000',208),(692,'50001798.34','0.00','1300',208);

/*Table structure for table `mis_party_adjustment` */

DROP TABLE IF EXISTS `mis_party_adjustment`;

CREATE TABLE `mis_party_adjustment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `adj_date` date NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `party_id` bigint(20) NOT NULL,
  `party_type` enum('CUSTOMER','SUPPLIER') NOT NULL,
  `reason` varchar(500) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `mis_party_adjustment` */

/*Table structure for table `mis_product` */

DROP TABLE IF EXISTS `mis_product`;

CREATE TABLE `mis_product` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `active` bit(1) NOT NULL,
  `brand` varchar(96) DEFAULT NULL,
  `category` varchar(96) DEFAULT NULL,
  `description` varchar(500) DEFAULT NULL,
  `min_stock` decimal(18,4) DEFAULT NULL,
  `name` varchar(200) NOT NULL,
  `retail_price` decimal(18,2) DEFAULT NULL,
  `selling_price` decimal(18,2) DEFAULT NULL,
  `sku` varchar(48) NOT NULL,
  `wholesale_price` decimal(18,2) DEFAULT NULL,
  `base_unit_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKjw3o8fle0jqocyi9s0ssrssdq` (`sku`),
  KEY `FK3i7dbnhs6ohh4h7tk5n59wf2` (`base_unit_id`),
  CONSTRAINT `FK3i7dbnhs6ohh4h7tk5n59wf2` FOREIGN KEY (`base_unit_id`) REFERENCES `mis_unit` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8;

/*Data for the table `mis_product` */

insert  into `mis_product`(`id`,`active`,`brand`,`category`,`description`,`min_stock`,`name`,`retail_price`,`selling_price`,`sku`,`wholesale_price`,`base_unit_id`) values (1,'','Brightway','Electronics',NULL,'600.0000','LED Bulb 12W Daylight E27','290.00','290.00','ELE-LED12','245.00',1),(2,'','Brightway','Electronics',NULL,'500.0000','USB-C Fast Charging Cable 1m','450.00','450.00','ELE-USBC1','360.00',1),(3,'','Voltix','Electronics',NULL,'100.0000','Power Bank 10000mAh Dual USB','3200.00','3200.00','ELE-PWB10','2650.00',1),(4,'','Voltix','Electronics',NULL,'60.0000','Bluetooth Speaker Portable','2800.00','2800.00','ELE-BTSPK','2300.00',1),(5,'','KeepWell','Houseware',NULL,'80.0000','Plastic Storage Box 30L with Lid','1150.00','1150.00','HOM-STOR30','920.00',1),(6,'','KeepWell','Houseware',NULL,'120.0000','Stainless Steel Water Bottle 750ml','1350.00','1350.00','HOM-BOTL750','1080.00',1),(7,'','ChefMate','Houseware',NULL,'60.0000','Non-stick Frying Pan 26cm','2400.00','2400.00','HOM-PAN26','1950.00',1),(8,'','Royal Bone','Houseware',NULL,'20.0000','Ceramic Dinner Set 24 Pieces','9800.00','9800.00','HOM-DIN24','8300.00',7),(9,'','Anatolia','Textiles',NULL,'150.0000','Cotton Bath Towel 70x140cm','1450.00','1450.00','TEX-TWL70','1150.00',1),(10,'','Anatolia','Textiles',NULL,'60.0000','Printed Cotton Bed Sheet Set (King)','3900.00','3900.00','TEX-BSET','3200.00',7),(11,'','Al Safa','Fragrance',NULL,'120.0000','Arabic Oud Attar 12ml','1650.00','1650.00','FRG-OUD12','1250.00',1),(12,'','Al Safa','Food',NULL,'200.0000','Premium Medjool Dates','1850.00','1850.00','FOD-DATE1','1550.00',4),(13,'','Siam Dream','Houseware',NULL,'40.0000','Natural Latex Pillow','4600.00','4600.00','HOM-PILLOW','3800.00',1),(14,'','Chaokoh','Food',NULL,'400.0000','Coconut Milk 400ml Can','420.00','420.00','FOD-COCO400','340.00',1),(15,'','Golden Palm','Food',NULL,'500.0000','Refined Palm Cooking Oil','520.00','520.00','FOD-PALM5','455.00',9),(16,'','BrightWash','Cleaning',NULL,'300.0000','Laundry Detergent Powder 1kg','590.00','590.00','CLN-DET1','485.00',6),(17,'','Hambo','Hardware',NULL,'100.0000','Cable Tie 2.6 x 250 mm (18 inch )','145.00','145.00','00000000001','145.00',6),(18,'','HAMBO','Hardware',NULL,'100.0000','Wire Lock (AFC735)','400.00','400.00','12345','400.00',1),(19,'','Haier','Electronics','Microwase','110.0000','Microwave','65000.00','55000.00','PR-12345','45000.00',1);

/*Table structure for table `mis_product_unit` */

DROP TABLE IF EXISTS `mis_product_unit`;

CREATE TABLE `mis_product_unit` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `factor` decimal(18,4) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `unit_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKiu0llomhaf2nc7cub7llfg4ax` (`product_id`,`unit_id`),
  KEY `FKn3glsf51d04j5c0049gs72apm` (`unit_id`),
  CONSTRAINT `FKe6xiskup7jxdsdqphhpbwdcmb` FOREIGN KEY (`product_id`) REFERENCES `mis_product` (`id`),
  CONSTRAINT `FKn3glsf51d04j5c0049gs72apm` FOREIGN KEY (`unit_id`) REFERENCES `mis_unit` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8;

/*Data for the table `mis_product_unit` */

insert  into `mis_product_unit`(`id`,`factor`,`product_id`,`unit_id`) values (1,'100.0000',1,3),(2,'10.0000',1,2),(3,'50.0000',2,2),(4,'200.0000',2,3),(5,'20.0000',3,3),(6,'24.0000',4,3),(7,'12.0000',5,3),(8,'48.0000',6,3),(9,'12.0000',7,3),(10,'4.0000',8,3),(11,'12.0000',9,5),(12,'60.0000',9,3),(13,'10.0000',10,3),(14,'12.0000',11,5),(15,'144.0000',11,3),(16,'10.0000',12,3),(17,'8.0000',13,3),(18,'24.0000',14,3),(19,'20.0000',15,3),(20,'12.0000',16,3),(21,'600.0000',17,3),(22,'100.0000',18,3);

/*Table structure for table `mis_receipt` */

DROP TABLE IF EXISTS `mis_receipt`;

CREATE TABLE `mis_receipt` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `amount` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `method` varchar(32) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `receipt_date` date NOT NULL,
  `receipt_no` varchar(32) NOT NULL,
  `reference` varchar(96) DEFAULT NULL,
  `account_id` bigint(20) NOT NULL,
  `customer_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKcfrtw34lh8mhhg6b29i65yv7l` (`receipt_no`),
  KEY `FKsd0nqarsyko5o4xd1gxxknlg1` (`account_id`),
  KEY `FKbgml05ps098i8c6l7nr1abm6m` (`customer_id`),
  CONSTRAINT `FKbgml05ps098i8c6l7nr1abm6m` FOREIGN KEY (`customer_id`) REFERENCES `mis_customer` (`id`),
  CONSTRAINT `FKsd0nqarsyko5o4xd1gxxknlg1` FOREIGN KEY (`account_id`) REFERENCES `mis_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

/*Data for the table `mis_receipt` */

insert  into `mis_receipt`(`id`,`amount`,`created_at`,`created_by`,`method`,`notes`,`receipt_date`,`receipt_no`,`reference`,`account_id`,`customer_id`) values (1,'117000.00','2026-10-27 17:09:07.649138',NULL,'CHEQUE',NULL,'2026-08-08','RCP-000001','CHQ-4412',2,2),(2,'37100.00','2026-10-27 17:09:08.417741',NULL,'BANK_TRANSFER',NULL,'2026-08-28','RCP-000002','IBFT-22014',2,3),(3,'99600.00','2026-10-27 17:09:08.859961',NULL,'BANK_TRANSFER',NULL,'2026-09-07','RCP-000003','IBFT-22871',2,5),(4,'114840.00','2026-10-27 17:09:09.252392',NULL,'CASH',NULL,'2026-09-15','RCP-000004',NULL,1,7),(5,'23400.00','2026-10-27 17:09:09.569362',NULL,'CHEQUE',NULL,'2026-09-24','RCP-000005','CHQ-4467',2,2),(6,'120000.00','2026-10-27 17:09:09.914716',NULL,'ONLINE',NULL,'2026-09-29','RCP-000006','JC-901233',2,4),(7,'181172.00','2026-10-27 17:09:10.458660',NULL,'BANK_TRANSFER',NULL,'2026-10-13','RCP-000007','IBFT-23310',2,3),(8,'42500.00','2026-10-27 17:09:10.738629',NULL,'CASH',NULL,'2026-10-18','RCP-000008','Opening balance cleared',1,6),(9,'75000.00','2026-10-27 17:09:10.974062',NULL,'CASH',NULL,'2026-10-22','RCP-000009',NULL,1,13),(10,'56650.00','2026-10-30 17:12:42.704284','owner','CASH',NULL,'2026-10-30','RCP-000010',NULL,3,2);

/*Table structure for table `mis_sale` */

DROP TABLE IF EXISTS `mis_sale`;

CREATE TABLE `mis_sale` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cogs_total` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `discount_total` decimal(18,2) NOT NULL,
  `gross_amount` decimal(18,2) NOT NULL,
  `invoice_no` varchar(32) NOT NULL,
  `paid_amount` decimal(18,2) NOT NULL,
  `paid_at_sale` decimal(18,2) NOT NULL,
  `payment_method` varchar(32) DEFAULT NULL,
  `remarks` varchar(1000) DEFAULT NULL,
  `returned_amount` decimal(18,2) NOT NULL,
  `returned_cogs` decimal(18,2) NOT NULL,
  `returned_net` decimal(18,2) NOT NULL,
  `sale_date` date NOT NULL,
  `tax_total` decimal(18,2) NOT NULL,
  `total` decimal(18,2) NOT NULL,
  `type` enum('RETAIL','WHOLESALE') NOT NULL,
  `account_id` bigint(20) DEFAULT NULL,
  `customer_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKtp1ikdlb0g8w0acx8376rw73u` (`invoice_no`),
  KEY `FK83dehjjt86o1dm07894krvl10` (`account_id`),
  KEY `FK8b1ckj3w79o60cvhdf5s8hoqc` (`customer_id`),
  CONSTRAINT `FK83dehjjt86o1dm07894krvl10` FOREIGN KEY (`account_id`) REFERENCES `mis_account` (`id`),
  CONSTRAINT `FK8b1ckj3w79o60cvhdf5s8hoqc` FOREIGN KEY (`customer_id`) REFERENCES `mis_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=116 DEFAULT CHARSET=utf8;

/*Data for the table `mis_sale` */

insert  into `mis_sale`(`id`,`cogs_total`,`created_at`,`created_by`,`discount_total`,`gross_amount`,`invoice_no`,`paid_amount`,`paid_at_sale`,`payment_method`,`remarks`,`returned_amount`,`returned_cogs`,`returned_net`,`sale_date`,`tax_total`,`total`,`type`,`account_id`,`customer_id`) values (1,'208000.00','2026-10-27 17:09:06.240513',NULL,'0.00','212000.00','INV-000001','212000.00','212000.00','CASH',NULL,'0.00','0.00','0.00','2026-07-07','0.00','212000.00','WHOLESALE',1,8),(2,'370.00','2026-10-27 17:09:06.307241',NULL,'0.00','580.00','INV-000002','580.00','580.00','CASH',NULL,'0.00','0.00','0.00','2026-07-11','0.00','580.00','RETAIL',1,1),(3,'495.00','2026-10-27 17:09:06.438284',NULL,'0.00','1350.00','INV-000003','1350.00','1350.00','CASH',NULL,'0.00','0.00','0.00','2026-07-15','0.00','1350.00','RETAIL',1,1),(4,'660.00','2026-10-27 17:09:06.546509',NULL,'0.00','1800.00','INV-000004','1800.00','1800.00','CASH',NULL,'0.00','0.00','0.00','2026-07-17','0.00','1800.00','RETAIL',1,1),(5,'172000.00','2026-10-27 17:09:06.597498',NULL,'0.00','220800.00','INV-000005','110400.00','110400.00','CASH',NULL,'0.00','0.00','0.00','2026-07-17','0.00','220800.00','WHOLESALE',1,11),(6,'74000.00','2026-10-27 17:09:06.677194',NULL,'0.00','98000.00','INV-000006','98000.00','98000.00','CASH',NULL,'0.00','0.00','0.00','2026-07-21','0.00','98000.00','WHOLESALE',1,8),(7,'156000.00','2026-10-27 17:09:06.725385',NULL,'0.00','99600.00','INV-000007','99600.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-07-21','0.00','99600.00','WHOLESALE',NULL,5),(8,'17500.00','2026-10-27 17:09:06.765642',NULL,'0.00','23400.00','INV-000008','23400.00','23400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-23','0.00','23400.00','WHOLESALE',2,8),(9,'156000.00','2026-10-27 17:09:06.823610',NULL,'0.00','159000.00','INV-000009','47700.00','47700.00','CASH',NULL,'0.00','0.00','0.00','2026-07-23','0.00','159000.00','WHOLESALE',1,11),(10,'1291.67','2026-10-27 17:09:06.868229',NULL,'0.00','2700.00','INV-000010','2700.00','2700.00','CASH',NULL,'0.00','0.00','0.00','2026-07-25','0.00','2700.00','RETAIL',1,1),(11,'52000.00','2026-10-27 17:09:06.914863',NULL,'0.00','53000.00','INV-000011','53000.00','15900.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-25','0.00','53000.00','WHOLESALE',2,3),(12,'495.00','2026-10-27 17:09:07.005232',NULL,'0.00','1350.00','INV-000012','1350.00','1350.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-27','0.00','1350.00','RETAIL',2,1),(13,'52000.00','2026-10-27 17:09:07.073392',NULL,'0.00','53000.00','INV-000013','53000.00','53000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-29','0.00','53000.00','WHOLESALE',2,5),(14,'645.83','2026-10-27 17:09:07.109762',NULL,'0.00','1350.00','INV-000014','1350.00','1350.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-29','0.00','1350.00','RETAIL',2,1),(15,'7800.00','2026-10-27 17:09:07.180562',NULL,'0.00','9600.00','INV-000015','9600.00','9600.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-07-31','0.00','9600.00','RETAIL',2,1),(16,'165000.01','2026-10-27 17:09:07.222914',NULL,'0.00','207000.00','INV-000016','182100.00','62100.00','CASH',NULL,'0.00','0.00','0.00','2026-07-31','0.00','207000.00','WHOLESALE',1,4),(17,'10400.00','2026-10-27 17:09:07.324959',NULL,'0.00','12800.00','INV-000017','12800.00','12800.00','CASH',NULL,'0.00','0.00','0.00','2026-08-02','0.00','12800.00','RETAIL',1,1),(18,'21500.00','2026-10-27 17:09:07.376322',NULL,'0.00','32000.00','INV-000018','32000.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-08-04','0.00','32000.00','WHOLESALE',NULL,2),(19,'110000.00','2026-10-27 17:09:07.418829',NULL,'0.00','138000.00','INV-000019','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-08-04','0.00','138000.00','WHOLESALE',NULL,9),(20,'104000.00','2026-10-27 17:09:07.456906',NULL,'0.00','106000.00','INV-000020','31800.00','31800.00','CASH',NULL,'0.00','0.00','0.00','2026-08-06','0.00','106000.00','WHOLESALE',1,12),(21,'330.00','2026-10-27 17:09:07.496939',NULL,'0.00','900.00','INV-000021','900.00','900.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-06','0.00','900.00','RETAIL',2,1),(22,'52000.00','2026-10-27 17:09:07.539995',NULL,'0.00','33200.00','INV-000022','33200.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-08-06','0.00','33200.00','WHOLESALE',NULL,7),(23,'55000.00','2026-10-27 17:09:07.580692',NULL,'2070.00','69000.00','INV-000023','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-08-08','0.00','66930.00','WHOLESALE',NULL,12),(24,'555.00','2026-10-27 17:09:07.766695',NULL,'0.00','870.00','INV-000024','870.00','870.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-10','0.00','870.00','RETAIL',2,1),(25,'208000.00','2026-10-27 17:09:07.819131',NULL,'3984.00','132800.00','INV-000025','128816.00','128816.00','CASH',NULL,'0.00','0.00','0.00','2026-08-10','0.00','128816.00','WHOLESALE',1,6),(26,'17500.00','2026-10-27 17:09:07.879797',NULL,'702.00','23400.00','INV-000026','6809.00','6809.00','CASH',NULL,'0.00','0.00','0.00','2026-08-12','0.00','22698.00','WHOLESALE',1,4),(27,'740.00','2026-10-27 17:09:07.941042',NULL,'0.00','1160.00','INV-000027','1160.00','1160.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-14','0.00','1160.00','RETAIL',2,1),(28,'7800.00','2026-10-27 17:09:07.973360',NULL,'0.00','9600.00','INV-000028','9600.00','9600.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-14','0.00','9600.00','RETAIL',2,1),(29,'1791.67','2026-10-27 17:09:08.048331',NULL,'0.00','2800.00','INV-000029','2800.00','2800.00','CASH',NULL,'0.00','0.00','0.00','2026-08-16','0.00','2800.00','RETAIL',1,1),(30,'35000.00','2026-10-27 17:09:08.096122',NULL,'0.00','46800.00','INV-000030','46800.00','23400.00','CASH',NULL,'23400.00','17500.00','23400.00','2026-08-18','0.00','46800.00','WHOLESALE',1,2),(31,'5200.00','2026-10-27 17:09:08.126639',NULL,'0.00','6400.00','INV-000031','6400.00','6400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-18','0.00','6400.00','RETAIL',2,1),(32,'165.00','2026-10-27 17:09:08.159718',NULL,'0.00','450.00','INV-000032','450.00','450.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-20','0.00','450.00','RETAIL',2,1),(33,'5833.33','2026-10-27 17:09:08.191769',NULL,'0.00','9600.00','INV-000033','9600.00','9600.00','CASH',NULL,'0.00','0.00','0.00','2026-08-20','0.00','9600.00','RETAIL',1,1),(34,'2450.00','2026-10-27 17:09:08.219284',NULL,'0.00','3450.00','INV-000034','3450.00','3450.00','CASH',NULL,'0.00','0.00','0.00','2026-08-20','0.00','3450.00','RETAIL',1,1),(35,'17200.00','2026-10-27 17:09:08.258561',NULL,'0.00','32640.00','INV-000035','32640.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-08-22','0.00','32640.00','WHOLESALE',NULL,7),(36,'740.00','2026-10-27 17:09:08.318460',NULL,'0.00','1160.00','INV-000036','1160.00','1160.00','CASH',NULL,'0.00','0.00','0.00','2026-08-26','0.00','1160.00','RETAIL',1,1),(37,'123999.99','2026-10-27 17:09:08.396153',NULL,'0.00','207360.00','INV-000037','178680.00','103680.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-28','0.00','207360.00','WHOLESALE',2,13),(38,'17200.00','2026-10-27 17:09:08.471070',NULL,'979.00','32640.00','INV-000038','31661.00','31661.00','CASH',NULL,'0.00','0.00','0.00','2026-08-30','0.00','31661.00','WHOLESALE',1,3),(39,'600000.02','2026-10-27 17:09:08.501072',NULL,'0.00','720000.00','INV-000039','720000.00','720000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-30','0.00','720000.00','WHOLESALE',2,9),(40,'185.00','2026-10-27 17:09:08.528584',NULL,'0.00','290.00','INV-000040','290.00','290.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-08-30','0.00','290.00','RETAIL',2,1),(41,'8600.00','2026-10-27 17:09:08.586661',NULL,'0.00','15600.00','INV-000041','15600.00','15600.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-01','0.00','15600.00','RETAIL',2,1),(42,'21500.00','2026-10-27 17:09:08.625173',NULL,'0.00','32000.00','INV-000042','32000.00','32000.00','CASH',NULL,'0.00','0.00','0.00','2026-09-01','0.00','32000.00','WHOLESALE',1,6),(43,'4375.00','2026-10-27 17:09:08.705518',NULL,'0.00','7200.00','INV-000043','7200.00','7200.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-01','0.00','7200.00','RETAIL',2,1),(44,'3062.50','2026-10-27 17:09:08.730533',NULL,'0.00','4600.00','INV-000044','4600.00','4600.00','CASH',NULL,'0.00','0.00','0.00','2026-09-03','0.00','4600.00','RETAIL',1,1),(45,'52500.00','2026-10-27 17:09:08.756464',NULL,'0.00','70200.00','INV-000045','70200.00','35100.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-03','0.00','70200.00','WHOLESALE',2,3),(46,'37000.00','2026-10-27 17:09:08.784093',NULL,'0.00','49000.00','INV-000046','49000.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-05','0.00','49000.00','WHOLESALE',NULL,7),(47,'300000.01','2026-10-27 17:09:08.810700',NULL,'0.00','360000.00','INV-000047','150500.00','108000.00','CASH',NULL,'0.00','0.00','0.00','2026-09-05','0.00','360000.00','WHOLESALE',1,6),(48,'110000.00','2026-10-27 17:09:08.837708',NULL,'4140.00','138000.00','INV-000048','133860.00','133860.00','CASH',NULL,'0.00','0.00','0.00','2026-09-07','0.00','133860.00','WHOLESALE',1,4),(49,'660.00','2026-10-27 17:09:08.895495',NULL,'0.00','1800.00','INV-000049','1800.00','1800.00','CASH',NULL,'0.00','0.00','0.00','2026-09-09','0.00','1800.00','RETAIL',1,1),(50,'156000.00','2026-10-27 17:09:08.923965',NULL,'2988.00','99600.00','INV-000050','96612.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-09','0.00','96612.00','WHOLESALE',NULL,3),(51,'8600.00','2026-10-27 17:09:08.953279',NULL,'0.00','15600.00','INV-000051','15600.00','15600.00','CASH',NULL,'0.00','0.00','0.00','2026-09-11','0.00','15600.00','RETAIL',1,1),(52,'3062.50','2026-10-27 17:09:09.009501',NULL,'0.00','4600.00','INV-000052','4600.00','4600.00','CASH',NULL,'0.00','0.00','0.00','2026-09-11','0.00','4600.00','RETAIL',1,1),(53,'12900.00','2026-10-27 17:09:09.066945',NULL,'0.00','24480.00','INV-000053','24480.00','24480.00','CASH',NULL,'0.00','0.00','0.00','2026-09-13','0.00','24480.00','WHOLESALE',1,9),(54,'17500.00','2026-10-27 17:09:09.094305',NULL,'0.00','23400.00','INV-000054','23400.00','23400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-13','0.00','23400.00','WHOLESALE',2,7),(55,'39000.00','2026-10-27 17:09:09.120730',NULL,'0.00','29400.00','INV-000055','29400.00','29400.00','CASH',NULL,'0.00','0.00','0.00','2026-09-13','0.00','29400.00','RETAIL',1,1),(56,'4720.00','2026-10-27 17:09:09.178453',NULL,'0.00','7400.00','INV-000056','7400.00','7400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-15','0.00','7400.00','RETAIL',2,1),(57,'43000.00','2026-10-27 17:09:09.202736',NULL,'0.00','64000.00','INV-000057','64000.00','32000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-15','0.00','64000.00','WHOLESALE',2,3),(58,'5500.00','2026-10-27 17:09:09.233850',NULL,'0.00','5820.00','INV-000058','5820.00','5820.00','CASH',NULL,'0.00','0.00','0.00','2026-09-15','0.00','5820.00','WHOLESALE',1,3),(59,'1833.33','2026-10-27 17:09:09.293496',NULL,'0.00','2360.00','INV-000059','2360.00','2360.00','CASH',NULL,'0.00','0.00','0.00','2026-09-17','0.00','2360.00','RETAIL',1,1),(60,'43000.00','2026-10-27 17:09:09.319789',NULL,'0.00','64000.00','INV-000060','32000.00','32000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-17','0.00','64000.00','WHOLESALE',2,4),(61,'19600.00','2026-10-27 17:09:09.370365',NULL,'0.00','22080.00','INV-000061','22080.00','22080.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-19','0.00','22080.00','WHOLESALE',2,9),(62,'18500.00','2026-10-27 17:09:09.396347',NULL,'0.00','24500.00','INV-000062','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-19','0.00','24500.00','WHOLESALE',NULL,9),(63,'2583.33','2026-10-27 17:09:09.423864',NULL,'0.00','5400.00','INV-000063','5400.00','5400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-19','0.00','5400.00','RETAIL',2,1),(64,'2750.00','2026-10-27 17:09:09.465256',NULL,'0.00','4350.00','INV-000064','4350.00','4350.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-21','0.00','4350.00','RETAIL',2,1),(65,'6450.00','2026-10-27 17:09:09.495262',NULL,'0.00','11700.00','INV-000065','11700.00','11700.00','CASH',NULL,'0.00','0.00','0.00','2026-09-21','0.00','11700.00','RETAIL',1,1),(66,'1291.67','2026-10-27 17:09:09.519726',NULL,'0.00','2700.00','INV-000066','2700.00','2700.00','CASH',NULL,'0.00','0.00','0.00','2026-09-23','0.00','2700.00','RETAIL',1,1),(67,'98000.00','2026-10-27 17:09:09.545842',NULL,'0.00','121600.00','INV-000067','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-23','0.00','121600.00','WHOLESALE',NULL,11),(68,'16500.00','2026-10-27 17:09:09.623480',NULL,'0.00','17460.00','INV-000068','17460.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-25','0.00','17460.00','WHOLESALE',NULL,3),(69,'3666.67','2026-10-27 17:09:09.672316',NULL,'0.00','5800.00','INV-000069','5800.00','5800.00','CASH',NULL,'0.00','0.00','0.00','2026-09-25','0.00','5800.00','RETAIL',1,1),(70,'18500.00','2026-10-27 17:09:09.722082',NULL,'0.00','24500.00','INV-000070','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-27','0.00','24500.00','WHOLESALE',NULL,6),(71,'132000.00','2026-10-27 17:09:09.749821',NULL,'0.00','288000.00','INV-000071','288000.00','288000.00','CASH',NULL,'0.00','0.00','0.00','2026-09-27','0.00','288000.00','WHOLESALE',1,12),(72,'220000.01','2026-10-27 17:09:09.772708',NULL,'0.00','276000.00','INV-000072','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-09-27','0.00','276000.00','WHOLESALE',NULL,5),(73,'49000.00','2026-10-27 17:09:09.835574',NULL,'0.00','60800.00','INV-000073','18240.00','18240.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-09-29','0.00','60800.00','WHOLESALE',2,10),(74,'185.00','2026-10-27 17:09:09.861557',NULL,'0.00','290.00','INV-000074','290.00','290.00','CASH',NULL,'0.00','0.00','0.00','2026-09-29','0.00','290.00','RETAIL',1,1),(75,'23600.00','2026-10-27 17:09:09.892704',NULL,'0.00','31000.00','INV-000075','15500.00','15500.00','CASH',NULL,'0.00','0.00','0.00','2026-09-29','0.00','31000.00','WHOLESALE',1,4),(76,'458.33','2026-10-27 17:09:09.976483',NULL,'0.00','590.00','INV-000076','590.00','590.00','CASH',NULL,'0.00','0.00','0.00','2026-10-01','0.00','590.00','RETAIL',1,1),(77,'150000.00','2026-10-27 17:09:10.000310',NULL,'0.00','180000.00','INV-000077','90000.00','90000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-01','0.00','180000.00','WHOLESALE',2,11),(78,'4300.00','2026-10-27 17:09:10.028955',NULL,'0.00','8160.00','INV-000078','4080.00','4080.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-01','0.00','8160.00','WHOLESALE',2,13),(79,'62000.00','2026-10-27 17:09:10.084454',NULL,'0.00','103680.00','INV-000079','51840.00','51840.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-03','0.00','103680.00','WHOLESALE',2,12),(80,'1937.50','2026-10-27 17:09:10.117084',NULL,'0.00','4050.00','INV-000080','4050.00','4050.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-03','0.00','4050.00','RETAIL',2,1),(81,'64500.00','2026-10-27 17:09:10.144412',NULL,'0.00','96000.00','INV-000081','48000.00','48000.00','CASH',NULL,'0.00','0.00','0.00','2026-10-03','0.00','96000.00','WHOLESALE',1,9),(82,'11800.00','2026-10-27 17:09:10.170027',NULL,'0.00','15500.00','INV-000082','7750.00','7750.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-05','0.00','15500.00','WHOLESALE',2,7),(83,'22000.00','2026-10-27 17:09:10.194147',NULL,'0.00','23280.00','INV-000083','23280.00','23280.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-05','0.00','23280.00','WHOLESALE',2,6),(84,'43000.00','2026-10-27 17:09:10.226347',NULL,'0.00','55200.00','INV-000084','55200.00','55200.00','CASH',NULL,'0.00','0.00','0.00','2026-10-07','0.00','55200.00','WHOLESALE',1,7),(85,'2583.33','2026-10-27 17:09:10.251256',NULL,'0.00','5400.00','INV-000085','5400.00','5400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-07','0.00','5400.00','RETAIL',2,1),(86,'300000.01','2026-10-27 17:09:10.285890',NULL,'0.00','360000.00','INV-000086','108000.00','108000.00','CASH',NULL,'0.00','0.00','0.00','2026-10-09','0.00','360000.00','WHOLESALE',1,6),(87,'54000.00','2026-10-27 17:09:10.312016',NULL,'0.00','53000.00','INV-000087','53000.00','53000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-09','0.00','53000.00','WHOLESALE',2,5),(88,'52000.00','2026-10-27 17:09:10.337067',NULL,'0.00','39200.00','INV-000088','39200.00','39200.00','CASH',NULL,'0.00','0.00','0.00','2026-10-09','0.00','39200.00','RETAIL',1,1),(89,'86000.00','2026-10-27 17:09:10.360677',NULL,'0.00','110400.00','INV-000089','110400.00','110400.00','CASH',NULL,'0.00','0.00','0.00','2026-10-11','0.00','110400.00','WHOLESALE',1,2),(90,'165000.01','2026-10-27 17:09:10.385654',NULL,'0.00','207000.00','INV-000090','207000.00','207000.00','CASH',NULL,'0.00','0.00','0.00','2026-10-11','0.00','207000.00','WHOLESALE',1,3),(91,'52000.00','2026-10-27 17:09:10.415139',NULL,'0.00','33200.00','INV-000091','33200.00','33200.00','CASH',NULL,'0.00','0.00','0.00','2026-10-13','0.00','33200.00','WHOLESALE',1,5),(92,'11800.00','2026-10-27 17:09:10.439147',NULL,'0.00','15500.00','INV-000092','7750.00','7750.00','CASH',NULL,'0.00','0.00','0.00','2026-10-13','0.00','15500.00','WHOLESALE',1,9),(93,'3125.00','2026-10-27 17:09:10.512892',NULL,'0.00','4950.00','INV-000093','4950.00','4950.00','CASH',NULL,'0.00','0.00','0.00','2026-10-15','0.00','4950.00','RETAIL',1,1),(94,'537.50','2026-10-27 17:09:10.537899',NULL,'0.00','1260.00','INV-000094','1260.00','1260.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-15','0.00','1260.00','RETAIL',2,1),(95,'3666.67','2026-10-27 17:09:10.560244',NULL,'0.00','5800.00','INV-000095','5800.00','5800.00','CASH',NULL,'0.00','0.00','0.00','2026-10-15','0.00','5800.00','RETAIL',1,1),(96,'5375.00','2026-10-27 17:09:10.586820',NULL,'0.00','8400.00','INV-000096','8400.00','8400.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-17','0.00','8400.00','RETAIL',2,1),(97,'23600.00','2026-10-27 17:09:10.610426',NULL,'0.00','31000.00','INV-000097','9300.00','9300.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-17','0.00','31000.00','WHOLESALE',2,3),(98,'9800.00','2026-10-27 17:09:10.635437',NULL,'0.00','11040.00','INV-000098','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-10-17','0.00','11040.00','WHOLESALE',NULL,7),(99,'216000.00','2026-10-27 17:09:10.803299',NULL,'0.00','212000.00','INV-000099','212000.00','212000.00','BANK_TRANSFER',NULL,'0.00','0.00','0.00','2026-10-19','0.00','212000.00','WHOLESALE',2,8),(100,'31000.00','2026-10-27 17:09:10.851320',NULL,'1555.00','51840.00','INV-000100','50285.00','50285.00','CASH',NULL,'0.00','0.00','0.00','2026-10-19','0.00','50285.00','WHOLESALE',1,6),(101,'70000.00','2026-10-27 17:09:10.895315',NULL,'0.00','93600.00','INV-000101','93600.00','93600.00','CASH',NULL,'0.00','0.00','0.00','2026-10-21','0.00','93600.00','WHOLESALE',1,13),(102,'12250.00','2026-10-27 17:09:10.922669',NULL,'0.00','18400.00','INV-000102','18400.00','18400.00','CASH',NULL,'0.00','0.00','0.00','2026-10-21','0.00','18400.00','RETAIL',1,1),(103,'27600.00','2026-10-27 17:09:10.949182',NULL,'0.00','27300.00','INV-000103','27300.00','13650.00','CASH',NULL,'0.00','0.00','0.00','2026-10-21','0.00','27300.00','WHOLESALE',1,2),(104,'9200.00','2026-10-27 17:09:11.001178',NULL,'0.00','9100.00','INV-000104','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-10-23','0.00','9100.00','WHOLESALE',NULL,13),(105,'24500.00','2026-10-27 17:09:11.023763',NULL,'0.00','30400.00','INV-000105','0.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-10-23','0.00','30400.00','WHOLESALE',NULL,11),(106,'123999.99','2026-10-27 17:09:11.045352',NULL,'6221.00','207360.00','INV-000106','201139.00','201139.00','CASH',NULL,'0.00','0.00','0.00','2026-10-23','0.00','201139.00','WHOLESALE',1,13),(107,'36800.00','2026-10-27 17:09:11.094441',NULL,'0.00','36400.00','INV-000107','36400.00','0.00','CREDIT',NULL,'0.00','0.00','0.00','2026-10-25','0.00','36400.00','WHOLESALE',NULL,2),(108,'178000.00','2026-10-27 17:09:11.121989',NULL,'0.00','220800.00','INV-000108','66240.00','66240.00','CASH',NULL,'0.00','0.00','0.00','2026-10-25','0.00','220800.00','WHOLESALE',1,10),(109,'36000000.00','2026-10-27 17:15:17.953513','owner','0.00','17400000.00','INV-000109','17400000.00','17400000.00','CASH',NULL,'0.00','0.00','0.00','2026-10-27','0.00','17400000.00','RETAIL',1,1),(110,'2600.00','2026-10-30 13:31:30.856282','sales','0.00','2450.00','INV-000110','0.00','0.00','CREDIT',NULL,'1225.00','1300.00','1225.00','2026-10-30','0.00','2450.00','WHOLESALE',NULL,5),(111,'38025.00','2026-10-30 14:22:57.644460','owner','0.00','71050.00','INV-000111','71050.00','71050.00','CASH',NULL,'0.00','0.00','0.00','2026-10-30','0.00','71050.00','RETAIL',1,1),(112,'1290000.00','2026-10-30 17:02:17.455545','owner','0.00','1450000.00','INV-000112','1400000.00','1400000.00','CASH',NULL,'145000.00','129000.00','145000.00','2026-10-30','0.00','1450000.00','RETAIL',1,2),(113,'150000.00','2026-10-30 18:16:11.760478','owner','25.00','200000.00','INV-000113','0.00','0.00','CREDIT',NULL,'199975.00','150000.00','199975.00','2026-10-30','0.00','199975.00','WHOLESALE',NULL,14),(114,'150000.00','2026-10-30 19:19:50.659507','owner','0.00','200000.00','INV-000114','100000.00','100000.00','CASH',NULL,'40000.00','30000.00','40000.00','2026-10-31','0.00','200000.00','WHOLESALE',1,14),(115,'50001798.34','2026-11-05 16:18:12.626187','owner','0.00','81252750.00','INV-000115','81252750.00','81252750.00','CASH',NULL,'0.00','0.00','0.00','2026-11-05','0.00','81252750.00','RETAIL',1,1);

/*Table structure for table `mis_sale_line` */

DROP TABLE IF EXISTS `mis_sale_line`;

CREATE TABLE `mis_sale_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `base_qty` decimal(18,4) NOT NULL,
  `discount` decimal(18,2) NOT NULL,
  `factor` decimal(18,4) NOT NULL,
  `line_total` decimal(18,2) NOT NULL,
  `net_amount` decimal(18,2) NOT NULL,
  `qty` decimal(18,4) NOT NULL,
  `rate` decimal(18,4) NOT NULL,
  `returned_base_qty` decimal(18,4) NOT NULL,
  `tax_amount` decimal(18,2) NOT NULL,
  `tax_pct` decimal(9,3) NOT NULL,
  `unit_cost` decimal(18,4) NOT NULL,
  `batch_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `sale_id` bigint(20) NOT NULL,
  `unit_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKpbnkn04tvq2or3vc7ie9gbxp2` (`batch_id`),
  KEY `FKeefe2w6ccdefkcit7j536gmnm` (`product_id`),
  KEY `FKqy862b6391s6nmyrj31qdo7v3` (`sale_id`),
  KEY `FKs3a6o1websihc0adpq843tyea` (`unit_id`),
  CONSTRAINT `FKeefe2w6ccdefkcit7j536gmnm` FOREIGN KEY (`product_id`) REFERENCES `mis_product` (`id`),
  CONSTRAINT `FKpbnkn04tvq2or3vc7ie9gbxp2` FOREIGN KEY (`batch_id`) REFERENCES `mis_batch` (`id`),
  CONSTRAINT `FKqy862b6391s6nmyrj31qdo7v3` FOREIGN KEY (`sale_id`) REFERENCES `mis_sale` (`id`),
  CONSTRAINT `FKs3a6o1websihc0adpq843tyea` FOREIGN KEY (`unit_id`) REFERENCES `mis_unit` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;

/*Data for the table `mis_sale_line` */

insert  into `mis_sale_line`(`id`,`base_qty`,`discount`,`factor`,`line_total`,`net_amount`,`qty`,`rate`,`returned_base_qty`,`tax_amount`,`tax_pct`,`unit_cost`,`batch_id`,`product_id`,`sale_id`,`unit_id`) values (1,'80.0000','0.00','20.0000','212000.00','212000.00','4.0000','53000.0000','0.0000','0.00','0.000','2600.0000',3,3,1,3),(2,'2.0000','0.00','1.0000','580.00','580.00','2.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,2,1),(3,'3.0000','0.00','1.0000','1350.00','1350.00','3.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,3,1),(4,'4.0000','0.00','1.0000','1800.00','1800.00','4.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,4,1),(5,'96.0000','0.00','24.0000','220800.00','220800.00','4.0000','55200.0000','0.0000','0.00','0.000','1791.6667',4,4,5,3),(6,'400.0000','0.00','100.0000','98000.00','98000.00','4.0000','24500.0000','0.0000','0.00','0.000','185.0000',1,1,6,3),(7,'12.0000','0.00','4.0000','99600.00','99600.00','3.0000','33200.0000','0.0000','0.00','0.000','13000.0000',8,8,7,3),(8,'12.0000','0.00','12.0000','23400.00','23400.00','1.0000','23400.0000','0.0000','0.00','0.000','1458.3333',7,7,8,3),(9,'60.0000','0.00','20.0000','159000.00','159000.00','3.0000','53000.0000','0.0000','0.00','0.000','2600.0000',3,3,9,3),(10,'2.0000','0.00','1.0000','2700.00','2700.00','2.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,10,1),(11,'20.0000','0.00','20.0000','53000.00','53000.00','1.0000','53000.0000','0.0000','0.00','0.000','2600.0000',3,3,11,3),(12,'3.0000','0.00','1.0000','1350.00','1350.00','3.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,12,1),(13,'20.0000','0.00','20.0000','53000.00','53000.00','1.0000','53000.0000','0.0000','0.00','0.000','2600.0000',3,3,13,3),(14,'1.0000','0.00','1.0000','1350.00','1350.00','1.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,14,1),(15,'3.0000','0.00','1.0000','9600.00','9600.00','3.0000','3200.0000','0.0000','0.00','0.000','2600.0000',3,3,15,1),(16,'180.0000','0.00','60.0000','207000.00','207000.00','3.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,16,3),(17,'4.0000','0.00','1.0000','12800.00','12800.00','4.0000','3200.0000','0.0000','0.00','0.000','2600.0000',3,3,17,1),(18,'10.0000','0.00','10.0000','32000.00','32000.00','1.0000','32000.0000','0.0000','0.00','0.000','2150.0000',10,10,18,3),(19,'120.0000','0.00','60.0000','138000.00','138000.00','2.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,19,3),(20,'40.0000','0.00','20.0000','106000.00','106000.00','2.0000','53000.0000','0.0000','0.00','0.000','2600.0000',3,3,20,3),(21,'2.0000','0.00','1.0000','900.00','900.00','2.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,21,1),(22,'4.0000','0.00','4.0000','33200.00','33200.00','1.0000','33200.0000','0.0000','0.00','0.000','13000.0000',8,8,22,3),(23,'60.0000','2070.00','60.0000','66930.00','66930.00','1.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,23,3),(24,'3.0000','0.00','1.0000','870.00','870.00','3.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,24,1),(25,'16.0000','3984.00','4.0000','128816.00','128816.00','4.0000','33200.0000','0.0000','0.00','0.000','13000.0000',8,8,25,3),(26,'12.0000','702.00','12.0000','22698.00','22698.00','1.0000','23400.0000','0.0000','0.00','0.000','1458.3333',7,7,26,3),(27,'4.0000','0.00','1.0000','1160.00','1160.00','4.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,27,1),(28,'3.0000','0.00','1.0000','9600.00','9600.00','3.0000','3200.0000','0.0000','0.00','0.000','2600.0000',3,3,28,1),(29,'1.0000','0.00','1.0000','2800.00','2800.00','1.0000','2800.0000','0.0000','0.00','0.000','1791.6667',4,4,29,1),(30,'24.0000','0.00','12.0000','46800.00','46800.00','2.0000','23400.0000','12.0000','0.00','0.000','1458.3333',7,7,30,3),(31,'2.0000','0.00','1.0000','6400.00','6400.00','2.0000','3200.0000','0.0000','0.00','0.000','2600.0000',3,3,31,1),(32,'1.0000','0.00','1.0000','450.00','450.00','1.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,32,1),(33,'4.0000','0.00','1.0000','9600.00','9600.00','4.0000','2400.0000','0.0000','0.00','0.000','1458.3333',7,7,33,1),(34,'3.0000','0.00','1.0000','3450.00','3450.00','3.0000','1150.0000','0.0000','0.00','0.000','816.6667',5,5,34,1),(35,'96.0000','0.00','24.0000','32640.00','32640.00','4.0000','8160.0000','0.0000','0.00','0.000','179.1667',12,14,35,3),(36,'4.0000','0.00','1.0000','1160.00','1160.00','4.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,36,1),(37,'192.0000','0.00','48.0000','207360.00','207360.00','4.0000','51840.0000','0.0000','0.00','0.000','645.8333',6,6,37,3),(38,'96.0000','979.00','24.0000','31661.00','31661.00','4.0000','8160.0000','0.0000','0.00','0.000','179.1667',12,14,38,3),(39,'576.0000','0.00','144.0000','720000.00','720000.00','4.0000','180000.0000','0.0000','0.00','0.000','1041.6667',13,11,39,3),(40,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,40,1),(41,'4.0000','0.00','1.0000','15600.00','15600.00','4.0000','3900.0000','0.0000','0.00','0.000','2150.0000',10,10,41,7),(42,'10.0000','0.00','10.0000','32000.00','32000.00','1.0000','32000.0000','0.0000','0.00','0.000','2150.0000',10,10,42,3),(43,'3.0000','0.00','1.0000','7200.00','7200.00','3.0000','2400.0000','0.0000','0.00','0.000','1458.3333',7,7,43,1),(44,'1.0000','0.00','1.0000','4600.00','4600.00','1.0000','4600.0000','0.0000','0.00','0.000','3062.5000',11,13,44,1),(45,'36.0000','0.00','12.0000','70200.00','70200.00','3.0000','23400.0000','0.0000','0.00','0.000','1458.3333',7,7,45,3),(46,'200.0000','0.00','100.0000','49000.00','49000.00','2.0000','24500.0000','0.0000','0.00','0.000','185.0000',1,1,46,3),(47,'288.0000','0.00','144.0000','360000.00','360000.00','2.0000','180000.0000','0.0000','0.00','0.000','1041.6667',13,11,47,3),(48,'120.0000','4140.00','60.0000','133860.00','133860.00','2.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,48,3),(49,'4.0000','0.00','1.0000','1800.00','1800.00','4.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,49,1),(50,'12.0000','2988.00','4.0000','96612.00','96612.00','3.0000','33200.0000','0.0000','0.00','0.000','13000.0000',8,8,50,3),(51,'4.0000','0.00','1.0000','15600.00','15600.00','4.0000','3900.0000','0.0000','0.00','0.000','2150.0000',10,10,51,7),(52,'1.0000','0.00','1.0000','4600.00','4600.00','1.0000','4600.0000','0.0000','0.00','0.000','3062.5000',11,13,52,1),(53,'72.0000','0.00','24.0000','24480.00','24480.00','3.0000','8160.0000','0.0000','0.00','0.000','179.1667',12,14,53,3),(54,'12.0000','0.00','12.0000','23400.00','23400.00','1.0000','23400.0000','0.0000','0.00','0.000','1458.3333',7,7,54,3),(55,'3.0000','0.00','1.0000','29400.00','29400.00','3.0000','9800.0000','0.0000','0.00','0.000','13000.0000',8,8,55,7),(56,'4.0000','0.00','1.0000','7400.00','7400.00','4.0000','1850.0000','0.0000','0.00','0.000','1180.0000',14,12,56,4),(57,'20.0000','0.00','10.0000','64000.00','64000.00','2.0000','32000.0000','0.0000','0.00','0.000','2150.0000',10,10,57,3),(58,'12.0000','0.00','12.0000','5820.00','5820.00','1.0000','5820.0000','0.0000','0.00','0.000','458.3333',16,16,58,3),(59,'4.0000','0.00','1.0000','2360.00','2360.00','4.0000','590.0000','0.0000','0.00','0.000','458.3333',16,16,59,6),(60,'20.0000','0.00','10.0000','64000.00','64000.00','2.0000','32000.0000','0.0000','0.00','0.000','2150.0000',10,10,60,3),(61,'24.0000','0.00','12.0000','22080.00','22080.00','2.0000','11040.0000','0.0000','0.00','0.000','816.6667',5,5,61,3),(62,'100.0000','0.00','100.0000','24500.00','24500.00','1.0000','24500.0000','0.0000','0.00','0.000','185.0000',1,1,62,3),(63,'4.0000','0.00','1.0000','5400.00','5400.00','4.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,63,1),(64,'3.0000','0.00','1.0000','4350.00','4350.00','3.0000','1450.0000','0.0000','0.00','0.000','916.6667',9,9,64,1),(65,'3.0000','0.00','1.0000','11700.00','11700.00','3.0000','3900.0000','0.0000','0.00','0.000','2150.0000',10,10,65,7),(66,'2.0000','0.00','1.0000','2700.00','2700.00','2.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,66,1),(67,'32.0000','0.00','8.0000','121600.00','121600.00','4.0000','30400.0000','0.0000','0.00','0.000','3062.5000',11,13,67,3),(68,'36.0000','0.00','12.0000','17460.00','17460.00','3.0000','5820.0000','0.0000','0.00','0.000','458.3333',16,16,68,3),(69,'4.0000','0.00','1.0000','5800.00','5800.00','4.0000','1450.0000','0.0000','0.00','0.000','916.6667',9,9,69,1),(70,'100.0000','0.00','100.0000','24500.00','24500.00','1.0000','24500.0000','0.0000','0.00','0.000','185.0000',1,1,70,3),(71,'800.0000','0.00','200.0000','288000.00','288000.00','4.0000','72000.0000','0.0000','0.00','0.000','165.0000',2,2,71,3),(72,'240.0000','0.00','60.0000','276000.00','276000.00','4.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,72,3),(73,'16.0000','0.00','8.0000','60800.00','60800.00','2.0000','30400.0000','0.0000','0.00','0.000','3062.5000',11,13,73,3),(74,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,74,1),(75,'20.0000','0.00','10.0000','31000.00','31000.00','2.0000','15500.0000','0.0000','0.00','0.000','1180.0000',14,12,75,3),(76,'1.0000','0.00','1.0000','590.00','590.00','1.0000','590.0000','0.0000','0.00','0.000','458.3333',16,16,76,6),(77,'144.0000','0.00','144.0000','180000.00','180000.00','1.0000','180000.0000','0.0000','0.00','0.000','1041.6667',13,11,77,3),(78,'24.0000','0.00','24.0000','8160.00','8160.00','1.0000','8160.0000','0.0000','0.00','0.000','179.1667',12,14,78,3),(79,'96.0000','0.00','48.0000','103680.00','103680.00','2.0000','51840.0000','0.0000','0.00','0.000','645.8333',6,6,79,3),(80,'3.0000','0.00','1.0000','4050.00','4050.00','3.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,80,1),(81,'30.0000','0.00','10.0000','96000.00','96000.00','3.0000','32000.0000','0.0000','0.00','0.000','2150.0000',10,10,81,3),(82,'10.0000','0.00','10.0000','15500.00','15500.00','1.0000','15500.0000','0.0000','0.00','0.000','1180.0000',14,12,82,3),(83,'48.0000','0.00','12.0000','23280.00','23280.00','4.0000','5820.0000','0.0000','0.00','0.000','458.3333',16,16,83,3),(84,'24.0000','0.00','24.0000','55200.00','55200.00','1.0000','55200.0000','0.0000','0.00','0.000','1791.6667',4,4,84,3),(85,'4.0000','0.00','1.0000','5400.00','5400.00','4.0000','1350.0000','0.0000','0.00','0.000','645.8333',6,6,85,1),(86,'288.0000','0.00','144.0000','360000.00','360000.00','2.0000','180000.0000','0.0000','0.00','0.000','1041.6667',13,11,86,3),(87,'20.0000','0.00','20.0000','53000.00','53000.00','1.0000','53000.0000','0.0000','0.00','0.000','2700.0000',19,3,87,3),(88,'4.0000','0.00','1.0000','39200.00','39200.00','4.0000','9800.0000','0.0000','0.00','0.000','13000.0000',8,8,88,7),(89,'48.0000','0.00','24.0000','110400.00','110400.00','2.0000','55200.0000','0.0000','0.00','0.000','1791.6667',4,4,89,3),(90,'180.0000','0.00','60.0000','207000.00','207000.00','3.0000','69000.0000','0.0000','0.00','0.000','916.6667',9,9,90,3),(91,'4.0000','0.00','4.0000','33200.00','33200.00','1.0000','33200.0000','0.0000','0.00','0.000','13000.0000',8,8,91,3),(92,'10.0000','0.00','10.0000','15500.00','15500.00','1.0000','15500.0000','0.0000','0.00','0.000','1180.0000',14,12,92,3),(93,'3.0000','0.00','1.0000','4950.00','4950.00','3.0000','1650.0000','0.0000','0.00','0.000','1041.6667',13,11,93,1),(94,'3.0000','0.00','1.0000','1260.00','1260.00','3.0000','420.0000','0.0000','0.00','0.000','179.1667',12,14,94,1),(95,'4.0000','0.00','1.0000','5800.00','5800.00','4.0000','1450.0000','0.0000','0.00','0.000','916.6667',9,9,95,1),(96,'3.0000','0.00','1.0000','8400.00','8400.00','3.0000','2800.0000','0.0000','0.00','0.000','1791.6667',4,4,96,1),(97,'20.0000','0.00','10.0000','31000.00','31000.00','2.0000','15500.0000','0.0000','0.00','0.000','1180.0000',14,12,97,3),(98,'12.0000','0.00','12.0000','11040.00','11040.00','1.0000','11040.0000','0.0000','0.00','0.000','816.6667',5,5,98,3),(99,'80.0000','0.00','20.0000','212000.00','212000.00','4.0000','53000.0000','0.0000','0.00','0.000','2700.0000',19,3,99,3),(100,'48.0000','1555.00','48.0000','50285.00','50285.00','1.0000','51840.0000','0.0000','0.00','0.000','645.8333',6,6,100,3),(101,'48.0000','0.00','12.0000','93600.00','93600.00','4.0000','23400.0000','0.0000','0.00','0.000','1458.3333',7,7,101,3),(102,'4.0000','0.00','1.0000','18400.00','18400.00','4.0000','4600.0000','0.0000','0.00','0.000','3062.5000',11,13,102,1),(103,'60.0000','0.00','20.0000','27300.00','27300.00','3.0000','9100.0000','0.0000','0.00','0.000','460.0000',15,15,103,3),(104,'20.0000','0.00','20.0000','9100.00','9100.00','1.0000','9100.0000','0.0000','0.00','0.000','460.0000',15,15,104,3),(105,'8.0000','0.00','8.0000','30400.00','30400.00','1.0000','30400.0000','0.0000','0.00','0.000','3062.5000',11,13,105,3),(106,'192.0000','6221.00','48.0000','201139.00','201139.00','4.0000','51840.0000','0.0000','0.00','0.000','645.8333',6,6,106,3),(107,'80.0000','0.00','20.0000','36400.00','36400.00','4.0000','9100.0000','0.0000','0.00','0.000','460.0000',15,15,107,3),(108,'96.0000','0.00','24.0000','220800.00','220800.00','4.0000','55200.0000','0.0000','0.00','0.000','1854.1667',20,4,108,3),(109,'60000.0000','0.00','1.0000','17400000.00','17400000.00','60000.0000','290.0000','0.0000','0.00','0.000','600.0000',27,1,109,1),(110,'10.0000','0.00','1.0000','2450.00','2450.00','10.0000','245.0000','5.0000','0.00','0.000','260.0000',28,1,110,1),(111,'6.0000','0.00','1.0000','19200.00','19200.00','6.0000','3200.0000','0.0000','0.00','0.000','2600.0000',3,3,111,1),(112,'120.0000','0.00','1.0000','50400.00','50400.00','120.0000','420.0000','0.0000','0.00','0.000','179.1667',12,14,111,1),(113,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,111,1),(114,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,111,1),(115,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,111,1),(116,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,111,1),(117,'1.0000','0.00','1.0000','290.00','290.00','1.0000','290.0000','0.0000','0.00','0.000','185.0000',1,1,111,1),(118,'10000.0000','0.00','1.0000','1450000.00','1450000.00','10000.0000','145.0000','1000.0000','0.00','0.000','129.0000',32,17,112,6),(119,'500.0000','25.00','1.0000','199975.00','199975.00','500.0000','400.0000','500.0000','0.00','0.000','300.0000',33,18,113,1),(120,'500.0000','0.00','1.0000','200000.00','200000.00','500.0000','400.0000','100.0000','0.00','0.000','300.0000',33,18,114,1),(121,'1250.0000','0.00','1.0000','81250000.00','81250000.00','1250.0000','65000.0000','0.0000','0.00','0.000','40000.0000',34,19,115,1),(122,'1.0000','0.00','1.0000','450.00','450.00','1.0000','450.0000','0.0000','0.00','0.000','165.0000',2,2,115,1),(123,'1.0000','0.00','1.0000','1150.00','1150.00','1.0000','1150.0000','0.0000','0.00','0.000','816.6667',5,5,115,1),(124,'1.0000','0.00','1.0000','1150.00','1150.00','1.0000','1150.0000','0.0000','0.00','0.000','816.6667',5,5,115,1);

/*Table structure for table `mis_sale_return` */

DROP TABLE IF EXISTS `mis_sale_return`;

CREATE TABLE `mis_sale_return` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `cogs_total` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `net_amount` decimal(18,2) NOT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `refund_amount` decimal(18,2) NOT NULL,
  `return_date` date NOT NULL,
  `return_no` varchar(32) NOT NULL,
  `tax_amount` decimal(18,2) NOT NULL,
  `total` decimal(18,2) NOT NULL,
  `customer_id` bigint(20) NOT NULL,
  `refund_account_id` bigint(20) DEFAULT NULL,
  `sale_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK5xx3ht71npw3c8kpg8tgaiq87` (`return_no`),
  KEY `FKmbjhpog4x1sy8fy40lcx2wmcx` (`customer_id`),
  KEY `FK6uft3mvcxxbp9sxp1islm6phs` (`refund_account_id`),
  KEY `FKc5aeyv0qa36ulh4i5y5cp433x` (`sale_id`),
  CONSTRAINT `FK6uft3mvcxxbp9sxp1islm6phs` FOREIGN KEY (`refund_account_id`) REFERENCES `mis_account` (`id`),
  CONSTRAINT `FKc5aeyv0qa36ulh4i5y5cp433x` FOREIGN KEY (`sale_id`) REFERENCES `mis_sale` (`id`),
  CONSTRAINT `FKmbjhpog4x1sy8fy40lcx2wmcx` FOREIGN KEY (`customer_id`) REFERENCES `mis_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

/*Data for the table `mis_sale_return` */

insert  into `mis_sale_return`(`id`,`cogs_total`,`created_at`,`created_by`,`net_amount`,`notes`,`refund_amount`,`return_date`,`return_no`,`tax_amount`,`total`,`customer_id`,`refund_account_id`,`sale_id`) values (1,'17500.00','2026-10-27 17:09:09.808560',NULL,'23400.00','Customer returned one unit - packaging damaged in transit.','0.00','2026-09-27','SRN-000001','0.00','23400.00',2,NULL,30),(2,'1300.00','2026-10-30 13:32:58.079549','sales','1225.00',NULL,'0.00','2026-10-30','SRN-000002','0.00','1225.00',5,NULL,110),(3,'129000.00','2026-10-30 17:07:27.755593','owner','145000.00',NULL,'125000.00','2026-10-30','SRN-000003','0.00','145000.00',2,1,112),(4,'150000.00','2026-10-30 18:17:42.808808','owner','199975.00',NULL,'0.00','2026-10-30','SRN-000004','0.00','199975.00',14,NULL,113),(5,'30000.00','2026-10-30 19:25:18.038689','owner','40000.00',NULL,'20000.00','2026-10-31','SRN-000005','0.00','40000.00',14,1,114);

/*Table structure for table `mis_sale_return_line` */

DROP TABLE IF EXISTS `mis_sale_return_line`;

CREATE TABLE `mis_sale_return_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `base_qty` decimal(18,4) NOT NULL,
  `net_amount` decimal(18,2) NOT NULL,
  `qty` decimal(18,4) NOT NULL,
  `tax_amount` decimal(18,2) NOT NULL,
  `total` decimal(18,2) NOT NULL,
  `unit_cost` decimal(18,4) NOT NULL,
  `batch_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `sale_line_id` bigint(20) NOT NULL,
  `sale_return_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK4w2txp4cjgqptjwlf3800mv8y` (`batch_id`),
  KEY `FK76w4yl6sy0jqpoiluaku8k6tm` (`product_id`),
  KEY `FK24g0ngjelrg5u4otxp56ly8yo` (`sale_line_id`),
  KEY `FKh0ygm56qnfd5sc3e3ndf3gddb` (`sale_return_id`),
  CONSTRAINT `FK24g0ngjelrg5u4otxp56ly8yo` FOREIGN KEY (`sale_line_id`) REFERENCES `mis_sale_line` (`id`),
  CONSTRAINT `FK4w2txp4cjgqptjwlf3800mv8y` FOREIGN KEY (`batch_id`) REFERENCES `mis_batch` (`id`),
  CONSTRAINT `FK76w4yl6sy0jqpoiluaku8k6tm` FOREIGN KEY (`product_id`) REFERENCES `mis_product` (`id`),
  CONSTRAINT `FKh0ygm56qnfd5sc3e3ndf3gddb` FOREIGN KEY (`sale_return_id`) REFERENCES `mis_sale_return` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

/*Data for the table `mis_sale_return_line` */

insert  into `mis_sale_return_line`(`id`,`base_qty`,`net_amount`,`qty`,`tax_amount`,`total`,`unit_cost`,`batch_id`,`product_id`,`sale_line_id`,`sale_return_id`) values (1,'12.0000','23400.00','1.0000','0.00','23400.00','1458.3333',7,7,30,1),(2,'5.0000','1225.00','5.0000','0.00','1225.00','260.0000',28,1,110,2),(3,'1000.0000','145000.00','1000.0000','0.00','145000.00','129.0000',32,17,118,3),(4,'500.0000','199975.00','500.0000','0.00','199975.00','300.0000',33,18,119,4),(5,'100.0000','40000.00','100.0000','0.00','40000.00','300.0000',33,18,120,5);

/*Table structure for table `mis_sequence` */

DROP TABLE IF EXISTS `mis_sequence`;

CREATE TABLE `mis_sequence` (
  `name` varchar(24) NOT NULL,
  `next_val` bigint(20) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `mis_sequence` */

insert  into `mis_sequence`(`name`,`next_val`) values ('CUSTOMER',2),('EXPENSE',49),('INVOICE',116),('RECEIPT',11),('RETURN',6),('SHIPMENT',2),('STOCKADJ',4),('SUPPAY',7),('VOUCHER',5);

/*Table structure for table `mis_shipment` */

DROP TABLE IF EXISTS `mis_shipment`;

CREATE TABLE `mis_shipment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `arrival_date` date NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `notes` varchar(1000) DEFAULT NULL,
  `payable_amount` decimal(18,2) NOT NULL,
  `shipment_no` varchar(48) NOT NULL,
  `total_cost` decimal(18,2) NOT NULL,
  `supplier_id` bigint(20) NOT NULL,
  `warehouse_id` bigint(20) NOT NULL,
  `container_no` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK5wjj76lrpcjau2bu7oss9v0bk` (`shipment_no`),
  KEY `FKglirssbs7hn25xv7sr5g3ler6` (`supplier_id`),
  KEY `FK8j0fpyhepieo5ai5ghs44g50q` (`warehouse_id`),
  CONSTRAINT `FK8j0fpyhepieo5ai5ghs44g50q` FOREIGN KEY (`warehouse_id`) REFERENCES `mis_warehouse` (`id`),
  CONSTRAINT `FKglirssbs7hn25xv7sr5g3ler6` FOREIGN KEY (`supplier_id`) REFERENCES `mis_supplier` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

/*Data for the table `mis_shipment` */

insert  into `mis_shipment`(`id`,`arrival_date`,`created_at`,`created_by`,`notes`,`payable_amount`,`shipment_no`,`total_cost`,`supplier_id`,`warehouse_id`,`container_no`) values (1,'2026-06-29','2026-10-27 17:09:05.950592',NULL,'20ft, Yantian to Karachi (KICT), cleared and trucked to Lahore.','1800000.00','IMP-001','3524000.00',1,1,'MSKU4417823'),(2,'2026-07-14','2026-10-27 17:09:06.378207',NULL,'40ft HC, Nansha to Karachi (KPT), cleared and trucked to Lahore.','0.00','IMP-002','4297000.00',2,1,'TCLU8830912'),(3,'2026-07-29','2026-10-27 17:09:07.043940',NULL,'40ft, Mersin to Karachi, then Lahore Dry Port.','2500000.00','IMP-003','4817500.00',4,1,'CMAU2257741'),(4,'2026-08-13','2026-10-27 17:09:07.908883',NULL,'20ft, Laem Chabang to Karachi, clearing at Port Qasim.','0.00','IMP-004','1423000.00',5,1,'HLXU6014389'),(5,'2026-08-28','2026-10-27 17:09:08.370046',NULL,'20ft reefer, Jebel Ali to Karachi, cleared and trucked to Lahore.','900000.00','IMP-005','3452000.00',3,1,'OOLU3392760'),(6,'2026-09-12','2026-10-27 17:09:09.043475',NULL,'40ft, Port Klang to Karachi (KICT).','1200000.00','IMP-006','2684000.00',6,1,'MAEU5568124'),(7,'2026-10-02','2026-10-27 17:09:10.057511',NULL,'Repeat order, 20ft via Yantian. Slightly higher unit costs than IMP-001.','0.00','IMP-007','2910500.00',1,1,'EGHU9027153'),(8,'2026-10-15','2026-10-27 17:09:10.492664',NULL,'40ft HC, Nansha to Karachi. Cleared last week.','1100000.00','IMP-008','2707000.00',2,1,'ZIMU1473986'),(9,'2026-10-27','2026-10-27 17:12:49.727341','owner',NULL,'0.00','SHP-000001','66000000.00',2,1,'ABC-CONTAINER'),(10,'2026-10-30','2026-10-30 13:26:07.670463','owner',NULL,'0.00','RN00212','710500.00',3,1,'CNT-005'),(11,'2026-10-30','2026-10-30 16:51:35.671699','owner',NULL,'0.00','BOL-20235','3870000.00',3,1,'LS-197'),(12,'2026-10-30','2026-10-30 17:55:40.929421','owner',NULL,'100000.00','BL-007','1500000.00',3,1,'05'),(13,'2026-11-05','2026-11-05 16:05:28.377604','owner',NULL,'0.00','SHP-002','50000000.00',1,1,'CTN-002-002');

/*Table structure for table `mis_stock_movement` */

DROP TABLE IF EXISTS `mis_stock_movement`;

CREATE TABLE `mis_stock_movement` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `move_date` date NOT NULL,
  `qty` decimal(18,4) NOT NULL,
  `reason` varchar(500) DEFAULT NULL,
  `ref_no` varchar(48) DEFAULT NULL,
  `ref_type` varchar(32) DEFAULT NULL,
  `type` enum('CORRECTION','DAMAGED','MISSING','OTHER_ADJUSTMENT','RECEIPT','SALE','SALE_RETURN') NOT NULL,
  `unit_cost` decimal(18,4) NOT NULL,
  `batch_id` bigint(20) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `warehouse_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `IDXqiqjnfrgmume7ig7o7u7kehpv` (`product_id`),
  KEY `IDX85nuim9fv011x9fv43vmwifqp` (`batch_id`),
  KEY `IDX5gnhqruyyr68xjrtmgdp0l8yn` (`move_date`),
  KEY `FKdlaysggxa21phh8ilhu36c4ax` (`warehouse_id`),
  CONSTRAINT `FK4wgrdyyl0tv3btlj4rapjkmpr` FOREIGN KEY (`batch_id`) REFERENCES `mis_batch` (`id`),
  CONSTRAINT `FKdlaysggxa21phh8ilhu36c4ax` FOREIGN KEY (`warehouse_id`) REFERENCES `mis_warehouse` (`id`),
  CONSTRAINT `FKmxb1ncf3n3qbwrjvvmflixoki` FOREIGN KEY (`product_id`) REFERENCES `mis_product` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=167 DEFAULT CHARSET=utf8;

/*Data for the table `mis_stock_movement` */

insert  into `mis_stock_movement`(`id`,`created_at`,`created_by`,`move_date`,`qty`,`reason`,`ref_no`,`ref_type`,`type`,`unit_cost`,`batch_id`,`product_id`,`warehouse_id`) values (1,'2026-10-27 17:09:05.993374',NULL,'2026-06-29','8000.0000','Stock received','IMP-001','SHIPMENT','RECEIPT','185.0000',1,1,1),(2,'2026-10-27 17:09:05.996733',NULL,'2026-06-29','6000.0000','Stock received','IMP-001','SHIPMENT','RECEIPT','165.0000',2,2,1),(3,'2026-10-27 17:09:05.998746',NULL,'2026-06-29','240.0000','Stock received','IMP-001','SHIPMENT','RECEIPT','2600.0000',3,3,1),(4,'2026-10-27 17:09:06.005758',NULL,'2026-06-29','240.0000','Stock received','IMP-001','SHIPMENT','RECEIPT','1791.6667',4,4,1),(5,'2026-10-27 17:09:06.269661',NULL,'2026-07-07','-80.0000','Sold to Ichhra Super Mart','INV-000001','SALE','SALE','2600.0000',3,3,1),(6,'2026-10-27 17:09:06.324409',NULL,'2026-07-11','-2.0000','Sold to Walk-in Customer','INV-000002','SALE','SALE','185.0000',1,1,1),(7,'2026-10-27 17:09:06.408767',NULL,'2026-07-14','1080.0000','Stock received','IMP-002','SHIPMENT','RECEIPT','816.6667',5,5,1),(8,'2026-10-27 17:09:06.409767',NULL,'2026-07-14','1920.0000','Stock received','IMP-002','SHIPMENT','RECEIPT','645.8333',6,6,1),(9,'2026-10-27 17:09:06.411815',NULL,'2026-07-14','600.0000','Stock received','IMP-002','SHIPMENT','RECEIPT','1458.3333',7,7,1),(10,'2026-10-27 17:09:06.412773',NULL,'2026-07-14','100.0000','Stock received','IMP-002','SHIPMENT','RECEIPT','13000.0000',8,8,1),(11,'2026-10-27 17:09:06.455563',NULL,'2026-07-15','-3.0000','Sold to Walk-in Customer','INV-000003','SALE','SALE','165.0000',2,2,1),(12,'2026-10-27 17:09:06.562073',NULL,'2026-07-17','-4.0000','Sold to Walk-in Customer','INV-000004','SALE','SALE','165.0000',2,2,1),(13,'2026-10-27 17:09:06.610653',NULL,'2026-07-17','-96.0000','Sold to Faisal Kitchen Ware','INV-000005','SALE','SALE','1791.6667',4,4,1),(14,'2026-10-27 17:09:06.691859',NULL,'2026-07-21','-400.0000','Sold to Ichhra Super Mart','INV-000006','SALE','SALE','185.0000',1,1,1),(15,'2026-10-27 17:09:06.738394',NULL,'2026-07-21','-12.0000','Sold to Liberty Home Store','INV-000007','SALE','SALE','13000.0000',8,8,1),(16,'2026-10-27 17:09:06.779675',NULL,'2026-07-23','-12.0000','Sold to Ichhra Super Mart','INV-000008','SALE','SALE','1458.3333',7,7,1),(17,'2026-10-27 17:09:06.836642',NULL,'2026-07-23','-60.0000','Sold to Faisal Kitchen Ware','INV-000009','SALE','SALE','2600.0000',3,3,1),(18,'2026-10-27 17:09:06.883173',NULL,'2026-07-25','-2.0000','Sold to Walk-in Customer','INV-000010','SALE','SALE','645.8333',6,6,1),(19,'2026-10-27 17:09:06.925835',NULL,'2026-07-25','-20.0000','Sold to Shah Alam Electronics Centre','INV-000011','SALE','SALE','2600.0000',3,3,1),(20,'2026-10-27 17:09:07.019233',NULL,'2026-07-27','-3.0000','Sold to Walk-in Customer','INV-000012','SALE','SALE','165.0000',2,2,1),(21,'2026-10-27 17:09:07.051386',NULL,'2026-07-29','4200.0000','Stock received','IMP-003','SHIPMENT','RECEIPT','916.6667',9,9,1),(22,'2026-10-27 17:09:07.052389',NULL,'2026-07-29','450.0000','Stock received','IMP-003','SHIPMENT','RECEIPT','2150.0000',10,10,1),(23,'2026-10-27 17:09:07.087250',NULL,'2026-07-29','-20.0000','Sold to Liberty Home Store','INV-000013','SALE','SALE','2600.0000',3,3,1),(24,'2026-10-27 17:09:07.121792',NULL,'2026-07-29','-1.0000','Sold to Walk-in Customer','INV-000014','SALE','SALE','645.8333',6,6,1),(25,'2026-10-27 17:09:07.193870',NULL,'2026-07-31','-3.0000','Sold to Walk-in Customer','INV-000015','SALE','SALE','2600.0000',3,3,1),(26,'2026-10-27 17:09:07.239955',NULL,'2026-07-31','-180.0000','Sold to Hafeez Mobile Accessories','INV-000016','SALE','SALE','916.6667',9,9,1),(27,'2026-10-27 17:09:07.340970',NULL,'2026-08-02','-4.0000','Sold to Walk-in Customer','INV-000017','SALE','SALE','2600.0000',3,3,1),(28,'2026-10-27 17:09:07.390327',NULL,'2026-08-04','-10.0000','Sold to Al-Madina Traders','INV-000018','SALE','SALE','2150.0000',10,10,1),(29,'2026-10-27 17:09:07.431383',NULL,'2026-08-04','-120.0000','Sold to Model Town Grocers','INV-000019','SALE','SALE','916.6667',9,9,1),(30,'2026-10-27 17:09:07.470906',NULL,'2026-08-06','-40.0000','Sold to DHA Cash & Carry','INV-000020','SALE','SALE','2600.0000',3,3,1),(31,'2026-10-27 17:09:07.509477',NULL,'2026-08-06','-2.0000','Sold to Walk-in Customer','INV-000021','SALE','SALE','165.0000',2,2,1),(32,'2026-10-27 17:09:07.550578',NULL,'2026-08-06','-4.0000','Sold to Brandreth Road Kitchenware','INV-000022','SALE','SALE','13000.0000',8,8,1),(33,'2026-10-27 17:09:07.592607',NULL,'2026-08-08','-60.0000','Sold to DHA Cash & Carry','INV-000023','SALE','SALE','916.6667',9,9,1),(34,'2026-10-27 17:09:07.787278',NULL,'2026-08-10','-3.0000','Sold to Walk-in Customer','INV-000024','SALE','SALE','185.0000',1,1,1),(35,'2026-10-27 17:09:07.831160',NULL,'2026-08-10','-16.0000','Sold to Rehmat General Store','INV-000025','SALE','SALE','13000.0000',8,8,1),(36,'2026-10-27 17:09:07.890898',NULL,'2026-08-12','-12.0000','Sold to Hafeez Mobile Accessories','INV-000026','SALE','SALE','1458.3333',7,7,1),(37,'2026-10-27 17:09:07.915877',NULL,'2026-08-13','240.0000','Stock received','IMP-004','SHIPMENT','RECEIPT','3062.5000',11,13,1),(38,'2026-10-27 17:09:07.915877',NULL,'2026-08-13','3840.0000','Stock received','IMP-004','SHIPMENT','RECEIPT','179.1667',12,14,1),(39,'2026-10-27 17:09:07.951606',NULL,'2026-08-14','-4.0000','Sold to Walk-in Customer','INV-000027','SALE','SALE','185.0000',1,1,1),(40,'2026-10-27 17:09:07.982343',NULL,'2026-08-14','-3.0000','Sold to Walk-in Customer','INV-000028','SALE','SALE','2600.0000',3,3,1),(41,'2026-10-27 17:09:08.058325',NULL,'2026-08-16','-1.0000','Sold to Walk-in Customer','INV-000029','SALE','SALE','1791.6667',4,4,1),(42,'2026-10-27 17:09:08.105642',NULL,'2026-08-18','-24.0000','Sold to Al-Madina Traders','INV-000030','SALE','SALE','1458.3333',7,7,1),(43,'2026-10-27 17:09:08.136643',NULL,'2026-08-18','-2.0000','Sold to Walk-in Customer','INV-000031','SALE','SALE','2600.0000',3,3,1),(44,'2026-10-27 17:09:08.169770',NULL,'2026-08-20','-1.0000','Sold to Walk-in Customer','INV-000032','SALE','SALE','165.0000',2,2,1),(45,'2026-10-27 17:09:08.200773',NULL,'2026-08-20','-4.0000','Sold to Walk-in Customer','INV-000033','SALE','SALE','1458.3333',7,7,1),(46,'2026-10-27 17:09:08.228286',NULL,'2026-08-20','-3.0000','Sold to Walk-in Customer','INV-000034','SALE','SALE','816.6667',5,5,1),(47,'2026-10-27 17:09:08.265603',NULL,'2026-08-22','-96.0000','Sold to Brandreth Road Kitchenware','INV-000035','SALE','SALE','179.1667',12,14,1),(48,'2026-10-27 17:09:08.329730',NULL,'2026-08-26','-4.0000','Sold to Walk-in Customer','INV-000036','SALE','SALE','185.0000',1,1,1),(49,'2026-10-27 17:09:08.377138',NULL,'2026-08-28','1728.0000','Stock received','IMP-005','SHIPMENT','RECEIPT','1041.6667',13,11,1),(50,'2026-10-27 17:09:08.378144',NULL,'2026-08-28','1400.0000','Stock received','IMP-005','SHIPMENT','RECEIPT','1180.0000',14,12,1),(51,'2026-10-27 17:09:08.404740',NULL,'2026-08-28','-192.0000','Sold to Johar Town Bedding Centre','INV-000037','SALE','SALE','645.8333',6,6,1),(52,'2026-10-27 17:09:08.481066',NULL,'2026-08-30','-96.0000','Sold to Shah Alam Electronics Centre','INV-000038','SALE','SALE','179.1667',12,14,1),(53,'2026-10-27 17:09:08.509583',NULL,'2026-08-30','-576.0000','Sold to Model Town Grocers','INV-000039','SALE','SALE','1041.6667',13,11,1),(54,'2026-10-27 17:09:08.537589',NULL,'2026-08-30','-1.0000','Sold to Walk-in Customer','INV-000040','SALE','SALE','185.0000',1,1,1),(55,'2026-10-27 17:09:08.596663',NULL,'2026-09-01','-4.0000','Sold to Walk-in Customer','INV-000041','SALE','SALE','2150.0000',10,10,1),(56,'2026-10-27 17:09:08.676887',NULL,'2026-09-01','-10.0000','Sold to Rehmat General Store','INV-000042','SALE','SALE','2150.0000',10,10,1),(57,'2026-10-27 17:09:08.713448',NULL,'2026-09-01','-3.0000','Sold to Walk-in Customer','INV-000043','SALE','SALE','1458.3333',7,7,1),(58,'2026-10-27 17:09:08.738487',NULL,'2026-09-03','-1.0000','Sold to Walk-in Customer','INV-000044','SALE','SALE','3062.5000',11,13,1),(59,'2026-10-27 17:09:08.764571',NULL,'2026-09-03','-36.0000','Sold to Shah Alam Electronics Centre','INV-000045','SALE','SALE','1458.3333',7,7,1),(60,'2026-10-27 17:09:08.791099',NULL,'2026-09-05','-200.0000','Sold to Brandreth Road Kitchenware','INV-000046','SALE','SALE','185.0000',1,1,1),(61,'2026-10-27 17:09:08.818755',NULL,'2026-09-05','-288.0000','Sold to Rehmat General Store','INV-000047','SALE','SALE','1041.6667',13,11,1),(62,'2026-10-27 17:09:08.847965',NULL,'2026-09-07','-120.0000','Sold to Hafeez Mobile Accessories','INV-000048','SALE','SALE','916.6667',9,9,1),(63,'2026-10-27 17:09:08.904890',NULL,'2026-09-09','-4.0000','Sold to Walk-in Customer','INV-000049','SALE','SALE','165.0000',2,2,1),(64,'2026-10-27 17:09:08.931960',NULL,'2026-09-09','-12.0000','Sold to Shah Alam Electronics Centre','INV-000050','SALE','SALE','13000.0000',8,8,1),(65,'2026-10-27 17:09:08.963860',NULL,'2026-09-11','-4.0000','Sold to Walk-in Customer','INV-000051','SALE','SALE','2150.0000',10,10,1),(66,'2026-10-27 17:09:09.022496',NULL,'2026-09-11','-1.0000','Sold to Walk-in Customer','INV-000052','SALE','SALE','3062.5000',11,13,1),(67,'2026-10-27 17:09:09.051936',NULL,'2026-09-12','4400.0000','Stock received','IMP-006','SHIPMENT','RECEIPT','460.0000',15,15,1),(68,'2026-10-27 17:09:09.051936',NULL,'2026-09-12','1440.0000','Stock received','IMP-006','SHIPMENT','RECEIPT','458.3333',16,16,1),(69,'2026-10-27 17:09:09.074982',NULL,'2026-09-13','-72.0000','Sold to Model Town Grocers','INV-000053','SALE','SALE','179.1667',12,14,1),(70,'2026-10-27 17:09:09.103210',NULL,'2026-09-13','-12.0000','Sold to Brandreth Road Kitchenware','INV-000054','SALE','SALE','1458.3333',7,7,1),(71,'2026-10-27 17:09:09.129755',NULL,'2026-09-13','-3.0000','Sold to Walk-in Customer','INV-000055','SALE','SALE','13000.0000',8,8,1),(72,'2026-10-27 17:09:09.188024',NULL,'2026-09-15','-4.0000','Sold to Walk-in Customer','INV-000056','SALE','SALE','1180.0000',14,12,1),(73,'2026-10-27 17:09:09.213253',NULL,'2026-09-15','-20.0000','Sold to Shah Alam Electronics Centre','INV-000057','SALE','SALE','2150.0000',10,10,1),(74,'2026-10-27 17:09:09.241848',NULL,'2026-09-15','-12.0000','Sold to Shah Alam Electronics Centre','INV-000058','SALE','SALE','458.3333',16,16,1),(75,'2026-10-27 17:09:09.302407',NULL,'2026-09-17','-4.0000','Sold to Walk-in Customer','INV-000059','SALE','SALE','458.3333',16,16,1),(76,'2026-10-27 17:09:09.326792',NULL,'2026-09-17','-20.0000','Sold to Hafeez Mobile Accessories','INV-000060','SALE','SALE','2150.0000',10,10,1),(77,'2026-10-27 17:09:09.353321',NULL,'2026-09-17','-3.0000','3 sets broken during unloading from container','ADJ-000001','ADJUSTMENT','DAMAGED','13000.0000',8,8,1),(78,'2026-10-27 17:09:09.377360',NULL,'2026-09-19','-24.0000','Sold to Model Town Grocers','INV-000061','SALE','SALE','816.6667',5,5,1),(79,'2026-10-27 17:09:09.402345',NULL,'2026-09-19','-100.0000','Sold to Model Town Grocers','INV-000062','SALE','SALE','185.0000',1,1,1),(80,'2026-10-27 17:09:09.430627',NULL,'2026-09-19','-4.0000','Sold to Walk-in Customer','INV-000063','SALE','SALE','645.8333',6,6,1),(81,'2026-10-27 17:09:09.451297',NULL,'2026-09-19','-8.0000','Shortage found on counting - 8 kg short against packing list','ADJ-000002','ADJUSTMENT','MISSING','1180.0000',14,12,1),(82,'2026-10-27 17:09:09.475197',NULL,'2026-09-21','-3.0000','Sold to Walk-in Customer','INV-000064','SALE','SALE','916.6667',9,9,1),(83,'2026-10-27 17:09:09.503211',NULL,'2026-09-21','-3.0000','Sold to Walk-in Customer','INV-000065','SALE','SALE','2150.0000',10,10,1),(84,'2026-10-27 17:09:09.529725',NULL,'2026-09-23','-2.0000','Sold to Walk-in Customer','INV-000066','SALE','SALE','645.8333',6,6,1),(85,'2026-10-27 17:09:09.554355',NULL,'2026-09-23','-32.0000','Sold to Faisal Kitchen Ware','INV-000067','SALE','SALE','3062.5000',11,13,1),(86,'2026-10-27 17:09:09.631486',NULL,'2026-09-25','-36.0000','Sold to Shah Alam Electronics Centre','INV-000068','SALE','SALE','458.3333',16,16,1),(87,'2026-10-27 17:09:09.689050',NULL,'2026-09-25','-4.0000','Sold to Walk-in Customer','INV-000069','SALE','SALE','916.6667',9,9,1),(88,'2026-10-27 17:09:09.729079',NULL,'2026-09-27','-100.0000','Sold to Rehmat General Store','INV-000070','SALE','SALE','185.0000',1,1,1),(89,'2026-10-27 17:09:09.757694',NULL,'2026-09-27','-800.0000','Sold to DHA Cash & Carry','INV-000071','SALE','SALE','165.0000',2,2,1),(90,'2026-10-27 17:09:09.779097',NULL,'2026-09-27','-240.0000','Sold to Liberty Home Store','INV-000072','SALE','SALE','916.6667',9,9,1),(91,'2026-10-27 17:09:09.814565',NULL,'2026-09-27','12.0000','Returned against INV-000030','SRN-000001','RETURN','SALE_RETURN','1458.3333',7,7,1),(92,'2026-10-27 17:09:09.843573',NULL,'2026-09-29','-16.0000','Sold to Al-Noor Attar House','INV-000073','SALE','SALE','3062.5000',11,13,1),(93,'2026-10-27 17:09:09.870932',NULL,'2026-09-29','-1.0000','Sold to Walk-in Customer','INV-000074','SALE','SALE','185.0000',1,1,1),(94,'2026-10-27 17:09:09.900726',NULL,'2026-09-29','-20.0000','Sold to Hafeez Mobile Accessories','INV-000075','SALE','SALE','1180.0000',14,12,1),(95,'2026-10-27 17:09:09.985936',NULL,'2026-10-01','-1.0000','Sold to Walk-in Customer','INV-000076','SALE','SALE','458.3333',16,16,1),(96,'2026-10-27 17:09:10.010888',NULL,'2026-10-01','-144.0000','Sold to Faisal Kitchen Ware','INV-000077','SALE','SALE','1041.6667',13,11,1),(97,'2026-10-27 17:09:10.037853',NULL,'2026-10-01','-24.0000','Sold to Johar Town Bedding Centre','INV-000078','SALE','SALE','179.1667',12,14,1),(98,'2026-10-27 17:09:10.069409',NULL,'2026-10-02','6000.0000','Stock received','IMP-007','SHIPMENT','RECEIPT','192.0000',17,1,1),(99,'2026-10-27 17:09:10.070483',NULL,'2026-10-02','5000.0000','Stock received','IMP-007','SHIPMENT','RECEIPT','172.5000',18,2,1),(100,'2026-10-27 17:09:10.070483',NULL,'2026-10-02','200.0000','Stock received','IMP-007','SHIPMENT','RECEIPT','2700.0000',19,3,1),(101,'2026-10-27 17:09:10.071424',NULL,'2026-10-02','192.0000','Stock received','IMP-007','SHIPMENT','RECEIPT','1854.1667',20,4,1),(102,'2026-10-27 17:09:10.092453',NULL,'2026-10-03','-96.0000','Sold to DHA Cash & Carry','INV-000079','SALE','SALE','645.8333',6,6,1),(103,'2026-10-27 17:09:10.127081',NULL,'2026-10-03','-3.0000','Sold to Walk-in Customer','INV-000080','SALE','SALE','645.8333',6,6,1),(104,'2026-10-27 17:09:10.152857',NULL,'2026-10-03','-30.0000','Sold to Model Town Grocers','INV-000081','SALE','SALE','2150.0000',10,10,1),(105,'2026-10-27 17:09:10.176887',NULL,'2026-10-05','-10.0000','Sold to Brandreth Road Kitchenware','INV-000082','SALE','SALE','1180.0000',14,12,1),(106,'2026-10-27 17:09:10.206210',NULL,'2026-10-05','-48.0000','Sold to Rehmat General Store','INV-000083','SALE','SALE','458.3333',16,16,1),(107,'2026-10-27 17:09:10.235298',NULL,'2026-10-07','-24.0000','Sold to Brandreth Road Kitchenware','INV-000084','SALE','SALE','1791.6667',4,4,1),(108,'2026-10-27 17:09:10.258264',NULL,'2026-10-07','-4.0000','Sold to Walk-in Customer','INV-000085','SALE','SALE','645.8333',6,6,1),(109,'2026-10-27 17:09:10.293887',NULL,'2026-10-09','-288.0000','Sold to Rehmat General Store','INV-000086','SALE','SALE','1041.6667',13,11,1),(110,'2026-10-27 17:09:10.321068',NULL,'2026-10-09','-20.0000','Sold to Liberty Home Store','INV-000087','SALE','SALE','2700.0000',19,3,1),(111,'2026-10-27 17:09:10.344069',NULL,'2026-10-09','-4.0000','Sold to Walk-in Customer','INV-000088','SALE','SALE','13000.0000',8,8,1),(112,'2026-10-27 17:09:10.369785',NULL,'2026-10-11','-48.0000','Sold to Al-Madina Traders','INV-000089','SALE','SALE','1791.6667',4,4,1),(113,'2026-10-27 17:09:10.392603',NULL,'2026-10-11','-180.0000','Sold to Shah Alam Electronics Centre','INV-000090','SALE','SALE','916.6667',9,9,1),(114,'2026-10-27 17:09:10.422184',NULL,'2026-10-13','-4.0000','Sold to Liberty Home Store','INV-000091','SALE','SALE','13000.0000',8,8,1),(115,'2026-10-27 17:09:10.446143',NULL,'2026-10-13','-10.0000','Sold to Model Town Grocers','INV-000092','SALE','SALE','1180.0000',14,12,1),(116,'2026-10-27 17:09:10.498673',NULL,'2026-10-15','600.0000','Stock received','IMP-008','SHIPMENT','RECEIPT','866.6667',21,5,1),(117,'2026-10-27 17:09:10.499670',NULL,'2026-10-15','1440.0000','Stock received','IMP-008','SHIPMENT','RECEIPT','677.0833',22,6,1),(118,'2026-10-27 17:09:10.499670',NULL,'2026-10-15','360.0000','Stock received','IMP-008','SHIPMENT','RECEIPT','1533.3333',23,7,1),(119,'2026-10-27 17:09:10.499670',NULL,'2026-10-15','48.0000','Stock received','IMP-008','SHIPMENT','RECEIPT','13750.0000',24,8,1),(120,'2026-10-27 17:09:10.523904',NULL,'2026-10-15','-3.0000','Sold to Walk-in Customer','INV-000093','SALE','SALE','1041.6667',13,11,1),(121,'2026-10-27 17:09:10.542899',NULL,'2026-10-15','-3.0000','Sold to Walk-in Customer','INV-000094','SALE','SALE','179.1667',12,14,1),(122,'2026-10-27 17:09:10.568188',NULL,'2026-10-15','-4.0000','Sold to Walk-in Customer','INV-000095','SALE','SALE','916.6667',9,9,1),(123,'2026-10-27 17:09:10.594832',NULL,'2026-10-17','-3.0000','Sold to Walk-in Customer','INV-000096','SALE','SALE','1791.6667',4,4,1),(124,'2026-10-27 17:09:10.617437',NULL,'2026-10-17','-20.0000','Sold to Shah Alam Electronics Centre','INV-000097','SALE','SALE','1180.0000',14,12,1),(125,'2026-10-27 17:09:10.642242',NULL,'2026-10-17','-12.0000','Sold to Brandreth Road Kitchenware','INV-000098','SALE','SALE','816.6667',5,5,1),(126,'2026-10-27 17:09:10.820787',NULL,'2026-10-19','-80.0000','Sold to Ichhra Super Mart','INV-000099','SALE','SALE','2700.0000',19,3,1),(127,'2026-10-27 17:09:10.862313',NULL,'2026-10-19','-48.0000','Sold to Rehmat General Store','INV-000100','SALE','SALE','645.8333',6,6,1),(128,'2026-10-27 17:09:10.905320',NULL,'2026-10-21','-48.0000','Sold to Johar Town Bedding Centre','INV-000101','SALE','SALE','1458.3333',7,7,1),(129,'2026-10-27 17:09:10.930676',NULL,'2026-10-21','-4.0000','Sold to Walk-in Customer','INV-000102','SALE','SALE','3062.5000',11,13,1),(130,'2026-10-27 17:09:10.955192',NULL,'2026-10-21','-60.0000','Sold to Al-Madina Traders','INV-000103','SALE','SALE','460.0000',15,15,1),(131,'2026-10-27 17:09:11.006180',NULL,'2026-10-23','-20.0000','Sold to Johar Town Bedding Centre','INV-000104','SALE','SALE','460.0000',15,15,1),(132,'2026-10-27 17:09:11.029777',NULL,'2026-10-23','-8.0000','Sold to Faisal Kitchen Ware','INV-000105','SALE','SALE','3062.5000',11,13,1),(133,'2026-10-27 17:09:11.052440',NULL,'2026-10-23','-192.0000','Sold to Johar Town Bedding Centre','INV-000106','SALE','SALE','645.8333',6,6,1),(134,'2026-10-27 17:09:11.101454',NULL,'2026-10-25','-80.0000','Sold to Al-Madina Traders','INV-000107','SALE','SALE','460.0000',15,15,1),(135,'2026-10-27 17:09:11.130988',NULL,'2026-10-25','-96.0000','Sold to Al-Noor Attar House','INV-000108','SALE','SALE','1854.1667',20,4,1),(136,'2026-10-27 17:12:49.744297','owner','2026-10-27','25000.0000','Stock received','SHP-000001','SHIPMENT','RECEIPT','600.0000',25,2,1),(137,'2026-10-27 17:12:49.744297','owner','2026-10-27','25000.0000','Stock received','SHP-000001','SHIPMENT','RECEIPT','600.0000',26,6,1),(138,'2026-10-27 17:12:49.744297','owner','2026-10-27','60000.0000','Stock received','SHP-000001','SHIPMENT','RECEIPT','600.0000',27,1,1),(139,'2026-10-27 17:15:18.006836','owner','2026-10-27','-60000.0000','Sold to Walk-in Customer','INV-000109','SALE','SALE','600.0000',27,1,1),(140,'2026-10-30 13:26:07.828110','owner','2026-10-30','2500.0000','Stock received','RN00212','SHIPMENT','RECEIPT','260.0000',28,1,1),(141,'2026-10-30 13:26:07.854162','owner','2026-10-30','200.0000','Stock received','RN00212','SHIPMENT','RECEIPT','200.0000',29,2,1),(142,'2026-10-30 13:26:07.857633','owner','2026-10-30','100.0000','Stock received','RN00212','SHIPMENT','RECEIPT','200.0000',30,1,1),(143,'2026-10-30 13:26:07.863099','owner','2026-10-30','10.0000','Stock received','RN00212','SHIPMENT','RECEIPT','50.0000',31,5,1),(144,'2026-10-30 13:31:30.937274','sales','2026-10-30','-10.0000','Sold to Liberty Home Store','INV-000110','SALE','SALE','260.0000',28,1,1),(145,'2026-10-30 13:32:58.104312','sales','2026-10-30','5.0000','Returned against INV-000110','SRN-000002','RETURN','SALE_RETURN','260.0000',28,1,1),(146,'2026-10-30 14:22:57.925710','owner','2026-10-30','-6.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','2600.0000',3,3,1),(147,'2026-10-30 14:22:57.933863','owner','2026-10-30','-120.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','179.1667',12,14,1),(148,'2026-10-30 14:22:57.933863','owner','2026-10-30','-1.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','185.0000',1,1,1),(149,'2026-10-30 14:22:57.933863','owner','2026-10-30','-1.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','185.0000',1,1,1),(150,'2026-10-30 14:22:57.944282','owner','2026-10-30','-1.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','185.0000',1,1,1),(151,'2026-10-30 14:22:57.948137','owner','2026-10-30','-1.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','185.0000',1,1,1),(152,'2026-10-30 14:22:57.950046','owner','2026-10-30','-1.0000','Sold to Walk-in Customer','INV-000111','SALE','SALE','185.0000',1,1,1),(153,'2026-10-30 16:51:35.703229','owner','2026-10-30','30000.0000','Stock received','BOL-20235','SHIPMENT','RECEIPT','129.0000',32,17,1),(154,'2026-10-30 17:02:17.495902','owner','2026-10-30','-10000.0000','Sold to Al-Madina Traders','INV-000112','SALE','SALE','129.0000',32,17,1),(155,'2026-10-30 17:07:27.844550','owner','2026-10-30','1000.0000','Returned against INV-000112','SRN-000003','RETURN','SALE_RETURN','129.0000',32,17,1),(156,'2026-10-30 17:55:40.963545','owner','2026-10-30','5000.0000','Stock received','BL-007','SHIPMENT','RECEIPT','300.0000',33,18,1),(157,'2026-10-30 18:05:36.199195','owner','2026-10-30','-500.0000','Stock Counting was revalued','ADJ-000003','ADJUSTMENT','CORRECTION','300.0000',33,18,1),(158,'2026-10-30 18:16:11.805476','owner','2026-10-30','-500.0000','Sold to Charag Deen Enterprises','INV-000113','SALE','SALE','300.0000',33,18,1),(159,'2026-10-30 18:17:42.843668','owner','2026-10-30','500.0000','Returned against INV-000113','SRN-000004','RETURN','SALE_RETURN','300.0000',33,18,1),(160,'2026-10-30 19:19:50.734048','owner','2026-10-31','-500.0000','Sold to Charag Deen Enterprises','INV-000114','SALE','SALE','300.0000',33,18,1),(161,'2026-10-30 19:25:18.070790','owner','2026-10-31','100.0000','Returned against INV-000114','SRN-000005','RETURN','SALE_RETURN','300.0000',33,18,1),(162,'2026-11-05 16:05:28.410668','owner','2026-11-05','1250.0000','Stock received','SHP-002','SHIPMENT','RECEIPT','40000.0000',34,19,1),(163,'2026-11-05 16:18:12.816821','owner','2026-11-05','-1250.0000','Sold to Walk-in Customer','INV-000115','SALE','SALE','40000.0000',34,19,1),(164,'2026-11-05 16:18:12.816821','owner','2026-11-05','-1.0000','Sold to Walk-in Customer','INV-000115','SALE','SALE','165.0000',2,2,1),(165,'2026-11-05 16:18:12.816821','owner','2026-11-05','-1.0000','Sold to Walk-in Customer','INV-000115','SALE','SALE','816.6667',5,5,1),(166,'2026-11-05 16:18:12.825294','owner','2026-11-05','-1.0000','Sold to Walk-in Customer','INV-000115','SALE','SALE','816.6667',5,5,1);

/*Table structure for table `mis_supplier` */

DROP TABLE IF EXISTS `mis_supplier`;

CREATE TABLE `mis_supplier` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `active` bit(1) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `code` varchar(32) NOT NULL,
  `contact` varchar(200) DEFAULT NULL,
  `country` varchar(96) DEFAULT NULL,
  `name` varchar(200) NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `opening_balance` decimal(18,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKixey2o6jjthnjf2o7ls2m69ds` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

/*Data for the table `mis_supplier` */

insert  into `mis_supplier`(`id`,`active`,`address`,`code`,`contact`,`country`,`name`,`notes`,`opening_balance`) values (1,'','Bao\'an District, Shenzhen (via Yantian port)','SUP-SZ','Mr. Kevin Zhao - +86 755 8266 1180','China','Shenzhen Brightway Electronics Co., Ltd',NULL,'0.00'),(2,'','Baiyun District, Guangzhou (via Nansha port)','SUP-GZ','Ms. Linda Chen - +86 20 8765 4421','China','Guangzhou Greenfield Houseware Trading',NULL,'0.00'),(3,'','Deira, Dubai (via Jebel Ali)','SUP-DXB','Mr. Yousuf Al Mansoori - +971 4 881 2290','UAE','Al Safa General Trading LLC',NULL,'0.00'),(4,'','Bursa / Istanbul (via Mersin port)','SUP-IST','Mr. Emre Kaya - +90 212 555 0143','Turkey','Bosphorus Home Textiles A.S.',NULL,'0.00'),(5,'','Samut Prakan, Bangkok (via Laem Chabang)','SUP-BKK','Khun Somchai - +66 2 123 4567','Thailand','Siam Living Products Co., Ltd',NULL,'0.00'),(6,'','Port Klang, Selangor','SUP-KUL','Mr. Tan Wei Ming - +60 3 3341 7788','Malaysia','Pinnacle Oleo & Home Care Sdn Bhd',NULL,'0.00');

/*Table structure for table `mis_supplier_payment` */

DROP TABLE IF EXISTS `mis_supplier_payment`;

CREATE TABLE `mis_supplier_payment` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `amount` decimal(18,2) NOT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `method` varchar(32) DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `payment_date` date NOT NULL,
  `payment_no` varchar(32) NOT NULL,
  `reference` varchar(96) DEFAULT NULL,
  `account_id` bigint(20) NOT NULL,
  `supplier_id` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKeu3hatlx5itw6kalhi53s2821` (`payment_no`),
  KEY `FKn9gsfxn6pauwogrjqs9vcvewg` (`account_id`),
  KEY `FKcyeh8jkcclq3312qisrax4wc0` (`supplier_id`),
  CONSTRAINT `FKcyeh8jkcclq3312qisrax4wc0` FOREIGN KEY (`supplier_id`) REFERENCES `mis_supplier` (`id`),
  CONSTRAINT `FKn9gsfxn6pauwogrjqs9vcvewg` FOREIGN KEY (`account_id`) REFERENCES `mis_account` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

/*Data for the table `mis_supplier_payment` */

insert  into `mis_supplier_payment`(`id`,`amount`,`created_at`,`created_by`,`method`,`notes`,`payment_date`,`payment_no`,`reference`,`account_id`,`supplier_id`) values (1,'1000000.00','2026-10-27 17:09:06.635597',NULL,'BANK_TRANSFER','Part payment IMP-001','2026-10-27','SPY-000001','TT-88214',2,1),(2,'1500000.00','2026-10-27 17:09:08.070325',NULL,'BANK_TRANSFER','Part payment IMP-003','2026-10-27','SPY-000002','TT-88377',2,4),(3,'500000.00','2026-10-27 17:09:09.276395',NULL,'BANK_TRANSFER','Part payment IMP-005','2026-10-27','SPY-000003','TT-88590',2,3),(4,'700000.00','2026-10-27 17:09:10.400612',NULL,'BANK_TRANSFER','Part payment IMP-006','2026-10-27','SPY-000004','TT-88702',2,6),(5,'100000.00','2026-10-30 19:29:48.016893','owner','BANK_TRANSFER',NULL,'2026-10-31','SPY-000005',NULL,3,3),(6,'200000.00','2026-10-30 19:30:45.040317','owner','BANK_TRANSFER',NULL,'2026-10-31','SPY-000006',NULL,2,3);

/*Table structure for table `mis_unit` */

DROP TABLE IF EXISTS `mis_unit`;

CREATE TABLE `mis_unit` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKr9onn226r18hwlsjf1elwbyc1` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

/*Data for the table `mis_unit` */

insert  into `mis_unit`(`id`,`name`) values (2,'Box'),(3,'Carton'),(5,'Dozen'),(4,'Kg'),(9,'Litre'),(8,'Meter'),(6,'Pack'),(1,'Piece'),(7,'Set');

/*Table structure for table `mis_warehouse` */

DROP TABLE IF EXISTS `mis_warehouse`;

CREATE TABLE `mis_warehouse` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `active` bit(1) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `code` varchar(32) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UKh9t6ikuu4po6w182uctbgrg8b` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

/*Data for the table `mis_warehouse` */

insert  into `mis_warehouse`(`id`,`active`,`address`,`code`,`name`) values (1,'','Lahore, Pakistan','LHR-01','Lahore Main Warehouse');

/*Table structure for table `price_list_entry` */

DROP TABLE IF EXISTS `price_list_entry`;

CREATE TABLE `price_list_entry` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_id` bigint(20) NOT NULL,
  `list_price` double NOT NULL,
  `floor_markup_pct` double NOT NULL,
  `tier_b_pct` double NOT NULL,
  `tier_c_pct` double NOT NULL,
  `tier_d_pct` double NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `item_id` (`item_id`),
  CONSTRAINT `fk_price_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4;

/*Data for the table `price_list_entry` */

insert  into `price_list_entry`(`id`,`item_id`,`list_price`,`floor_markup_pct`,`tier_b_pct`,`tier_c_pct`,`tier_d_pct`) values (1,1,1135,8,2.5,5,3),(2,2,4225,8,2.5,5,3),(3,3,13015,8,2.5,5,3),(4,4,16830,8,2.5,5,3),(5,5,3150,8,2.5,5,3),(6,6,4705,8,2.5,5,3),(7,7,6525,8,2.5,5,3),(8,8,13835,8,2.5,5,3);

/*Table structure for table `purchase_order` */

DROP TABLE IF EXISTS `purchase_order`;

CREATE TABLE `purchase_order` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `supplier_id` bigint(20) NOT NULL,
  `order_date` date NOT NULL,
  `incoterm` varchar(64) NOT NULL,
  `payment_terms` varchar(64) NOT NULL,
  `status` varchar(16) NOT NULL,
  `container_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_po_supplier` (`supplier_id`),
  KEY `fk_po_container` (`container_id`),
  CONSTRAINT `fk_po_container` FOREIGN KEY (`container_id`) REFERENCES `container` (`id`),
  CONSTRAINT `fk_po_supplier` FOREIGN KEY (`supplier_id`) REFERENCES `supplier` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

/*Data for the table `purchase_order` */

insert  into `purchase_order`(`id`,`code`,`supplier_id`,`order_date`,`incoterm`,`payment_terms`,`status`,`container_id`) values (1,'PO-2601',1,'2026-09-17','FOB Guangzhou','LC 60 days','SHIPPED',1),(2,'PO-2602',2,'2026-06-21','FOB Ningbo','TT 30% advance','RECEIVED',2),(3,'PO-2603',3,'2026-07-14','FOB Qingdao','LC at sight','RECEIVED',3),(4,'PO-2604',4,'2026-09-17','FOB Shanghai','LC 90 days','RECEIVED',4),(5,'PO-2605',2,'2026-09-17','FOB Ningbo','TT 30% advance','RECEIVED',5),(6,'PO-2606',1,'2026-09-17','FOB Guangzhou','LC 60 days','SHIPPED',6);

/*Table structure for table `purchase_order_line` */

DROP TABLE IF EXISTS `purchase_order_line`;

CREATE TABLE `purchase_order_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `purchase_order_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `qty` double NOT NULL,
  `fob_unit_price_usd` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_poline_po` (`purchase_order_id`),
  KEY `fk_poline_item` (`item_id`),
  CONSTRAINT `fk_poline_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`),
  CONSTRAINT `fk_poline_po` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_order` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4;

/*Data for the table `purchase_order_line` */

insert  into `purchase_order_line`(`id`,`purchase_order_id`,`item_id`,`qty`,`fob_unit_price_usd`) values (4,2,4,1250,33),(5,2,5,2600,6.1),(6,2,3,560,26),(7,3,6,1800,9.2),(8,3,7,1400,12.8),(15,4,5,3200,6.05),(16,4,4,700,32.4),(17,5,1,5200,2.02),(18,5,2,1100,7.55),(19,6,8,600,21.9),(20,6,3,400,25.6),(21,1,1,4800,1.95),(22,1,2,900,7.4),(23,1,8,420,21.5);

/*Table structure for table `receipt` */

DROP TABLE IF EXISTS `receipt`;

CREATE TABLE `receipt` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `customer_id` bigint(20) NOT NULL,
  `amount_pkr` double NOT NULL,
  `mode` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_receipt_customer` (`customer_id`),
  CONSTRAINT `fk_receipt_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

/*Data for the table `receipt` */

insert  into `receipt`(`id`,`code`,`date`,`customer_id`,`amount_pkr`,`mode`) values (1,'RV-0021','2026-08-18',1,1600000,'Cheque — Meezan 0431'),(2,'RV-0022','2026-08-27',3,3600000,'Bank transfer — HBL'),(3,'RV-0023','2026-09-01',2,900000,'Cheque — UBL 7742'),(4,'RV-0024','2026-09-10',1,2200000,'Bank transfer — Meezan');

/*Table structure for table `receipt_allocation` */

DROP TABLE IF EXISTS `receipt_allocation`;

CREATE TABLE `receipt_allocation` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `receipt_id` bigint(20) NOT NULL,
  `invoice_id` bigint(20) NOT NULL,
  `amount_applied` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_ralloc_receipt` (`receipt_id`),
  KEY `fk_ralloc_invoice` (`invoice_id`),
  CONSTRAINT `fk_ralloc_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `sales_invoice` (`id`),
  CONSTRAINT `fk_ralloc_receipt` FOREIGN KEY (`receipt_id`) REFERENCES `receipt` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4;

/*Data for the table `receipt_allocation` */

insert  into `receipt_allocation`(`id`,`receipt_id`,`invoice_id`,`amount_applied`) values (1,1,1,1600000),(2,2,3,3600000),(3,3,2,900000),(4,4,1,1199550),(5,4,4,1000450);

/*Table structure for table `sales_invoice` */

DROP TABLE IF EXISTS `sales_invoice`;

CREATE TABLE `sales_invoice` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `customer_id` bigint(20) NOT NULL,
  `status` varchar(24) NOT NULL,
  `created_by` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `fk_inv_customer` (`customer_id`),
  CONSTRAINT `fk_inv_customer` FOREIGN KEY (`customer_id`) REFERENCES `customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4;

/*Data for the table `sales_invoice` */

insert  into `sales_invoice`(`id`,`code`,`date`,`customer_id`,`status`,`created_by`) values (1,'INV-0031','2026-08-05',1,'POSTED','seed'),(2,'INV-0032','2026-08-12',2,'POSTED','seed'),(3,'INV-0033','2026-08-20',3,'POSTED','seed'),(4,'INV-0034','2026-08-29',1,'POSTED','seed'),(5,'INV-0035','2026-09-03',4,'POSTED','seed'),(6,'INV-0036','2026-09-09',2,'POSTED','seed');

/*Table structure for table `sales_invoice_line` */

DROP TABLE IF EXISTS `sales_invoice_line`;

CREATE TABLE `sales_invoice_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `invoice_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `container_id` bigint(20) NOT NULL,
  `qty` double NOT NULL,
  `rate_pkr` double NOT NULL,
  `unit_cost_snapshot` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_invline_invoice` (`invoice_id`),
  KEY `fk_invline_item` (`item_id`),
  KEY `fk_invline_container` (`container_id`),
  CONSTRAINT `fk_invline_container` FOREIGN KEY (`container_id`) REFERENCES `container` (`id`),
  CONSTRAINT `fk_invline_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `sales_invoice` (`id`),
  CONSTRAINT `fk_invline_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4;

/*Data for the table `sales_invoice_line` */

insert  into `sales_invoice_line`(`id`,`invoice_id`,`item_id`,`container_id`,`qty`,`rate_pkr`,`unit_cost_snapshot`) values (1,1,1,1,1400,1010,962.4404),(2,1,8,1,90,10650,10324.8418),(3,2,2,1,260,3720,3572.4193),(4,3,5,2,640,3180,2310.3495),(5,3,3,2,120,13400,9714.2366),(6,4,4,2,210,15900,12318.619),(7,4,1,1,900,1040,962.4404),(8,5,6,3,520,4380,3512.9697),(9,5,7,3,300,5950,4869.2676),(10,6,5,2,480,3120,2310.3495),(11,6,4,2,95,16200,12318.619);

/*Table structure for table `stock_entry` */

DROP TABLE IF EXISTS `stock_entry`;

CREATE TABLE `stock_entry` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `date` date NOT NULL,
  `type` varchar(24) NOT NULL,
  `posted_by` varchar(128) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `stock_entry` */

/*Table structure for table `stock_entry_line` */

DROP TABLE IF EXISTS `stock_entry_line`;

CREATE TABLE `stock_entry_line` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `stock_entry_id` bigint(20) NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `container_id` bigint(20) NOT NULL,
  `signed_qty` double NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `unit_cost_snapshot` double NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_seline_entry` (`stock_entry_id`),
  KEY `fk_seline_item` (`item_id`),
  KEY `fk_seline_container` (`container_id`),
  CONSTRAINT `fk_seline_container` FOREIGN KEY (`container_id`) REFERENCES `container` (`id`),
  CONSTRAINT `fk_seline_entry` FOREIGN KEY (`stock_entry_id`) REFERENCES `stock_entry` (`id`),
  CONSTRAINT `fk_seline_item` FOREIGN KEY (`item_id`) REFERENCES `item` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/*Data for the table `stock_entry_line` */

/*Table structure for table `supplier` */

DROP TABLE IF EXISTS `supplier`;

CREATE TABLE `supplier` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `name` varchar(200) NOT NULL,
  `origin_port` varchar(128) NOT NULL,
  `payment_terms` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4;

/*Data for the table `supplier` */

insert  into `supplier`(`id`,`code`,`name`,`origin_port`,`payment_terms`) values (1,'SUP-01','HTM Tools Co. Ltd','Guangzhou, CN','LC 60 days'),(2,'SUP-02','Sunrise Hardware Ind.','Ningbo, CN','TT 30% advance'),(3,'SUP-03','Jinhe Fittings Group','Qingdao, CN','LC at sight'),(4,'SUP-04','Yuhua Electricals','Shanghai, CN','LC 90 days');

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
