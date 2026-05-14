{{ config(materialized='table') }}

WITH receita AS (
    SELECT
        DATE_TRUNC('month', p.data_pedido)::DATE AS mes
        , SUM(i.valor_total) AS receita_bruta
        , SUM(i.valor_total * COALESCE(p.desconto_pct, 0) / 100) AS desconto_total
        , SUM(i.valor_total) - SUM(i.valor_total * COALESCE(p.desconto_pct, 0) / 100) AS receita_liquida
        , COUNT(DISTINCT p.id_pedido) AS qtd_pedidos
    FROM {{ ref('stg_pedidos') }} p
    JOIN {{ ref('stg_itens_pedido') }} i ON p.id_pedido = i.id_pedido
    WHERE p._dq_ok
        AND i._dq_ok
        AND p.status != 'CANCELADO'
    GROUP BY 1
)

, custos AS (
    SELECT
        DATE_TRUNC('month', data_referencia)::DATE AS mes
        , SUM(CASE WHEN tipo_custo = 'FIXO' THEN valor ELSE 0 END) AS custo_fixo
        , SUM(CASE WHEN tipo_custo = 'VARIÁVEL' THEN valor ELSE 0 END) AS custo_variavel
        , SUM(valor) AS custo_total
        , SUM(CASE WHEN centro_custo = 'Produção' THEN valor ELSE 0 END) AS custo_producao
        , SUM(CASE WHEN centro_custo = 'Coleta' THEN valor ELSE 0 END) AS custo_coleta
        , SUM(CASE WHEN centro_custo = 'Logística' THEN valor ELSE 0 END) AS custo_logistica
        , SUM(CASE WHEN centro_custo = 'Comercial' THEN valor ELSE 0 END) AS custo_comercial
        , SUM(CASE WHEN centro_custo = 'Administrativo' THEN valor ELSE 0 END) AS custo_administrativo
    FROM {{ ref('stg_custos') }}
    WHERE _dq_ok
    GROUP BY 1
)

, perdas AS (
    SELECT
        DATE_TRUNC('month', data_perda)::DATE AS mes
        , SUM(valor_estimado) AS valor_perdas
    FROM {{ ref('stg_perdas') }}
    WHERE _dq_ok
    GROUP BY 1
)

, frete AS (
    SELECT
        DATE_TRUNC('month', data_realizada)::DATE AS mes
        , SUM(custo_frete) AS custo_frete_total
    FROM {{ ref('stg_entregas') }}
    WHERE _dq_ok
        AND data_realizada IS NOT NULL
    GROUP BY 1
)

SELECT
    r.mes
    , ROUND(r.receita_bruta, 2) AS receita_bruta
    , ROUND(r.desconto_total, 2) AS desconto_total
    , ROUND(r.receita_liquida, 2) AS receita_liquida
    , r.qtd_pedidos
    , ROUND(COALESCE(c.custo_fixo, 0), 2) AS custo_fixo
    , ROUND(COALESCE(c.custo_variavel, 0), 2) AS custo_variavel
    , ROUND(COALESCE(c.custo_producao, 0), 2) AS custo_producao
    , ROUND(COALESCE(c.custo_coleta, 0), 2) AS custo_coleta
    , ROUND(COALESCE(c.custo_logistica, 0), 2) AS custo_logistica
    , ROUND(COALESCE(c.custo_comercial, 0), 2) AS custo_comercial
    , ROUND(COALESCE(c.custo_administrativo, 0), 2) AS custo_administrativo
    , ROUND(COALESCE(f.custo_frete_total, 0), 2) AS custo_frete
    , ROUND(COALESCE(p.valor_perdas, 0), 2) AS valor_perdas
    , ROUND(
        r.receita_liquida
        - COALESCE(c.custo_total, 0)
        - COALESCE(f.custo_frete_total, 0)
        - COALESCE(p.valor_perdas, 0)
        , 2
    ) AS resultado_estimado
    , ROUND(
        100.0 * (
            r.receita_liquida
            - COALESCE(c.custo_total, 0)
            - COALESCE(f.custo_frete_total, 0)
            - COALESCE(p.valor_perdas, 0)
        ) / NULLIF(r.receita_liquida, 0)
        , 2
    ) AS margem_pct

FROM receita r
LEFT JOIN custos c ON r.mes = c.mes
LEFT JOIN perdas p ON r.mes = p.mes
LEFT JOIN frete f ON r.mes = f.mes
ORDER BY r.mes