WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_produto ORDER BY _ingested_at DESC) AS rn
        -- Row Number para resolver duplicados
    FROM {{ source('bronze', 'produtos') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_produto::INT AS id_produto
    ,TRIM(nome_produto) AS nome_produto
    , TRIM(categoria) AS categoria
    , UPPER(TRIM(unidade)) AS unidade
    , NULLIF(preco_venda, '')::NUMERIC AS preco_venda
    , custo_unitario::NUMERIC AS custo_unitario
    , UPPER(TRIM(ativo)) AS ativo
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_produto IS NOT NULL
        AND nome_produto IS NOT NULL
        AND NULLIF(preco_venda,'')::NUMERIC > 0
        AND custo_unitario::NUMERIC > 0
    ) AS _dq_ok
FROM step_1 
WHERE rn = 1
