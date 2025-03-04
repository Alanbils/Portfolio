/*
This analysis examines revenue trends over time by different dimensions.
It helps identify growth patterns and seasonal effects.
*/

with order_items as (
    select * from {{ ref('fct_order_items') }}
    where status = 'completed'
),

-- Daily revenue
daily as (
    select
        date_trunc('day', order_date) as day,
        sum(line_total) as revenue,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as customer_count,
        revenue / customer_count as revenue_per_customer,
        revenue / order_count as average_order_value
    from order_items
    group by 1
),

-- Weekly revenue
weekly as (
    select
        date_trunc('week', order_date) as week,
        sum(line_total) as revenue,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as customer_count,
        revenue / customer_count as revenue_per_customer,
        revenue / order_count as average_order_value
    from order_items
    group by 1
),

-- Monthly revenue
monthly as (
    select
        date_trunc('month', order_date) as month,
        sum(line_total) as revenue,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as customer_count,
        revenue / customer_count as revenue_per_customer,
        revenue / order_count as average_order_value
    from order_items
    group by 1
),

-- Monthly revenue by category
monthly_category as (
    select
        date_trunc('month', order_date) as month,
        category,
        sum(line_total) as revenue,
        sum(line_profit) as profit,
        revenue / sum(revenue) over (partition by month) as category_percentage
    from order_items
    group by 1, 2
    order by 1, 2
),

-- Monthly revenue by customer region
monthly_region as (
    select
        date_trunc('month', order_date) as month,
        customer_region,
        sum(line_total) as revenue,
        sum(line_profit) as profit,
        count(distinct customer_id) as customer_count,
        revenue / customer_count as revenue_per_customer
    from order_items
    group by 1, 2
    order by 1, 2
)

-- Select appropriate view based on need
select * from monthly
order by month