{% macro date_spine(start_date, end_date) %}

with date_spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date=start_date,
        end_date=end_date
        )
    }}
),

enriched_dates as (
    select
        date_day as date,
        extract(year from date_day) as year,
        extract(month from date_day) as month,
        extract(day from date_day) as day_of_month,
        extract(dayofweek from date_day) + 1 as day_of_week,
        extract(quarter from date_day) as quarter,
        extract(dayofyear from date_day) as day_of_year,
        case
            when extract(dayofweek from date_day) + 1 in (6, 7) then true
            else false
        end as is_weekend,
        case
            when extract(month from date_day) = 1 and extract(day from date_day) = 1 then true
            when extract(month from date_day) = 7 and extract(day from date_day) = 4 then true
            when extract(month from date_day) = 12 and extract(day from date_day) = 25 then true
            else false
        end as is_holiday
    from date_spine
)

select * from enriched_dates

{% endmacro %}