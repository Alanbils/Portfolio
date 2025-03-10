with customers as (
    select * from {{ ref('stg_customers') }}
),

customer_orders as (
    select
        customer_id,
        count(*) as total_orders,
        sum(amount) as lifetime_value
    from {{ ref('stg_orders') }}
    group by 1
),

final as (
    select
        customers.customer_id,
        customers.email,
        customers.first_name,
        customers.last_name,
        coalesce(customer_orders.total_orders, 0) as total_orders,
        coalesce(customer_orders.lifetime_value, 0) as lifetime_value
    from customers
    left join customer_orders using (customer_id)
)

select * from final
