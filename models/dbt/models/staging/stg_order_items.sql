with source as (
    select * from {{ source('raw_data', 'order_items') }}
),

renamed as (
    select
        order_item_id,
        order_id,
        product_id,
        quantity,
        unit_price,
        quantity * unit_price as line_total,
        created_at,
        updated_at
    from source
)

select * from renamed