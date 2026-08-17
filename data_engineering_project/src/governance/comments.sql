-- =============================================================================
-- Data Governance: Table / Column Comments + Unity Catalog Tags
-- Catalog: dev
--
-- Source objects confirmed from the repository:
--   Silver: customers_clean, products_scd2, sales_clean, suppliers_scd2
--   Gold:   customer_metrics, daily_kpis, product_analytics, sales_summary
-- =============================================================================

USE CATALOG IDENTIFIER(:catalog);

-- =============================================================================
-- SILVER: CUSTOMERS
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).silver.customers_clean IS
'Cleaned customer master data. One current customer record per customer ID. Contains direct PII including email address and phone number.';

ALTER TABLE IDENTIFIER(:catalog).silver.customers_clean
ALTER COLUMN
    id COMMENT 'Unique customer identifier; business key for the customer record',
    name COMMENT 'Customer full name; personally identifiable information',
    email COMMENT 'Customer email address; direct PII and restricted from general analytics users',
    city COMMENT 'Customer city of residence',
    state COMMENT 'Customer state or administrative region',
    signup_date COMMENT 'Date on which the customer registered',
    phone COMMENT 'Customer telephone number; direct PII and restricted from general analytics users';

ALTER TABLE IDENTIFIER(:catalog).silver.customers_clean
SET TAGS (
    'data_classification' = 'confidential',
    'pii_level' = 'high',
    'domain' = 'customer',
    'layer' = 'silver'
);

ALTER TABLE IDENTIFIER(:catalog).silver.customers_clean
ALTER COLUMN email
SET TAGS (
    'pii_type' = 'email',
    'pii_level' = 'high'
);

ALTER TABLE IDENTIFIER(:catalog).silver.customers_clean
ALTER COLUMN phone
SET TAGS (
    'pii_type' = 'phone',
    'pii_level' = 'high'
);

-- =============================================================================
-- SILVER: PRODUCTS (SCD TYPE 2)
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).silver.products_scd2 IS
'Product master history maintained using Slowly Changing Dimension Type 2. Stores current and historical product versions with effective and end dates.';

ALTER TABLE IDENTIFIER(:catalog).silver.products_scd2
ALTER COLUMN
    product_id COMMENT 'Unique product identifier',
    product_name COMMENT 'Business name of the product',
    category COMMENT 'Product category used for product analytics and revenue grouping',
    price COMMENT 'Product selling price captured for the corresponding SCD2 version',
    supplier_id COMMENT 'Identifier of the supplier associated with the product version',
    effective_date COMMENT 'Date on which this product version became effective',
    end_date COMMENT 'Date on which this product version stopped being effective; NULL for the active version',
    is_current COMMENT 'Boolean flag indicating whether this is the current product version',
    version COMMENT 'Sequential SCD2 version number for the product';

ALTER TABLE IDENTIFIER(:catalog).silver.products_scd2
SET TAGS (
    'data_classification' = 'internal',
    'pii_level' = 'none',
    'domain' = 'product',
    'layer' = 'silver',
    'history_type' = 'scd2'
);

-- =============================================================================
-- SILVER: SALES
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).silver.sales_clean IS
'Cleaned sales transaction data used as the primary Silver-layer sales fact. Contains transaction identifiers, customer/product references, amounts, dates, and sales regions.';

ALTER TABLE IDENTIFIER(:catalog).silver.sales_clean
ALTER COLUMN
    sale_id COMMENT 'Unique identifier for the sale transaction',
    customer_id COMMENT 'Identifier of the customer associated with the transaction',
    product_id COMMENT 'Identifier of the product sold',
    quantity COMMENT 'Number of units sold in the transaction',
    sale_amount COMMENT 'Total monetary amount of the sale transaction',
    sale_date COMMENT 'Business date of the sale',
    region COMMENT 'Sales region used for regional reporting and row-level security';

ALTER TABLE IDENTIFIER(:catalog).silver.sales_clean
SET TAGS (
    'data_classification' = 'internal',
    'pii_level' = 'none',
    'domain' = 'sales',
    'layer' = 'silver'
);

ALTER TABLE IDENTIFIER(:catalog).silver.sales_clean
ALTER COLUMN customer_id
SET TAGS (
    'identifier_type' = 'indirect_customer_identifier',
    'pii_level' = 'medium'
);

-- =============================================================================
-- SILVER: SUPPLIERS (SCD TYPE 2)
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).silver.suppliers_scd2 IS
'Supplier master history maintained using Slowly Changing Dimension Type 2. Contains supplier identity, contact email, country, and historical validity periods.';

ALTER TABLE IDENTIFIER(:catalog).silver.suppliers_scd2
ALTER COLUMN
    supplier_id COMMENT 'Unique supplier identifier',
    supplier_name COMMENT 'Business name of the supplier',
    contact_email COMMENT 'Supplier contact email address; direct contact information',
    country COMMENT 'Supplier country',
    effective_date COMMENT 'Date on which this supplier version became effective',
    end_date COMMENT 'Date on which this supplier version stopped being effective; NULL for the active version',
    is_current COMMENT 'Boolean flag indicating whether this is the current supplier version',
    version COMMENT 'Sequential SCD2 version number for the supplier';

ALTER TABLE IDENTIFIER(:catalog).silver.suppliers_scd2
SET TAGS (
    'data_classification' = 'confidential',
    'pii_level' = 'medium',
    'domain' = 'supplier',
    'layer' = 'silver',
    'history_type' = 'scd2'
);

ALTER TABLE IDENTIFIER(:catalog).silver.suppliers_scd2
ALTER COLUMN contact_email
SET TAGS (
    'pii_type' = 'email',
    'pii_level' = 'high'
);

-- =============================================================================
-- GOLD: CUSTOMER METRICS
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).gold.customer_metrics IS
'Customer-level analytics and customer lifetime value metrics derived from cleaned sales and customer data. Contains customer identity attributes and aggregated financial measures.';

ALTER TABLE IDENTIFIER(:catalog).gold.customer_metrics
ALTER COLUMN
    customer_id COMMENT 'Unique customer identifier',
    customer_name COMMENT 'Customer full name carried into the analytical layer',
    state COMMENT 'Customer state used for geographic analysis',
    first_order_date COMMENT 'Date of the customer''s first recorded order',
    last_order_date COMMENT 'Date of the customer''s most recent recorded order',
    lifetime_value COMMENT 'Cumulative customer revenue across recorded orders in USD',
    total_orders COMMENT 'Total number of recorded orders for the customer',
    avg_order_value COMMENT 'Average monetary value per customer order in USD',
    customer_segment COMMENT 'Customer lifecycle segment: new, returning, or loyal';

ALTER TABLE IDENTIFIER(:catalog).gold.customer_metrics
SET TAGS (
    'data_classification' = 'confidential',
    'pii_level' = 'medium',
    'domain' = 'customer_analytics',
    'layer' = 'gold'
);

ALTER TABLE IDENTIFIER(:catalog).gold.customer_metrics
ALTER COLUMN customer_id
SET TAGS ('pii_level' = 'medium', 'identifier_type' = 'customer_identifier');

ALTER TABLE IDENTIFIER(:catalog).gold.customer_metrics
ALTER COLUMN customer_name
SET TAGS ('pii_level' = 'medium', 'pii_type' = 'name');

-- =============================================================================
-- GOLD: DAILY KPIs
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).gold.daily_kpis IS
'Daily sales KPIs including revenue, order counts, rolling revenue averages, and cumulative totals. Designed for executive and operational reporting.';

ALTER TABLE IDENTIFIER(:catalog).gold.daily_kpis
ALTER COLUMN
    sale_date COMMENT 'Calendar date represented by the KPI record',
    daily_revenue COMMENT 'Total revenue generated on the day in USD',
    daily_orders COMMENT 'Total number of sales orders on the day',
    revenue_7day_avg COMMENT 'Seven-day rolling average of daily revenue in USD',
    revenue_30day_avg COMMENT 'Thirty-day rolling average of daily revenue in USD',
    running_total_revenue COMMENT 'Cumulative revenue from the beginning of the available sales period in USD',
    running_total_orders COMMENT 'Cumulative number of sales orders from the beginning of the available sales period';

ALTER TABLE IDENTIFIER(:catalog).gold.daily_kpis
SET TAGS (
    'data_classification' = 'internal',
    'pii_level' = 'none',
    'domain' = 'sales_kpi',
    'layer' = 'gold'
);

-- =============================================================================
-- GOLD: PRODUCT ANALYTICS
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).gold.product_analytics IS
'Product-level revenue and volume analytics joined with the current product and supplier dimensions.';

ALTER TABLE IDENTIFIER(:catalog).gold.product_analytics
ALTER COLUMN
    product_id COMMENT 'Unique product identifier',
    product_name COMMENT 'Business name of the product',
    category COMMENT 'Product category',
    supplier_id COMMENT 'Unique supplier identifier for the current product version',
    supplier_name COMMENT 'Supplier business name',
    total_units_sold COMMENT 'Total units sold for the product',
    total_revenue COMMENT 'Total sales revenue attributed to the product in USD',
    category_revenue_share_pct COMMENT 'Percentage of category revenue contributed by the product',
    revenue_percentile COMMENT 'Relative revenue percentile of the product within its category';

ALTER TABLE IDENTIFIER(:catalog).gold.product_analytics
SET TAGS (
    'data_classification' = 'internal',
    'pii_level' = 'none',
    'domain' = 'product_analytics',
    'layer' = 'gold'
);

-- =============================================================================
-- GOLD: SALES SUMMARY
-- =============================================================================

COMMENT ON TABLE IDENTIFIER(:catalog).gold.sales_summary IS
'Monthly sales summary by region and product category with prior-year revenue and year-over-year growth metrics.';

ALTER TABLE IDENTIFIER(:catalog).gold.sales_summary
ALTER COLUMN
    region COMMENT 'Sales region; used for regional reporting and row-level security',
    category COMMENT 'Product category used for sales segmentation',
    sale_year COMMENT 'Calendar year of the summarized sales period',
    sale_month COMMENT 'Calendar month number of the summarized sales period',
    total_revenue COMMENT 'Total sales revenue for the region/category/month combination in USD',
    total_orders COMMENT 'Total sales orders for the region/category/month combination',
    prior_year_revenue COMMENT 'Revenue for the same region/category/month in the prior year, when available',
    yoy_growth_pct COMMENT 'Year-over-year revenue growth percentage';

ALTER TABLE IDENTIFIER(:catalog).gold.sales_summary
SET TAGS (
    'data_classification' = 'internal',
    'pii_level' = 'none',
    'domain' = 'sales_analytics',
    'layer' = 'gold',
    'security_model' = 'region_restricted'
);

-- =============================================================================
-- VALIDATION
-- =============================================================================
-- Run after the script to verify metadata:
--
DESCRIBE TABLE EXTENDED dev.silver.customers_clean;
DESCRIBE TABLE EXTENDED dev.silver.products_scd2;
DESCRIBE TABLE EXTENDED dev.silver.sales_clean;
DESCRIBE TABLE EXTENDED dev.silver.suppliers_scd2;
DESCRIBE TABLE EXTENDED dev.gold.customer_metrics;
DESCRIBE TABLE EXTENDED dev.gold.daily_kpis;
DESCRIBE TABLE EXTENDED dev.gold.product_analytics;
DESCRIBE TABLE EXTENDED dev.gold.sales_summary;

-- Optional UC metadata checks:
SELECT * FROM dev.information_schema.table_tags;
SELECT * FROM dev.information_schema.column_tags;
-- =============================================================================