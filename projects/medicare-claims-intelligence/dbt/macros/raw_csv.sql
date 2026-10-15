{# Reads one DE-SynPUF CSV. IDs and dates stay VARCHAR so leading zeros and blanks survive. #}
{% macro raw_csv(file_name) -%}
read_csv('{{ var("raw_dir") }}/{{ file_name }}', header = true, all_varchar = true)
{%- endmacro %}

{# YYYYMMDD string -> DATE, NULL when blank. #}
{% macro yyyymmdd(col) -%}
try_strptime(nullif({{ col }}, ''), '%Y%m%d')::date
{%- endmacro %}

{# Number of non-blank columns among prefix_1 .. prefix_n (diagnosis / HCPCS counts). #}
{% macro count_filled(prefix, n) -%}
({% for i in range(1, n + 1) %}(case when nullif({{ prefix }}_{{ i }}, '') is not null then 1 else 0 end){% if not loop.last %} + {% endif %}{% endfor %})
{%- endmacro %}
