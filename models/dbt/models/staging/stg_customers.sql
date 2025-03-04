with source as (
    select * from {{ source('raw_data', 'customers') }}
),

renamed as (
    select
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        address,
        city,
        state,
        zip_code,
        created_at,
        updated_at
    from source
)

select * from renamed