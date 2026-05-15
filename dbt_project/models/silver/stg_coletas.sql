WITH step_1 AS (
    SELECT
        *
        , COALESCE(id_coleta, collection_id, "COLETA ID") AS id_coleta_raw
        , COALESCE(id_fazenda, farm_id, "ID FAZENDA") AS id_fazenda_raw
        , COALESCE(id_rota, route_id, "ID ROTA") AS id_rota_raw
        , COALESCE(data_coleta, collection_date, "DATA") AS data_coleta_raw
        , COALESCE(volume_litros, collected_liters, "VOLUME") AS volume_litros_raw_txt
        , COALESCE(temperatura_c, temperature_c, "TEMPERATURA") AS temperatura_c_raw_txt
        , COALESCE(acidez, acidity, "ACIDEZ") AS acidez_raw_txt
        , COALESCE(gordura_pct, fat_pct, "GORDURA") AS gordura_pct_raw_txt
        , COALESCE(proteina_pct, protein_pct, "PROTEINA") AS proteina_pct_raw_txt
        , ROW_NUMBER() OVER (
            PARTITION BY COALESCE(id_coleta, collection_id, "COLETA ID")
            ORDER BY _ingested_at DESC
        ) AS rn
    FROM {{ source('bronze', 'coletas') }}
    WHERE _is_duplicate = FALSE
),

step_2 AS (
    SELECT
        id_coleta_raw::BIGINT AS id_coleta
        , id_fazenda_raw::INT AS id_fazenda
        , id_rota_raw::INT AS id_rota
        , CASE
            WHEN data_coleta_raw ~ '^\d{4}-\d{2}-\d{2}$'
                THEN data_coleta_raw::DATE
            WHEN data_coleta_raw ~ '^\d{2}/\d{2}/\d{4}$'
                THEN TO_DATE(data_coleta_raw, 'DD/MM/YYYY')
            WHEN data_coleta_raw ~ '^\d{2}-\d{2}-\d{4}$'
                THEN TO_DATE(data_coleta_raw, 'MM-DD-YYYY')
            ELSE NULL
        END AS data_coleta
        , REPLACE(NULLIF(volume_litros_raw_txt, ''), ',', '.')::NUMERIC AS volume_litros_raw
        , REPLACE(NULLIF(temperatura_c_raw_txt, ''), ',', '.')::NUMERIC AS temperatura_c
        , REPLACE(NULLIF(acidez_raw_txt, ''), ',', '.')::NUMERIC AS acidez
        , REPLACE(NULLIF(gordura_pct_raw_txt, ''), ',', '.')::NUMERIC AS gordura_pct
        , REPLACE(NULLIF(proteina_pct_raw_txt, ''), ',', '.')::NUMERIC AS proteina_pct
        , _source_format
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
