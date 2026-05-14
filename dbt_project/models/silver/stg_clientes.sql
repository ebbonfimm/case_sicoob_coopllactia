WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() over (PARTITION BY id_cliente ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'clientes') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_cliente::INT AS id_produto
    , TRIM(nome_cliente) AS nome_cliente
    , UPPER(TRIM(segmento)) AS segmento
    , TRIM(estado) AS UF
    , TRIM(cidade) AS cidade
    , cnpj as documento
    , CASE 
        WHEN LEFT(LOWER(ativo), 1) = 'n' THEN FALSE 
        WHEN LEFT(LOWER(ativo), 1) = 'n' THEN TRUE
        ELSE FALSE 
    end as ativo
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_cliente IS NOT NULL
        AND nome_cliente IS NOT NULL
        AND cnpj IS NOT NULL
    ) AS _dq_ok
FROM step_1
WHERE rn = 1
