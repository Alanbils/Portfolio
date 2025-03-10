WITH source AS (
    SELECT * FROM {{ source('raw', 'orders') }}
),

renamed AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        status,
        amount,
        created_at,
        updated_at
    FROM source
),

final AS (
    SELECT
        order_id,
        customer_id,
        CAST(order_date AS DATE) as order_date,
        status,
        CAST(amount AS DECIMAL(10,2)) as amount,
        created_at,
        updated_at,
        _etl_loaded_at
    FROM renamed
)

SELECT * FROM final
