/* Test: every National budget week matches exactly one event.
   Why : National rows are assigned to an event_key by name + date window. A row
         matching no event (typo, wrong dates) is silently dropped; a row
         matching two events is double-counted.
   Pass: returns 0 rows. */
SELECT
  n.event_name,
  n.week_start,
  COUNT(DISTINCT e.event_key) AS matched_events
FROM `your-project.marketing_analytics.stg_national_budget_weekly` n
LEFT JOIN `your-project.marketing_analytics.stg_events` e
  ON n.event_name = e.event_name
 AND n.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
GROUP BY 1, 2
HAVING COUNT(DISTINCT e.event_key) <> 1;
