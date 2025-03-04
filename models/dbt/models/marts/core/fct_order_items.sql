{{
    config(
        materialized = 'incremental',
        unique_key = 'order_item_id',
        dist = "{{ redshift_dist_sort(dist_style='KEY', sort_type='INTERLEAVED', sort_keys=['order_id', 'product_id']) }}"
    )
}}

with order_items as (
    select * from {{ ref('stg_order_items') }}
    
    {% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
    {% endif %}
),

orders as (
    select * from {{ ref('fct_orders') }}
),

products as (
    select * from {{ ref('dim_products') }}
),

final as (
    select
        order_items.order_item_id,
        order_items.order_id,
        orders.customer_id,
        order_items.product_id,
        -- Order attributes
        orders.order_date,
        orders.status,
        -- Customer attributes
        orders.customer_name,
        orders.customer_region,
        -- Product attributes
        products.product_name,
        products.category,
        products.price_tier,
        products.margin as product_margin,
        -- Order item metrics
        order_items.quantity,
        order_items.unit_price,
        order_items.line_total,
        -- Derived metrics
        order_items.line_total - (products.cost * order_items.quantity) as line_profit,
        (order_items.line_total - (products.cost * order_items.quantity)) / nullif(order_items.line_total, 0) * 100 as line_margin_percent,
        -- Timestamps
        order_items.created_at,
        order_items.updated_at
    from order_items
    left join orders on order_items.order_id = orders.order_id
    left join products on order_items.product_id = products.product_id
)

select * from final