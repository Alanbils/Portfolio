{{
    config(
        materialized = 'table',
        post_hook="{{ create_redshift_table_statistics(this.identifier) }}"
    )
}}

with products as (
    select * from {{ ref('stg_products') }}
),

final as (
    select
        product_id,
        product_name,
        category,
        price,
        cost,
        sku,
        description,
        created_at,
        -- Add derived columns
        price - cost as margin,
        (price - cost) / nullif(price, 0) * 100 as margin_percent,
        case
            when price < 25 then 'Budget'
            when price < 75 then 'Regular'
            else 'Premium'
        end as price_tier,
        case
            when category = 'Electronics' then 'E'
            when category = 'Clothing' then 'C'
            when category = 'Home' then 'H'
            else 'O'
        end || '-' || sku as product_code
    from products
)

select * from final