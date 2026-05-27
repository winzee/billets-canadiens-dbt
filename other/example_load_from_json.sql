extract_from_json AS (
  SELECT
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.created_at')  AS created_at,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.updated_at')  AS updated_at,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.wallet_id')  AS wallet_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.transaction_id')  AS transaction_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.credit_line_id')  AS credit_line_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.amount')  AS amount,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.origin')  AS origin,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_id') AS action_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.operation_status')  AS operation_status,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.operation')  AS operation,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_data.reason')  AS reason,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_data.cs_agent') AS cs_agent,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_data.cart_id')  AS cart_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_data.shopify_order_id')  AS shopify_order_id,
    JSON_EXTRACT_SCALAR(_airbyte_data, '$.action_data.shopify_draft_order_id') AS shopify_draft_order_id,
    _airbyte_ab_id,
    _airbyte_emitted_at,
    _data_lake_imported_at,
  FROM source
),
cast_data_types AS (
  SELECT
    CAST(created_at             AS {{ type_timestamp() }}) AS created_at,
    CAST(updated_at             AS {{ type_timestamp() }}) AS updated_at,
    CAST(wallet_id              AS {{ type_string() }})    AS wallet_id,
    CAST(transaction_id         AS {{ type_string() }})    AS transaction_id,
    CAST(credit_line_id         AS {{ type_string() }})    AS credit_line_id,
    CAST(amount                 AS {{ type_numeric() }})   AS amount,
    CAST(origin                 AS {{ type_string() }})    AS origin,
    CAST(action_id              AS {{ type_string() }})    AS action_id,
    CAST(operation_status       AS {{ type_string() }})    AS operation_status,
    CAST(operation              AS {{ type_string() }})    AS operation,
    CAST(reason                 AS {{ type_string() }})    AS reason,
    CAST(cs_agent               AS {{ type_string() }})    AS cs_agent,
    CAST(cart_id                AS {{ type_string() }})    AS cart_id,
    CAST(shopify_order_id       AS {{ type_int() }})       AS shopify_order_id,
    CAST(shopify_draft_order_id AS {{ type_int() }})       AS shopify_draft_order_id,
    _airbyte_ab_id,
    _airbyte_emitted_at,
    _data_lake_imported_at,
  FROM extract_from_json
),
add_hash AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key([
      'created_at','updated_at','wallet_id','transaction_id','credit_line_id','amount',
      'origin','action_id','operation_status','operation','reason','cs_agent','cart_id',
      'shopify_order_id','shopify_draft_order_id'
    ]) }} AS _hash_id,
    cast_data_types.*
  FROM cast_data_types
),

staging AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key([
      'transaction_id','created_at'
    ]) }} as grain_hash_id,
    transaction_id,
    shopify_order_id,
    shopify_draft_order_id,
    wallet_id,
    action_id,
    credit_line_id,
    cart_id,
    amount,
    origin,
    operation_status,
    operation,
    reason,
    cs_agent,
    created_at,
    updated_at,
    _airbyte_ab_id,
    _airbyte_emitted_at,
    _data_lake_imported_at,
    _hash_id,

  FROM add_hash
)