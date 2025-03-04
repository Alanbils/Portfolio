with source as (
    select * from {{ source('raw_data', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        amount,
        created_at,
        updated_at
    from source
)

select * from renamed