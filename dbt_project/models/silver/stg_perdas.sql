WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() OVER (PARTITION BY id_perda ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'perdas') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_perda::INT AS id_perda
    , TRIM(etapa) AS etapa
    , TRIM(tipo_perda) AS tipo_perda
    , CASE
        WHEN data_perda ~ '^\d{4}-\d{2}-\d{2}$'
            THEN data_perda::DATE
        ELSE NULL
    END AS data_perda
    , NULLIF(volume_litros_ou_kg, '')::NUMERIC AS volume_litros_ou_kg
    , NULLIF(valor_estimado, '')::NUMERIC AS valor_estimado
    , NULLIF(id_cooperado, '')::INT AS id_cooperado
    , NULLIF(id_producao, '')::INT AS id_producao
    , NULLIF(id_entrega, '')::INT AS id_entrega
    , NULLIF(descricao, '') AS descricao
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_perda IS NOT NULL
        AND etapa IS NOT NULL
        AND data_perda IS NOT NULL
    ) AS _dq_ok

FROM step_1
WHERE rn = 1