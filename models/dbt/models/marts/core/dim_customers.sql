with customers as (
    select * from {{ ref('stg_customers') }}
),

final as (
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
        -- Add derived columns
        concat(first_name, ' ', last_name) as full_name,
        case
            when state in ('CA', 'OR', 'WA') then 'West'
            when state in ('NY', 'NJ', 'CT') then 'East'
            when state in ('TX', 'OK', 'NM') then 'South'
            else 'Other'
        end as region
    from customers
)

select * from final