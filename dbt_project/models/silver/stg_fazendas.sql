WITH step_1 AS (
    SELECT
        *
        , ROW_NUMBER() over (PARTITION BY id_fazenda ORDER BY _ingested_at DESC) AS rn
    FROM {{ source('bronze', 'fazendas') }}
    WHERE _is_duplicate = FALSE
)

SELECT
    id_fazenda::INT AS id_fazenda
    , id_cooperado::INT AS id_cooperado
    , TRIM(nome_fazenda) AS nome_fazenda
    , TRIM(municipio) AS municipio
    , NULLIF(area_hectares, '')::NUMERIC AS area_hectares
    , NULLIF(qtd_animais_lactacao, '')::NUMERIC AS qtd_animais_lactacao
    , TRIM(UPPER(raca_predominante)) as raca_predominante
    , _row_hash
    , _source_file
    , _ingested_at
    , (
        id_fazenda IS NOT NULL
        AND nome_fazenda IS NOT NULL
        AND NULLIF(area_hectares, '')::NUMERIC > 0
        AND NULLIF(qtd_animais_lactacao, '')::NUMERIC > 0
    ) AS _dq_ok
FROM step_1
WHERE rn = 1