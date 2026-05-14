{{ config(materialized='table') }}

SELECT
    DATE_TRUNC('month', c.data_coleta)::DATE AS mes
    , c.id_fazenda
    , f.nome_fazenda
    , f.municipio
    , co.nome AS nome_cooperado
    , COUNT(*) AS qtd_coletas
    , ROUND(SUM(c.volume_litros), 0) AS volume_total_litros
    , ROUND(AVG(c.volume_litros), 1) AS volume_medio_por_coleta
    , ROUND(AVG(c.gordura_pct), 3) AS gordura_media_pct
    , ROUND(AVG(c.proteina_pct), 3) AS proteina_media_pct
    , ROUND(AVG(c.acidez), 2) AS acidez_media
    , ROUND(AVG(c.temperatura_c), 1) AS temperatura_media_c
    , ROUND(
        100.0 * SUM(CASE WHEN c._dq_ok THEN 1 ELSE 0 END) / COUNT(*)
        , 1
    ) AS pct_coletas_validas

FROM {{ ref('stg_coletas') }} c
LEFT JOIN {{ ref('stg_fazendas') }} f ON c.id_fazenda = f.id_fazenda
LEFT JOIN {{ ref('stg_cooperados') }} co ON f.id_cooperado = co.id_cooperado
WHERE c.data_coleta IS NOT NULL
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, volume_total_litros DESC