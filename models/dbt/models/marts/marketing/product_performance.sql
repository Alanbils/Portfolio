{{
    config(
        materialized = 'table',
        post_hook="{{ create_redshift_table_statistics(this.identifier) }}"
    )
}}

with order_items as (
    select * from {{ ref('fct_order_items') }}
),

products as (
    select * from {{ ref('dim_products') }}
),

-- Aggregate metrics by product
product_metrics as (
    select
        product_id,
        count(distinct order_id) as order_count,
        sum(quantity) as total_quantity_sold,
        sum(line_total) as total_revenue,
        sum(line_profit) as total_profit,
        avg(line_margin_percent) as avg_margin_percent,
        min(order_date) as first_ordered_date,
        max(order_date) as last_ordered_date
    from order_items
    where status = 'completed'
    group by 1
),

-- Add time-based metrics
final as (
    select
        p.product_id,
        p.product_name,
        p.category,
        p.price_tier,
        p.price,
        p.cost,
        p.margin as unit_margin,
        pm.order_count,
        pm.total_quantity_sold,
        pm.total_revenue,
        pm.total_profit,
        pm.avg_margin_percent,
        
        -- Calculate per day metrics
        pm.total_revenue / nullif(datediff('day', pm.first_ordered_date, pm.last_ordered_date), 0) as daily_revenue,
        pm.total_quantity_sold / nullif(datediff('day', pm.first_ordered_date, pm.last_ordered_date), 0) as daily_units,
        
        -- Time metrics
        pm.first_ordered_date,
        pm.last_ordered_date,
        datediff('day', pm.first_ordered_date, pm.last_ordered_date) as days_selling,
        datediff('day', pm.last_ordered_date, current_date) as days_since_last_order,
        
        -- Categorization
        case
            when pm.total_revenue > 10000 then 'High'
            when pm.total_revenue > 1000 then 'Medium'
            else 'Low'
        end as revenue_tier,
        
        case
            when datediff('day', pm.last_ordered_date, current_date) <= 30 then 'Active'
            when datediff('day', pm.last_ordered_date, current_date) <= 90 then 'Slowing'
            else 'Inactive'
        end as product_status
    from products p
    left join product_metrics pm on p.product_id = pm.product_id
)

select * from final