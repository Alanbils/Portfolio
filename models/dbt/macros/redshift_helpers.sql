{% macro grant_select_on_schemas(schemas, role) %}
    {% for schema in schemas %}
        grant usage on schema {{ schema }} to {{ role }};
        grant select on all tables in schema {{ schema }} to {{ role }};
        alter default privileges in schema {{ schema }} grant select on tables to {{ role }};
    {% endfor %}
{% endmacro %}

{% macro create_redshift_table_statistics(table_name) %}
    {% set table_relation = ref(table_name) %}
    analyze {{ table_relation }} compute statistics;
{% endmacro %}

{% macro redshift_dist_sort(dist_style='AUTO', sort_type='COMPOUND', sort_keys=none) %}
  {%- if dist_style -%}
    diststyle {{dist_style}}
  {%- endif -%}
  
  {%- if sort_keys -%}
    {%- if sort_type -%}
      {{sort_type}} sortkey (
    {%- else -%}
      sortkey (
    {%- endif -%}
    
    {%- for key in sort_keys -%}
      {{key}}{% if not loop.last %}, {% endif %}
    {%- endfor -%}
    )
  {%- endif -%}
{% endmacro %}