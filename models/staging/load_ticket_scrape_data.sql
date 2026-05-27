{{ config(
    materialized="incremental",
    tags = ['incremental'],
    docs={'node_color': 'DeepSkyBlue'},
    unique_key = 'grain_hash_id',
    on_schema_change = 'fail',
    cluster_by = ['grain_hash_id']
) }}

WITH source AS (
  SELECT
    *
  FROM
   {{ source('tickets', 'seats') }}
  {% if is_incremental() %}
  {# Load only the latest and new rows of data from the data lake #}
  WHERE
    _batch_timestamp > (SELECT MAX(_batch_timestamp) FROM {{ this }})
  {% endif %}
),

extract_from_json AS (
  SELECT
    JSON_EXTRACT_SCALAR(payload, '$.event.id') AS event_id,
    JSON_EXTRACT_SCALAR(payload, '$.listingId') AS listing_id,
    JSON_EXTRACT_SCALAR(payload, '$.listingVersionId') AS listing_version_id,
    JSON_EXTRACT_SCALAR(payload, '$.offerId') AS offer_id,
    JSON_EXTRACT_SCALAR(payload, '$.ticketTypeId') AS ticket_type_id,
    -- Event Struct
    STRUCT(
      PARSE_TIMESTAMP("%FT%H:%M:%E*S%Ez", JSON_EXTRACT_SCALAR(payload, '$.event.date')) AS date,
      JSON_EXTRACT_SCALAR(payload, '$.event.id') AS id,
      JSON_EXTRACT_SCALAR(payload, '$.event.title') AS title,
      JSON_EXTRACT_SCALAR(payload, '$.event.url') AS url,
      JSON_EXTRACT_SCALAR(payload, '$.event.venue') AS venue
    ) AS event,


    -- Top level scalars
    JSON_EXTRACT_SCALAR(payload, '$.inventoryType') AS inventory_type,
    JSON_EXTRACT_SCALAR(payload, '$.section') AS section,
    JSON_EXTRACT_SCALAR(payload, '$.row') AS row,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.seatFrom') AS INT64) AS seat_from,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.seatTo') AS INT64) AS seat_to,
    ARRAY(
      SELECT CAST(JSON_VALUE(quantity) AS INT64)
      FROM UNNEST(JSON_EXTRACT_ARRAY(payload, '$.sellableQuantities')) AS quantity
    ) AS sellable_quantities,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.faceValue') AS FLOAT64) AS face_value,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.listPrice') AS FLOAT64) AS list_price,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.totalPrice') AS FLOAT64) AS total_price,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.noChargesPrice') AS FLOAT64) AS no_charges_price,
    ARRAY(
      SELECT STRUCT(
        CAST(JSON_EXTRACT_SCALAR(chg, '$.amount') AS FLOAT64) AS amount,
        JSON_EXTRACT_SCALAR(chg, '$.reason') AS reason,
        JSON_EXTRACT_SCALAR(chg, '$.type') AS type
      )
      FROM UNNEST(JSON_EXTRACT_ARRAY(payload, '$.charges')) AS chg
    ) AS charges,
    JSON_EXTRACT_SCALAR(payload, '$.currency') AS currency,
    JSON_EXTRACT_SCALAR(payload, '$.sellerNotes') AS seller_notes,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.online') AS BOOL) AS online,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.rollup') AS BOOL) AS `rollup`,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.rank') AS INT64) AS rank,

    -- Meta Struct
    STRUCT(
      PARSE_TIMESTAMP("%FT%H:%M:%E*S%Ez", JSON_EXTRACT_SCALAR(payload, '$.meta.expires')) AS expires,
      PARSE_TIMESTAMP("%FT%H:%M:%E*S%Ez", JSON_EXTRACT_SCALAR(payload, '$.meta.modified')) AS modified,
      JSON_EXTRACT_SCALAR(payload, '$.meta.type') AS type
    ) AS meta,
    -- Arrays

    ARRAY(
      SELECT STRUCT(
        JSON_EXTRACT_SCALAR(alt, '$.id') AS id,
        JSON_EXTRACT_SCALAR(alt, '$.provider') AS provider
      )
      FROM UNNEST(JSON_EXTRACT_ARRAY(payload, '$.alternateIds')) AS alt
    ) AS alternate_ids,


    JSON_EXTRACT_SCALAR(payload, '$.offerType') AS offer_type,
    CAST(JSON_EXTRACT_SCALAR(payload, '$.protected') AS BOOL) AS protected,
    JSON_EXTRACT_SCALAR(payload, '$.schema') AS schema,

    _batch_timestamp
  FROM source
  --QUALIFY ROW_NUMBER() OVER(PARTITION BY TO_JSON_STRING(payload), _batch_timestamp ORDER BY _batch_timestamp) = 1
),

staging AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key([
      'event_id',
      'listing_id',
      'listing_version_id',
      'offer_id',
      'ticket_type_id',
      'meta.modified',
      '_batch_timestamp'
    ]) }} as grain_hash_id,
    *
  FROM extract_from_json
)

SELECT * FROM staging
