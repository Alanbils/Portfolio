with orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        customers.full_name as customer_name,
        customers.region as customer_region,
        orders.order_date,
        orders.status,
        orders.amount,
        orders.created_at,
        -- Add derived metrics
        case
            when status = 'completed' then amount
            else 0
        end as completed_amount,
        case
            when status = 'returned' then amount
            else 0
        end as returned_amount,
        date_trunc('month', order_date) as order_month
    from orders
    left join customers on orders.customer_id = customers.customer_id
)

select * from final