{{ config(materialized='table') }}

SELECT
    DATE_TRUNC('month', e.data_prevista)::DATE AS mes
    , e.id_rota
    , r.nome_rota
    , r.municipio_origem
    , r.veiculo_tipo
    , COUNT(*) AS qtd_entregas
    , COUNT(CASE WHEN e.status_entrega = 'ENTREGUE' THEN 1 END) AS qtd_entregues
    , COUNT(CASE WHEN e.status_entrega = 'DEVOLVIDO' THEN 1 END) AS qtd_devolvidas
    , COUNT(CASE WHEN e.status_entrega = 'PENDENTE' THEN 1 END) AS qtd_pendentes
    , COUNT(CASE WHEN COALESCE(e.dias_atraso, 0) <= 0 THEN 1 END) AS qtd_no_prazo
    , ROUND(
        100.0 * COUNT(CASE WHEN COALESCE(e.dias_atraso, 0) <= 0 THEN 1 END)
        / NULLIF(COUNT(*), 0)
        , 1
    ) AS pct_no_prazo
    , ROUND(AVG(e.dias_atraso), 1) AS atraso_medio_dias
    , MAX(e.dias_atraso) AS atraso_maximo_dias
    , ROUND(SUM(e.custo_frete), 2) AS custo_frete_total
    , ROUND(AVG(e.custo_frete), 2) AS custo_frete_medio
    , ROUND(AVG(e.km_percorrido), 1) AS km_medio
    , ROUND(
        SUM(e.custo_frete) / NULLIF(SUM(e.km_percorrido), 0)
        , 4
    ) AS custo_por_km

FROM {{ ref('stg_entregas') }} e
LEFT JOIN {{ ref('stg_rotas') }} r ON e.id_rota = r.id_rota
WHERE e._dq_ok
    AND e.data_prevista IS NOT NULL
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, pct_no_prazo ASC