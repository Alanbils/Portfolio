/* 
This analysis explores customer segmentation based on order patterns.
It calculates RFM (Recency, Frequency, Monetary) values for each customer.
*/

with customer_orders as (
    select * from {{ ref('customer_orders') }}
),

current_date as (
    select dateadd(day, 1, max(most_recent_order_date)) as max_date
    from customer_orders
),

rfm_calcs as (
    select
        customer_id,
        customer_name,
        customer_region,
        datediff('day', most_recent_order_date, (select max_date from current_date)) as recency,
        order_count as frequency,
        total_completed_amount as monetary,
        
        -- RFM Scoring
        ntile(5) over (order by datediff('day', most_recent_order_date, (select max_date from current_date))) as r_score,
        ntile(5) over (order by order_count) as f_score,
        ntile(5) over (order by total_completed_amount) as m_score
    from customer_orders
),

rfm_scores as (
    select
        *,
        -- Combine scores into a single value
        concat(r_score, f_score, m_score) as rfm_score,
        
        -- Segment categorization
        case
            when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'Champions'
            when r_score >= 3 and f_score >= 3 and m_score >= 3 then 'Loyal Customers'
            when r_score >= 4 and f_score >= 1 and m_score >= 4 then 'Big Spenders'
            when r_score <= 2 and f_score <= 2 and m_score <= 2 then 'At Risk'
            when r_score <= 1 and f_score >= 3 and m_score >= 3 then 'Can't Lose Them'
            when r_score <= 2 and f_score <= 1 and m_score <= 1 then 'Lost'
            when r_score >= 4 and f_score <= 1 and m_score <= 1 then 'Promising'
            when r_score >= 3 and f_score <= 1 and m_score <= 1 then 'New Customers'
            else 'Other'
        end as segment
    from rfm_calcs
)

select * from rfm_scores