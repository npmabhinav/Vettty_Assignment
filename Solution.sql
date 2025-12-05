-- SQL Test Answers (MySQL 8+)
-- Author: <Kushwaha Abhinav Ranjan>   
-- Assumptions:
--  1) transactions has columns: buyer_id, purchase_time (TIMESTAMP), refund_time (TIMESTAMP, nullable),
--     refund_item, store_id, item_id, gross_transaction_value (DECIMAL).
--  2) items has columns: store_id, item_id, item_category, item_name.
--  3) Refund exists when refund_time IS NOT NULL.
--  4) MySQL version >= 8.0 (for window functions).



-- 1) COUNT OF PURCHASES PER MONTH (EXCLUDING REFUNDED PURCHASES 
--Approach: exclude transactions with a non-null refund_time (these are refunded). Group remaining transactions by month (use DATE_FORMAT to normalize to month) and count.

SELECT
  DATE_FORMAT(purchase_time, '%Y-%m-01') AS month_start,
  COUNT(*) AS purchases_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY DATE_FORMAT(purchase_time, '%Y-%m')
ORDER BY month_start;



-- 2) HOW MANY STORES RECEIVE AT LEAST 5 TRANSACTIONS IN OCT 2020?
--Approach: filter by purchase_time within Oct 2020, group by store_id, count transactions per store, and count how many stores have COUNT(*) >= 5.

SELECT
  COUNT(*) AS stores_with_at_least_5_in_oct_2020
FROM (
  SELECT store_id, COUNT(*) AS tx_count
  FROM transactions
  WHERE purchase_time >= '2020-10-01'
    AND purchase_time <  '2020-11-01'
  GROUP BY store_id
  HAVING COUNT(*) >= 5
) AS s;



-- 3) FOR EACH STORE: SHORTEST INTERVAL (IN MINUTES) FROM PURCHASE TO REFUND
--Approach: consider only rows where refund_time IS NOT NULL. Compute interval in minutes using TIMESTAMPDIFF(MINUTE, purchase_time, refund_time) and take the minimum per store_id.

SELECT
  store_id,
  MIN(TIMESTAMPDIFF(MINUTE, purchase_time, refund_time)) AS min_minutes_to_refund
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id
ORDER BY store_id;



-- 4) GROSS_TRANSACTION_VALUE OF EVERY STORE'S FIRST ORDER
--Approach: for each store_id, rank transactions by purchase_time ascending using ROW_NUMBER() window function and pick the row with rn = 1 (earliest purchase). Return its gross_transaction_value.

WITH ranked_by_store AS (
  SELECT
    store_id,
    purchase_time,
    gross_transaction_value,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time ASC) AS rn
  FROM transactions
)
SELECT
  store_id,
  purchase_time AS first_purchase_time,
  gross_transaction_value AS first_order_gross_value
FROM ranked_by_store
WHERE rn = 1
ORDER BY store_id;


-- 5) MOST POPULAR ITEM_NAME THAT BUYERS ORDER ON THEIR FIRST PURCHASE
--Approach: identify each buyer’s first transaction (ROW_NUMBER() partitioned by buyer_id). Join those first-purchase rows to items on (store_id, item_id) to get item_name. Count frequencies and return the top 1.

WITH buyer_first_purchase AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
  FROM transactions t
)
, first_purchases AS (
  SELECT *
  FROM buyer_first_purchase
  WHERE rn = 1
)
SELECT
  COALESCE(i.item_name, 'UNKNOWN') AS item_name,
  COUNT(*) AS times_ordered_on_first_purchase
FROM first_purchases fp
LEFT JOIN items i
  ON fp.store_id = i.store_id
  AND fp.item_id  = i.item_id
GROUP BY i.item_name
ORDER BY times_ordered_on_first_purchase DESC
LIMIT 1;


-- 6) FLAG: WHETHER A REFUND CAN BE PROCESSED (WITHIN 72 HOURS)
--Approach: A refund can be processed only if refund_time exists and the difference between purchase_time and refund_time is ≤ 72 hours. Use TIMESTAMPDIFF(HOUR, ...) <= 72. Produce a flag column refund_allowed_within_72hrs (1 = allowed, 0 = not allowed).

SELECT
  *,
  CASE
    WHEN refund_time IS NULL THEN 0
    WHEN TIMESTAMPDIFF(HOUR, purchase_time, refund_time) <= 72 THEN 1
    ELSE 0
  END AS refund_allowed_within_72hrs
FROM transactions
ORDER BY purchase_time;




-- 7) RANK BY buyer_id AND RETURN ONLY THE SECOND PURCHASE PER BUYER (IGNORE REFUNDS)
--Approach: exclude refunded transactions (refund_time IS NULL), then use ROW_NUMBER() partitioned by buyer_id ordered by purchase_time to rank purchases. Filter purchase_rank = 2.
WITH ranked_non_refunded AS (
  SELECT
    t.*,
    ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS purchase_rank
  FROM transactions t
  WHERE refund_time IS NULL
)
SELECT
  buyer_id,
  purchase_time,
  store_id,
  item_id,
  gross_transaction_value
FROM ranked_non_refunded
WHERE purchase_rank = 2
ORDER BY buyer_id;



-- 8) FIND THE SECOND TRANSACTION TIME PER BUYER (DON'T USE MIN/MAX)
--Approach: use ROW_NUMBER() partitioned by buyer_id ordered by purchase_time and select rows where rn = 2. This returns the exact timestamp of the second purchase for each buyer.

WITH rn AS (
  SELECT
    buyer_id,
    purchase_time,
    ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time ASC) AS rn
  FROM transactions
)
SELECT
  buyer_id,
  purchase_time AS second_purchase_time
FROM rn
WHERE rn = 2
ORDER BY buyer_id;

