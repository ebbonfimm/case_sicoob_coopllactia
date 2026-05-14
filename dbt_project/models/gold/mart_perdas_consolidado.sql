{{ config(materialized='table') }}

SELECT
    DATE_TRUNC('month', p.data_perda)::DATE AS mes
    , p.etapa
    , p.tipo_perda
    , COUNT(*) AS qtd_ocorrencias
    , ROUND(SUM(p.volume_litros_ou_kg), 1) AS volume_perdido
    , ROUND(SUM(p.valor_estimado), 2) AS valor_perdido
    , ROUND(AVG(p.valor_estimado), 2) AS valor_medio_por_ocorrencia
    , ROUND(
        100.0 * SUM(p.valor_estimado)
        / NULLIF(SUM(SUM(p.valor_estimado)) OVER (PARTITION BY DATE_TRUNC('month', p.data_perda)), 0)
        , 2
    ) AS pct_valor_no_mes

FROM {{ ref('stg_perdas') }} p
WHERE p._dq_ok
    AND p.data_perda IS NOT NULL
GROUP BY 1, 2, 3, p.data_perda
ORDER BY 1, valor_perdido DESC