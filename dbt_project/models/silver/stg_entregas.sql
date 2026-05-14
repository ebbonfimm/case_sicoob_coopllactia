WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_entrega ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'entregas') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_entrega::BIGINT AS id_entrega
    , id_pedido::INT AS id_pedido
    , id_rota::INT AS id_rota
    , CASE
        WHEN data_prevista ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_prevista::DATE
        ELSE NULL
    END AS data_prevista
    , CASE
        WHEN data_realizada ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_realizada::DATE
        ELSE NULL
    END AS data_realizada
    , UPPER(TRIM(status_entrega)) AS status_entrega
    , NULLIF(km_percorrido, '')::NUMERIC AS km_percorrido
    , NULLIF(custo_frete, '')::NUMERIC AS custo_frete
    , NULLIF(ocorrencia, '') AS ocorrencia
    -- SLA: diferença em dias entre previsto e realizado
    , CASE
        WHEN data_realizada ~ '^\d{4}-\d{2}-\d{2}$'
         AND data_prevista  ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_realizada::DATE - data_prevista::DATE
        ELSE NULL
    END AS dias_atraso
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_entrega IS NOT NULL
        AND id_pedido IS NOT NULL
    ) AS _dq_ok

FROM step_1
WHERE rn = 1