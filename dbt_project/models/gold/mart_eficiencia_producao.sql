{{ config(materialized='table') }}

SELECT
    DATE_TRUNC('month', p.data_producao)::DATE AS mes
    , p.linha_producao
    , pr.categoria AS categoria_produto
    , pr.nome_produto
    , COUNT(*) AS qtd_ordens
    , ROUND(SUM(p.volume_entrada_litros), 0) AS total_entrada_litros
    , ROUND(SUM(p.volume_saida), 0) AS total_saida
    , ROUND(AVG(p.rendimento_pct) * 100, 2) AS rendimento_medio_pct
    , ROUND(SUM(p.volume_entrada_litros - p.volume_saida), 0) AS perda_processo_litros
    , ROUND(
        100.0 * SUM(p.volume_entrada_litros - p.volume_saida)
        / NULLIF(SUM(p.volume_entrada_litros), 0)
        , 2
    ) AS pct_perda_processo
    , ROUND(SUM(p.custo_total), 2) AS custo_total
    , ROUND(
        SUM(p.custo_total) / NULLIF(SUM(p.volume_saida), 0)
        , 4
    ) AS custo_por_unidade_saida

FROM {{ ref('stg_producao') }} p
LEFT JOIN {{ ref('stg_produtos') }} pr ON p.id_produto = pr.id_produto
WHERE p._dq_ok
GROUP BY 1, 2, 3, 4
ORDER BY 1, rendimento_medio_pct DESC