SELECT 
    *
FROM information_schema.tables
WHERE table_schema = 'bronze'
ORDER BY table_name;

SELECT 
    table_name,
    rows_read,
    rows_inserted,
    rows_skipped,
    duration_ms,
    status,
    ingested_at
FROM bronze.ingestion_log
ORDER BY ingested_at;

SELECT * FROM bronze.cooperados c ;

select * from bronze.clientes c ;
select * from bronze.fazendas f ;

SELECT * FROM bronze.rotas r ;

select * from bronze.produtos p ;





-- SILVER
SELECT * FROM silver.stg_cooperado sc ;
SELECT * FROM silver.stg_rotas sr ;