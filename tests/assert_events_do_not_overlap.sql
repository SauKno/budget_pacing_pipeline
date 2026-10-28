/* Test: events must not share a week.
   Why : Co-op budget has no event column and is assigned to events by date.
         If two events' windows (padded 6 days for weeks starting before the
         event) overlap, a Co-op week could be counted in both.
   Pass: returns 0 rows. */
SELECT
  a.event_key AS event_a,
  b.event_key AS event_b
FROM `your-project.marketing_analytics.stg_events` a
JOIN `your-project.marketing_analytics.stg_events` b
  ON a.event_key < b.event_key
 AND DATE_SUB(a.start_date, INTERVAL 6 DAY) <= b.end_date
 AND DATE_SUB(b.start_date, INTERVAL 6 DAY) <= a.end_date;
