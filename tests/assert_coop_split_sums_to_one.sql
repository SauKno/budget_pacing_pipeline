/* Test: each Co-op channel split (default and each override) sums to 1.0.
   Why : A split of 50% / 40% would silently drop 10% of Co-op budget.
   Pass: returns 0 rows. */
SELECT
  COALESCE(event_key, 'DEFAULT') AS split_for,
  SUM(split_pct)                 AS total_split
FROM `your-project.marketing_analytics.cfg_coop_channel_split`
GROUP BY 1
HAVING ABS(SUM(split_pct) - 1) > 1e-9;
