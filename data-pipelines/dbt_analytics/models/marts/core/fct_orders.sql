WITH orders AS (
    SELECT * FROM {{ ref('stg_orders') }}
),

final AS (
    SELECT
        order_id,
        customer_id,
        order_date,
        status,
        amount,
        DATE_TRUNC('month', order_date) as order_month,
        CASE 
            WHEN amount > 1000 THEN 'high_value'
            WHEN amount > 500 THEN 'medium_value'
            ELSE 'low_value'
        END as order_tier
    FROM orders
)

SELECT * FROM final
