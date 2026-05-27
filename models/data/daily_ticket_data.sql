with
  data as (select * from {{ ref('load_ticket_scrape_data') }})
select
  date(_batch_timestamp) as date,
  *
from
  data
qualify row_number() over (
  partition by event_id, listing_id, listing_version_id, offer_id, ticket_type_id
  order by _batch_timestamp desc
) = 1
