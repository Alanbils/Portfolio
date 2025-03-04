with source as (
    select * from {{ source('raw_data', 'products') }}
),

renamed as (
    select
        product_id,
        product_name,
        category,
        price,
        cost,
        sku,
        description,
        created_at,
        updated_at
    from source
)

select * from renamed