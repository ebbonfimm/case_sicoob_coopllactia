WITH step_1 AS (
    SELECT 
        *
        , ROW_NUMBER() OVER (PARTITION BY id_cooperado ORDER BY _ingested_at DESC) AS rn 
        -- Row Number para resolver duplicados
    FROM {{ source('bronze', 'cooperados') }}
    WHERE _is_duplicate = FALSE
),

step_2 AS (
    SELECT
        id_cooperado::INT AS id_cooperado
        , TRIM(nome) AS nome
        , CASE
            WHEN data_adesao ~ '^\d{4}-\d{2}-\d{2}$'
                THEN data_adesao::DATE
            ELSE NULL
        END AS data_adesao
        , UPPER(TRIM(situacao)) AS situacao
        , _row_hash
        , _source_file
        , _ingested_at

    FROM step_1
    WHERE rn = 1  -- Se 1 = Inclusão mais recente
)

SELECT
    *,
    (
        id_cooperado IS NOT NULL
        AND nome IS NOT NULL
        AND data_adesao IS NOT NULL
        AND situacao IN ('ATIVO', 'INATIVO', 'SUSPENSO')  -- Definidos com base nas regras de negócio.
    ) AS _dq_ok

FROM step_2
