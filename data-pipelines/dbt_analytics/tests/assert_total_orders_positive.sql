-- Custom test to ensure order totals are positive
select
    customer_id,
    total_orders
from {{ ref('dim_customers') }}
where total_orders < 0
