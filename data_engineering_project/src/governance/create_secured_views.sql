-- =============================================================================
-- Data Governance & Security: Secure Dynamic Views
-- Catalog: dev
--
-- Security model:
--   data_engineers : unrestricted access for engineering/debugging
--   executives     : unrestricted analytics access where appropriate
--   sales_us       : US sales rows
--   sales_eu       : EU sales rows
--   sales_apac     : APAC sales rows
--   analysts       : masked PII + region-filtered sales through secure views
-- =============================================================================

USE CATALOG IDENTIFIER(:catalog);

-- =============================================================================
-- 1. SECURE CUSTOMER VIEW
--    Masks email and phone for analysts.
-- =============================================================================

CREATE OR REPLACE VIEW IDENTIFIER(:catalog || '.gold.customers_secure') AS
SELECT
    id AS customer_id,
    name,
    CASE
        WHEN is_account_group_member('data_engineers')
             OR is_account_group_member('executives')
        THEN email
        ELSE
            CASE
                WHEN email IS NULL THEN NULL
                WHEN instr(email, '@') > 0
                    THEN concat('***@', regexp_extract(email, '@(.*)$', 1))
                ELSE '***'
            END
    END AS email,
    city,
    state,
    signup_date,
    CASE
        WHEN is_account_group_member('data_engineers')
             OR is_account_group_member('executives')
        THEN phone
        ELSE
            CASE
                WHEN phone IS NULL THEN NULL
                WHEN length(regexp_replace(phone, '[^0-9]', '')) >= 4
                    THEN concat(
                        '***-***-',
                        right(regexp_replace(phone, '[^0-9]', ''), 4)
                    )
                ELSE '***'
            END
    END AS phone
FROM IDENTIFIER(:catalog || '.silver.customers_clean');

COMMENT ON VIEW IDENTIFIER(:catalog || '.gold.customers_secure') IS
'Secure customer view. Exposes customer analytics attributes while dynamically masking email and phone for users outside the data_engineers/executives groups.';

-- =============================================================================
-- 2. SECURE SUPPLIER VIEW
--    Masks supplier contact email for non-privileged users.
-- =============================================================================

CREATE OR REPLACE VIEW IDENTIFIER(:catalog || '.gold.suppliers_secure') AS
SELECT
    supplier_id,
    supplier_name,
    CASE
        WHEN is_account_group_member('data_engineers')
             OR is_account_group_member('executives')
        THEN contact_email
        ELSE
            CASE
                WHEN contact_email IS NULL THEN NULL
                WHEN instr(contact_email, '@') > 0
                    THEN concat('***@', regexp_extract(contact_email, '@(.*)$', 1))
                ELSE '***'
            END
    END AS contact_email,
    country,
    effective_date,
    end_date,
    is_current,
    version
FROM IDENTIFIER(:catalog || '.silver.suppliers_scd2')
WHERE
    is_current = true
    OR is_account_group_member('data_engineers')
    OR is_account_group_member('executives');

COMMENT ON VIEW IDENTIFIER(:catalog || '.gold.suppliers_secure') IS
'Secure current supplier view. Contact email is fully visible to data engineers and executives and masked for other users. Historical versions remain available only to privileged users.';

-- =============================================================================
-- 3. SECURE SALES VIEW
--    Row-level security by region + no direct PII exposure.
-- =============================================================================

CREATE OR REPLACE VIEW IDENTIFIER(:catalog || '.gold.sales_secure') AS
SELECT
    sale_id,
    customer_id,
    product_id,
    quantity,
    sale_amount,
    sale_date,
    region
FROM IDENTIFIER(:catalog || '.silver.sales_clean')
WHERE
    is_account_group_member('data_engineers')
    OR is_account_group_member('executives')
    OR (is_account_group_member('sales_us') AND region = 'US')
    OR (is_account_group_member('sales_eu') AND region = 'EU')
    OR (is_account_group_member('sales_apac') AND region = 'APAC');

COMMENT ON VIEW IDENTIFIER(:catalog || '.gold.sales_secure') IS
'Secure sales transaction view with dynamic row-level filtering by sales region. Data engineers and executives see all rows; regional sales groups see only their assigned region.';

-- =============================================================================
-- 4. SECURE CUSTOMER METRICS VIEW
--    Masks the customer name for non-privileged users.
--    This view is useful when analysts need CLV metrics but do not need
--    customer-identifying information.
-- =============================================================================

CREATE OR REPLACE VIEW IDENTIFIER(:catalog || '.gold.customer_metrics_secure') AS
SELECT
    customer_id,
    CASE
        WHEN is_account_group_member('data_engineers')
             OR is_account_group_member('executives')
        THEN customer_name
        ELSE 'REDACTED'
    END AS customer_name,
    state,
    first_order_date,
    last_order_date,
    lifetime_value,
    total_orders,
    avg_order_value,
    customer_segment
FROM IDENTIFIER(:catalog || '.gold.customer_metrics');

COMMENT ON VIEW IDENTIFIER(:catalog || '.gold.customer_metrics_secure') IS
'Secure customer metrics view. Customer name is restricted to privileged groups while lifetime value, ordering metrics, and segmentation remain available for analytics.';

