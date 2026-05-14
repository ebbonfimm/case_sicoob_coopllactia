WITH step_1 AS (
    SELECT 
        *
        , ROW_NUMBER() OVER (PARTITION BY id_coleta ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'coletas') }}
    WHERE _is_duplicate = FALSE
),

step_2 AS (
    SELECT
        id_coleta::BIGINT AS id_coleta
        , id_fazenda::INT AS id_fazenda
        , id_rota::INT AS id_rota
        ,CASE
            WHEN data_coleta ~ '^\d{4}-\d{2}-\d{2}$'
                THEN data_coleta::DATE
            ELSE NULL
        END AS data_coleta
        , volume_litros::NUMERIC AS volume_litros_raw
        , NULLIF(temperatura_c, '')::NUMERIC AS temperatura_c
        , NULLIF(acidez, '')::NUMERIC AS acidez
        , NULLIF(gordura_pct, '')::NUMERIC AS gordura_pct
        , NULLIF(proteina_pct, '')::NUMERIC  AS proteina_pct
        , _row_hash
        , _source_file
        , _ingested_at

    FROM step_1
    WHERE rn = 1
)

SELECT
    *
    , CASE
        WHEN volume_litros_raw < 0 THEN NULL
        ELSE volume_litros_raw
    END AS volume_litros
    , (
        volume_litros_raw > 0
        AND data_coleta IS NOT NULL
        AND id_fazenda IS NOT NULL
    ) AS _dq_ok

FROM step_2
