WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_producao ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'producao') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_producao::INT AS id_producao
    , id_produto::INT AS id_produto
    , CASE
        WHEN data_producao ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_producao::DATE
        ELSE NULL
    END AS data_producao
    , UPPER(TRIM(REGEXP_REPLACE(linha_producao, '\s+', ' '))) AS linha_producao
    , volume_entrada_litros::NUMERIC AS volume_entrada_litros
    , volume_saida::NUMERIC AS volume_saida
    , NULLIF(custo_total, '')::NUMERIC AS custo_total
    , lote
    , CASE
        WHEN validade ~ '^\d{4}-\d{2}-\d{2}$'
            THEN validade::DATE
        ELSE NULL
    END AS validade
    , ROUND(
        volume_saida::NUMERIC / NULLIF(volume_entrada_litros::NUMERIC, 0)
        , 4
    ) AS rendimento_pct
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_producao IS NOT NULL
        AND volume_entrada_litros::NUMERIC > 0
    ) AS _dq_ok

FROM step_1
WHERE rn = 1