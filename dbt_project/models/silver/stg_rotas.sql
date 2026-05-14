WITH step_1 AS (
    SELECT 
        *
        , ROW_NUMBER() OVER (PARTITION BY id_rota ORDER BY _ingested_at DESC) AS rn
        -- Row Number para resolver duplicados
    FROM {{ source('bronze', 'rotas') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_rota::INT AS id_rota
    , TRIM(nome_rota) AS nome_rota
    , TRIM(municipio_origem) AS municipio_origem
    , km_total::NUMERIC AS km_total
    , TRIM(veiculo_tipo) AS veiculo_tipo
    , CASE 
        WHEN LEFT(LOWER(ativa), 1) = 'n' THEN FALSE 
        WHEN LEFT(LOWER(ativa), 1) = 'n' THEN TRUE
        ELSE FALSE 
    end as ativo -- Normalizando como nome ativo
    , _row_hash
    , _source_file
    , _ingested_at
    , (id_rota IS NOT NULL AND km_total::NUMERIC IS NOT NULL) AS _dq_ok
FROM step_1 
WHERE rn = 1
