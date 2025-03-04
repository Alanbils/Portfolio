with orders as (
    select * from {{ ref('fct_orders') }}
),

customer_orders as (
    select
        customer_id,
        customer_name,
        customer_region,
        count(*) as order_count,
        sum(amount) as total_amount,
        sum(completed_amount) as total_completed_amount,
        sum(returned_amount) as total_returned_amount,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        datediff('day', min(order_date), max(order_date)) as customer_lifetime_days
    from orders
    group by 1, 2, 3
),

final as (
    select
        *,
        -- Add customer metrics
        case
            when total_returned_amount > 0 then true
            else false
        end as has_returned_order,
        total_returned_amount / nullif(total_amount, 0) as return_rate,
        total_amount / nullif(order_count, 0) as average_order_value,
        case
            when customer_lifetime_days > 365 then 'Loyal'
            when customer_lifetime_days > 90 then 'Active' 
            else 'New'
        end as customer_segment
    from customer_orders
)

select * from final