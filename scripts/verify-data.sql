-- Data Integrity Checks for Medusa v2
-- Run via: psql $DATABASE_URL -f verify-data.sql

-- 1. Orphaned products (no variants)
SELECT 'orphaned_products' AS check_name, count(*) AS count
FROM product p
LEFT JOIN product_variant pv ON pv.product_id = p.id
WHERE pv.id IS NULL AND p.deleted_at IS NULL;

-- 2. Variants without prices
SELECT 'variants_no_prices' AS check_name, count(*) AS count
FROM product_variant pv
LEFT JOIN product_variant_price_set pvps ON pvps.variant_id = pv.id
WHERE pvps.id IS NULL AND pv.deleted_at IS NULL;

-- 3. Ledger pair integrity (every pair_id must have exactly 2 entries)
SELECT 'bad_ledger_pairs' AS check_name, count(*) AS count
FROM (
  SELECT pair_id, count(*) as entry_count
  FROM inventory_ledger_entry
  WHERE pair_id IS NOT NULL AND deleted_at IS NULL
  GROUP BY pair_id
  HAVING count(*) != 2
) bad_pairs;

-- 4. Ledger pairs that don't sum to zero
SELECT 'unbalanced_ledger_pairs' AS check_name, count(*) AS count
FROM (
  SELECT pair_id, sum(signed_quantity) AS net
  FROM inventory_ledger_entry
  WHERE pair_id IS NOT NULL AND deleted_at IS NULL
  GROUP BY pair_id
  HAVING sum(signed_quantity) != 0
) unbalanced;

-- 5. Stuck intakes (processing for >1 hour)
SELECT 'stuck_intakes' AS check_name, count(*) AS count
FROM intake
WHERE status = 'processing'
  AND updated_at < NOW() - INTERVAL '1 hour';

-- 6. Intakes in invalid status
SELECT 'invalid_intake_status' AS check_name, count(*) AS count
FROM intake
WHERE status NOT IN ('draft', 'processing', 'completed', 'voided');
