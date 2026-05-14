-- silver/stg_custos_operacionais.sql
WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_custo ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'custos_operacionais') }}
    WHERE _is_duplicate = FALSE
)
SELECT
    id_custo::INT AS id_custo
    , TRIM(centro_custo) AS centro_custo
    , UPPER(TRIM(tipo_custo)) AS tipo_custo
    , NULLIF(descricao,'') AS descricao
    , valor::NUMERIC AS valor
    , CASE WHEN data_referencia ~ '^\d{4}-\d{2}-\d{2}$' THEN data_referencia::DATE ELSE NULL END AS data_referencia
    , competencia
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        valor::NUMERIC > 0 
        AND data_referencia IS NOT NULL
    ) AS _dq_ok
FROM step_1
WHERE rn = 1
