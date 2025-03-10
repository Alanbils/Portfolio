{% test primary_key_integrity(model, column_name) %}
    -- Custom test to ensure primary key integrity across time
    with validation as (
        select
            {{ column_name }} as primary_key,
            count(*) as occurrences,
            min(created_at) as first_seen,
            max(created_at) as last_seen
        from {{ model }}
        group by {{ column_name }}
        having count(*) > 1
    )
    
    select *
    from validation
{% endtest %}

{% test value_in_range(model, column_name, min_value, max_value) %}
    -- Custom test to ensure numeric values fall within expected range
    select
        *
    from {{ model }}
    where {{ column_name }} < {{ min_value }}
        or {{ column_name }} > {{ max_value }}
{% endtest %}

{% test date_not_in_future(model, column_name) %}
    -- Custom test to ensure dates are not in the future
    select
        *
    from {{ model }}
    where {{ column_name }} > current_timestamp
{% endtest %}

{% test consistent_status_transitions(model, status_column, timestamp_column) %}
    -- Custom test to ensure status transitions follow business rules
    with status_changes as (
        select
            *,
            lag({{ status_column }}) over (
                partition by id 
                order by {{ timestamp_column }}
            ) as previous_status
        from {{ model }}
    )
    
    select *
    from status_changes
    where (
        previous_status = 'pending' and {{ status_column }} not in ('processing', 'cancelled')
    ) or (
        previous_status = 'processing' and {{ status_column }} not in ('completed', 'failed')
    )
{% endtest %}
