-- =============================================================================
-- Coopllactia — DDL das Tabelas Bronze
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- log
CREATE TABLE IF NOT EXISTS bronze.ingestion_log (
    id              SERIAL PRIMARY KEY,
    table_name      TEXT NOT NULL,
    source_file     TEXT NOT NULL,
    ingested_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rows_read       INT,
    rows_inserted   INT,
    rows_updated    INT,
    rows_skipped    INT,
    duration_ms     INT,
    status          TEXT,
    error_msg       TEXT
);


--cooperado
CREATE TABLE IF NOT EXISTS bronze.cooperados (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_cooperado    TEXT,
    nome            TEXT,
    municipio       TEXT,
    data_adesao     TEXT,   -- pode vir como DD/MM/YYYY ou YYYY-MM-DD
    situacao        TEXT,   -- pode vir como Ativo / ativo / ATIVO
    area_hectares   TEXT,
    email           TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_cooperados_hash ON bronze.cooperados (_row_hash);

-- ---------------------------------------------------------------------------
-- uiahsphauibwxbwuixnianwoxniaw
CREATE TABLE IF NOT EXISTS bronze.animais (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_animal       TEXT,
    id_cooperado    TEXT,
    raca            TEXT,
    data_nascimento TEXT,
    em_lactacao     TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_animais_hash ON bronze.animais (_row_hash);


-- coletas
CREATE TABLE IF NOT EXISTS bronze.coletas (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_coleta       TEXT,
    id_cooperado    TEXT,
    data_coleta     TEXT,   -- normalizado para YYYY-MM-DD na ingestão
    volume_litros   TEXT,   -- pode conter valores negativos (erro de digitação)
    temperatura_c   TEXT,   -- pode ser nulo
    acidez          TEXT,
    gordura_pct     TEXT,
    proteina_pct    TEXT,
    id_rota         TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_coletas_hash ON bronze.coletas (_row_hash);
CREATE INDEX IF NOT EXISTS idx_bronze_coletas_cooperado ON bronze.coletas (id_cooperado);
CREATE INDEX IF NOT EXISTS idx_bronze_coletas_data ON bronze.coletas (data_coleta);


-- produtos
CREATE TABLE IF NOT EXISTS bronze.produtos (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_produto      TEXT,
    nome_produto    TEXT,
    categoria       TEXT,
    unidade         TEXT,
    preco_venda     TEXT,   -- pode ser 0 ou nulo (problema de qualidade)
    custo_unitario  TEXT,
    ativo           TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_produtos_hash ON bronze.produtos (_row_hash);


-- producao
CREATE TABLE IF NOT EXISTS bronze.producao (
    _row_id                 BIGSERIAL PRIMARY KEY,
    _row_hash               TEXT NOT NULL,
    _source_file            TEXT NOT NULL,
    _ingested_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate           BOOLEAN NOT NULL DEFAULT FALSE,

    id_producao             TEXT,
    id_produto              TEXT,
    data_producao           TEXT,
    linha_producao          TEXT,   -- inconsistência de capitalização
    volume_entrada_litros   TEXT,
    volume_saida_kg_ou_l    TEXT,
    custo_total             TEXT,
    lote                    TEXT,
    validade                TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_producao_hash ON bronze.producao (_row_hash);


--clientes
CREATE TABLE IF NOT EXISTS bronze.clientes (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_cliente      TEXT,
    nome_cliente    TEXT,
    segmento        TEXT,   -- inconsistência de capitalização
    estado          TEXT,
    cidade          TEXT,
    cnpj            TEXT,
    ativo           TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_clientes_hash ON bronze.clientes (_row_hash);


--pedidos
CREATE TABLE IF NOT EXISTS bronze.pedidos (
    _row_id         BIGSERIAL PRIMARY KEY,
    _row_hash       TEXT NOT NULL,
    _source_file    TEXT NOT NULL,
    _ingested_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate   BOOLEAN NOT NULL DEFAULT FALSE,

    id_pedido       TEXT,
    id_cliente      TEXT,
    data_pedido     TEXT,
    status          TEXT,
    canal           TEXT,
    desconto_pct    TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_pedidos_hash ON bronze.pedidos (_row_hash);


-- itens_pedido
CREATE TABLE IF NOT EXISTS bronze.itens_pedido (
    _row_id             BIGSERIAL PRIMARY KEY,
    _row_hash           TEXT NOT NULL,
    _source_file        TEXT NOT NULL,
    _ingested_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate       BOOLEAN NOT NULL DEFAULT FALSE,

    id_item             TEXT,
    id_pedido           TEXT,
    id_produto          TEXT,
    quantidade          TEXT,
    preco_unitario      TEXT,   -- pode conter valores negativos
    valor_total         TEXT    -- pode ser nulo (imputado no Silver)
);
CREATE INDEX IF NOT EXISTS idx_bronze_itens_hash ON bronze.itens_pedido (_row_hash);


-- rotas
CREATE TABLE IF NOT EXISTS bronze.rotas (
    _row_id             BIGSERIAL PRIMARY KEY,
    _row_hash           TEXT NOT NULL,
    _source_file        TEXT NOT NULL,
    _ingested_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate       BOOLEAN NOT NULL DEFAULT FALSE,

    id_rota             TEXT,
    nome_rota           TEXT,
    municipio_origem    TEXT,
    km_total            TEXT,
    veiculo_tipo        TEXT,
    ativa               TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_rotas_hash ON bronze.rotas (_row_hash);


-- entregas
CREATE TABLE IF NOT EXISTS bronze.entregas (
    _row_id             BIGSERIAL PRIMARY KEY,
    _row_hash           TEXT NOT NULL,
    _source_file        TEXT NOT NULL,
    _ingested_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate       BOOLEAN NOT NULL DEFAULT FALSE,

    id_entrega          TEXT,
    id_pedido           TEXT,
    id_rota             TEXT,
    data_prevista       TEXT,
    data_realizada      TEXT,   -- pode ser nulo (entrega pendente)
    status_entrega      TEXT,
    km_percorrido       TEXT,
    custo_frete         TEXT,
    ocorrencia          TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_entregas_hash ON bronze.entregas (_row_hash);


-- custos_operacionais
CREATE TABLE IF NOT EXISTS bronze.custos_operacionais (
    _row_id             BIGSERIAL PRIMARY KEY,
    _row_hash           TEXT NOT NULL,
    _source_file        TEXT NOT NULL,
    _ingested_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate       BOOLEAN NOT NULL DEFAULT FALSE,

    id_custo            TEXT,
    centro_custo        TEXT,
    tipo_custo          TEXT,   -- Fixo / fixo / FIXO etc.
    descricao           TEXT,
    valor               TEXT,
    data_referencia     TEXT,
    competencia         TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_custos_hash ON bronze.custos_operacionais (_row_hash);


-- perdas
CREATE TABLE IF NOT EXISTS bronze.perdas (
    _row_id                 BIGSERIAL PRIMARY KEY,
    _row_hash               TEXT NOT NULL,
    _source_file            TEXT NOT NULL,
    _ingested_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _is_duplicate           BOOLEAN NOT NULL DEFAULT FALSE,

    id_perda                TEXT,
    etapa                   TEXT,
    tipo_perda              TEXT,
    data_perda              TEXT,
    volume_litros_ou_kg     TEXT,
    valor_estimado          TEXT,
    id_cooperado            TEXT,
    id_producao             TEXT,
    id_entrega              TEXT,
    descricao               TEXT
);
CREATE INDEX IF NOT EXISTS idx_bronze_perdas_hash ON bronze.perdas (_row_hash);
