{{
  config(
    materialized = 'view',
    )
}}
with
  data as (select * from {{ ref('load_ticket_scrape_data') }})
select
  * EXCEPT (
    alternate_ids,
    charges,
    sellable_quantities
  ),
  ARRAY_TO_STRING(
    ARRAY(
      SELECT
        CAST(value AS STRING)
      FROM UNNEST(sellable_quantities) value
    ),
    ','
  ) as sellable_quantities
from
  data