WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_item ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'itens_pedido') }}
    WHERE _is_duplicate = FALSE
)

, step_2 AS (
    SELECT
        id_item::BIGINT AS id_item
        , id_pedido::INT AS id_pedido
        , id_produto::INT AS id_produto
        , quantidade::INT AS quantidade
        , preco_unitario::NUMERIC AS preco_unitario_raw
        , NULLIF(valor_total, '')::NUMERIC AS valor_total_raw
        , _row_hash
        , _source_file
        , _ingested_at
    FROM step_1
    WHERE rn = 1
)

SELECT
    *
    -- corrige preço negativo
    , ABS(preco_unitario_raw) AS preco_unitario
    -- reconstrói valor_total se nulo
    , COALESCE(valor_total_raw, quantidade * ABS(preco_unitario_raw)) AS valor_total
    , (preco_unitario_raw < 0) AS _dq_preco_negativo
    , (valor_total_raw IS NULL) AS _dq_valor_total_imputado
    , (
        preco_unitario_raw > 0
        AND quantidade > 0
    ) AS _dq_ok

FROM step_2