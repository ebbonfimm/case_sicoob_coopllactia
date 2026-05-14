WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_pedido ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'pedidos') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_pedido::INT AS id_pedido
    , id_cliente::INT AS id_cliente
    , CASE
        WHEN data_pedido ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_pedido::DATE
        ELSE NULL
    END AS data_pedido
    , UPPER(TRIM(status)) AS status
    , UPPER(TRIM(canal)) AS canal
    , NULLIF(desconto_pct, '')::NUMERIC AS desconto_pct
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_pedido IS NOT NULL
        AND id_cliente IS NOT NULL
        AND data_pedido IS NOT NULL
    ) AS _dq_ok

FROM step_1
WHERE rn = 1