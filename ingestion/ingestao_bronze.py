"""
Coopllactia — Pipeline de Ingestão (Raw → Bronze)
===================================================
Responsabilidades deste script:
  1. Lê cada CSV da camada Raw
  2. Aplica tipagem mínima e registro de metadados (_source_file, _ingested_at, _row_hash)
  3. Carrega na camada bronze do PostgreSQL com estratégia UPSERT por hash
  4. Registra log de ingestão na tabela bronze.ingestion_log
  5. Não aplica regras de negócio — isso é papel do dbt (Silver/Gold)
"""

import os
import csv
import hashlib
import json
import logging
from datetime import datetime, timezone
from pathlib import Path

import psycopg2
from psycopg2.extras import execute_values

# ─── configuração ─────────────────────────────────────────────────────────────

DB_CONFIG = {
    "host":     os.getenv("PG_HOST",     "localhost"),
    "port":     int(os.getenv("PG_PORT", "5432")),
    "dbname":   os.getenv("PG_DB",       "coopllactia"),
    "user":     os.getenv("PG_USER",     "coopllactia"),
    "password": os.getenv("PG_PASSWORD", "coopllactia"),
}

RAW_DIR = Path(__file__).parent.parent / "raw_data"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


# ─── mapeamento CSV → tabela bronze ──────────────────────────────────────────
# Cada entrada define:
#   file        : nome do CSV
#   table       : tabela destino no schema bronze
#   pk_cols     : colunas que compõem a chave natural (usadas no UPSERT)
#   date_cols   : colunas que representam datas (normalizar para ISO durante parse)

TABLES = [
    {
        "file":  "cooperados.csv",
        "table": "bronze.cooperados",
        "pk_cols": ["id_cooperado"],
        "date_cols": ["data_adesao"],
    },
    {
        "file":  "fazendas.csv",
        "table": "bronze.fazendas",
        "pk_cols": ["id_fazenda"],
        "date_cols": [],
    },
    {
        "file":  "coletas_fonte_a.csv",
        "table": "bronze.coletas",
        "pk_cols": ["id_coleta"],
        "date_cols": [],
        "delimiter": ";",
        "source_format": "fonte_a",
    },
    {
        "file":  "coletas_fonte_b.csv",
        "table": "bronze.coletas",
        "pk_cols": ["collection_id"],
        "date_cols": [],
        "delimiter": ",",
        "source_format": "fonte_b",
    },
    {
        "file":  "coletas_fonte_c.csv",
        "table": "bronze.coletas",
        "pk_cols": ["COLETA ID"],
        "date_cols": [],
        "delimiter": ",",
        "source_format": "fonte_c",
    },
    {
        "file":  "produtos.csv",
        "table": "bronze.produtos",
        "pk_cols": ["id_produto"],
        "date_cols": [],
    },
    {
        "file":  "producao.csv",
        "table": "bronze.producao",
        "pk_cols": ["id_producao"],
        "date_cols": ["data_producao", "validade"],
    },
    {
        "file":  "clientes.csv",
        "table": "bronze.clientes",
        "pk_cols": ["id_cliente"],
        "date_cols": [],
    },
    {
        "file":  "pedidos.csv",
        "table": "bronze.pedidos",
        "pk_cols": ["id_pedido"],
        "date_cols": ["data_pedido"],
    },
    {
        "file":  "itens_pedido.csv",
        "table": "bronze.itens_pedido",
        "pk_cols": ["id_item"],
        "date_cols": [],
    },
    {
        "file":  "rotas.csv",
        "table": "bronze.rotas",
        "pk_cols": ["id_rota"],
        "date_cols": [],
    },
    {
        "file":  "entregas.csv",
        "table": "bronze.entregas",
        "pk_cols": ["id_entrega"],
        "date_cols": ["data_prevista", "data_realizada"],
    },
    {
        "file":  "custos_operacionais.csv",
        "table": "bronze.custos_operacionais",
        "pk_cols": ["id_custo"],
        "date_cols": ["data_referencia"],
    },
    {
        "file":  "perdas.csv",
        "table": "bronze.perdas",
        "pk_cols": ["id_perda"],
        "date_cols": ["data_perda"],
    },
]


# ─── helpers ──────────────────────────────────────────────────────────────────

def normalize_date(raw: str) -> str | None:
    """Converte datas em formato DD/MM/YYYY ou YYYY-MM-DD para YYYY-MM-DD.
    Retorna None se vazio ou não reconhecido.
    """
    if not raw or raw.strip() == "":
        return None
    raw = raw.strip()
    if len(raw) == 10 and raw[4] == "-":
        return raw
    parts = raw.split("/")
    if len(parts) == 3:
        try:
            return f"{parts[2]}-{parts[1].zfill(2)}-{parts[0].zfill(2)}"
        except Exception:
            pass
    return None


def parse_numeric_like(value: str) -> str | None:
    if value is None:
        return None
    txt = str(value).strip()
    if txt == "":
        return None
    return txt.replace(",", ".")


def normalize_coletas_row(row: dict, source_format: str) -> dict:
    if source_format == "fonte_a":
        return {
            "id_coleta": row.get("id_coleta"),
            "id_fazenda": row.get("id_fazenda"),
            "id_rota": row.get("id_rota"),
            "data_coleta": row.get("data_coleta"),
            "volume_litros": row.get("volume_litros"),
            "temperatura_c": row.get("temperatura_c"),
            "gordura_pct": row.get("gordura_pct"),
            "proteina_pct": row.get("proteina_pct"),
            "acidez": row.get("acidez"),
            "collection_id": None,
            "farm_id": None,
            "route_id": None,
            "collection_date": None,
            "collected_liters": None,
            "temperature_c": None,
            "fat_pct": None,
            "protein_pct": None,
            "acidity": None,
            "COLETA ID": None,
            "ID FAZENDA": None,
            "ID ROTA": None,
            "DATA": None,
            "VOLUME": None,
            "TEMPERATURA": None,
            "GORDURA": None,
            "PROTEINA": None,
            "ACIDEZ": None,
            "OBSERVACAO": None,
        }

    if source_format == "fonte_b":
        return {
            "id_coleta": None,
            "id_fazenda": None,
            "id_rota": None,
            "data_coleta": None,
            "volume_litros": None,
            "temperatura_c": None,
            "gordura_pct": None,
            "proteina_pct": None,
            "acidez": None,
            "collection_id": row.get("collection_id"),
            "farm_id": row.get("farm_id"),
            "route_id": row.get("route_id"),
            "collection_date": row.get("collection_date"),
            "collected_liters": parse_numeric_like(row.get("collected_liters")),
            "temperature_c": parse_numeric_like(row.get("temperature_c")),
            "fat_pct": parse_numeric_like(row.get("fat_pct")),
            "protein_pct": parse_numeric_like(row.get("protein_pct")),
            "acidity": parse_numeric_like(row.get("acidity")),
            "COLETA ID": None,
            "ID FAZENDA": None,
            "ID ROTA": None,
            "DATA": None,
            "VOLUME": None,
            "TEMPERATURA": None,
            "GORDURA": None,
            "PROTEINA": None,
            "ACIDEZ": None,
            "OBSERVACAO": None,
        }

    return {
        "id_coleta": None,
        "id_fazenda": None,
        "id_rota": None,
        "data_coleta": None,
        "volume_litros": None,
        "temperatura_c": None,
        "gordura_pct": None,
        "proteina_pct": None,
        "acidez": None,
        "collection_id": None,
        "farm_id": None,
        "route_id": None,
        "collection_date": None,
        "collected_liters": None,
        "temperature_c": None,
        "fat_pct": None,
        "protein_pct": None,
        "acidity": None,
        "COLETA ID": row.get("COLETA ID"),
        "ID FAZENDA": row.get("ID FAZENDA"),
        "ID ROTA": row.get("ID ROTA"),
        "DATA": row.get("DATA"),
        "VOLUME": parse_numeric_like(row.get("VOLUME")),
        "TEMPERATURA": parse_numeric_like(row.get("TEMPERATURA")),
        "GORDURA": parse_numeric_like(row.get("GORDURA")),
        "PROTEINA": parse_numeric_like(row.get("PROTEINA")),
        "ACIDEZ": parse_numeric_like(row.get("ACIDEZ")),
        "OBSERVACAO": row.get("OBSERVACAO"),
    }


def row_hash(row: dict) -> str:
    """MD5 do conteúdo da linha (sem metadados de ingestão)."""
    stable = json.dumps(row, sort_keys=True, ensure_ascii=False, default=str)
    return hashlib.md5(stable.encode()).hexdigest()


def parse_csv(filepath: Path, date_cols: list[str], delimiter: str = ",", source_format: str | None = None) -> list[dict]:
    rows = []
    with open(filepath, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=delimiter)
        for r in reader:
            for dc in date_cols:
                if dc in r:
                    r[dc] = normalize_date(r[dc])
            if source_format in {"fonte_a", "fonte_b", "fonte_c"}:
                r = normalize_coletas_row(r, source_format)
            rows.append(r)
    return rows


def create_schemas_and_log(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS bronze;")
        cur.execute("CREATE SCHEMA IF NOT EXISTS silver;")
        cur.execute("CREATE SCHEMA IF NOT EXISTS gold;")
        cur.execute("""
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
        """)
    conn.commit()


def ensure_bronze_table(conn, table_name: str, sample_row: dict):
    """Cria a tabela bronze se não existir, com todas as colunas como TEXT
    mais as colunas de metadados de ingestão.
    As colunas de negócio são TEXT porque a camada Bronze não aplica tipagem —
    isso é responsabilidade do dbt Silver.
    """
    cols = list(sample_row.keys())
    col_defs = ",\n    ".join(f'"{c}" TEXT' for c in cols)
    ddl = f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            _row_id       BIGSERIAL PRIMARY KEY,
            _row_hash     TEXT NOT NULL,
            _source_file  TEXT NOT NULL,
            _source_format TEXT,
            _ingested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            _is_duplicate BOOLEAN NOT NULL DEFAULT FALSE,
            {col_defs}
        );
        CREATE INDEX IF NOT EXISTS idx_{table_name.replace('.','_')}_hash
            ON {table_name} (_row_hash);
    """
    with conn.cursor() as cur:
        cur.execute(ddl)
    conn.commit()


def ensure_source_format_column(conn, table_name: str):
    with conn.cursor() as cur:
        cur.execute(f"ALTER TABLE {table_name} ADD COLUMN IF NOT EXISTS _source_format TEXT;")
    conn.commit()


def ensure_table_columns(conn, table_name: str, sample_row: dict):
    with conn.cursor() as cur:
        for col in sample_row.keys():
            cur.execute(f'ALTER TABLE {table_name} ADD COLUMN IF NOT EXISTS "{col}" TEXT;')
    conn.commit()


def load_existing_hashes(conn, table_name: str) -> set[str]:
    with conn.cursor() as cur:
        try:
            cur.execute(f"SELECT _row_hash FROM {table_name};")
            return {r[0] for r in cur.fetchall()}
        except Exception:
            conn.rollback()
            return set()


def insert_rows(conn, table_name: str, rows: list[dict],
                existing_hashes: set[str], source_file: str, source_format: str | None = None):
    if not rows:
        return 0, 0

    cols = list(rows[0].keys())
    all_cols = ["_row_hash", "_source_file", "_source_format", "_is_duplicate"] + cols

    to_insert = []
    seen_hashes = set()
    skipped = 0

    for row in rows:
        h = row_hash(row)
        is_dup = h in existing_hashes or h in seen_hashes
        if is_dup:
            skipped += 1
            to_insert.append(
                (h, source_file, source_format, True) + tuple(row.get(c) for c in cols)
            )
        else:
            to_insert.append(
                (h, source_file, source_format, False) + tuple(row.get(c) for c in cols)
            )
        seen_hashes.add(h)

    quoted_cols = ", ".join(f'"{c}"' for c in all_cols)
    sql = f"INSERT INTO {table_name} ({quoted_cols}) VALUES %s"

    with conn.cursor() as cur:
        execute_values(cur, sql, to_insert, page_size=1000)
    conn.commit()

    inserted = len(to_insert) - skipped
    return inserted, skipped


# ─── pipeline principal ───────────────────────────────────────────────────────

def run_ingestion():
    log.info("Conectando ao PostgreSQL...")
    conn = psycopg2.connect(**DB_CONFIG)
    create_schemas_and_log(conn)
    log.info("Schemas bronze/silver/gold garantidos.")

    total_start = datetime.now(timezone.utc)

    for tdef in TABLES:
        filepath = RAW_DIR / tdef["file"]
        if not filepath.exists():
            log.warning(f"Arquivo não encontrado: {filepath} — pulando.")
            continue

        t_start = datetime.now(timezone.utc)
        log.info(f"▶ Ingerindo {tdef['file']} → {tdef['table']}")

        try:
            rows = parse_csv(
                filepath,
                tdef["date_cols"],
                delimiter=tdef.get("delimiter", ","),
                source_format=tdef.get("source_format")
            )
            rows_read = len(rows)

            if rows:
                ensure_bronze_table(conn, tdef["table"], rows[0])
                ensure_source_format_column(conn, tdef["table"])
                ensure_table_columns(conn, tdef["table"], rows[0])
                existing = load_existing_hashes(conn, tdef["table"])
                inserted, skipped = insert_rows(
                    conn,
                    tdef["table"],
                    rows,
                    existing,
                    tdef["file"],
                    tdef.get("source_format")
                )
            else:
                inserted, skipped = 0, 0

            duration = int((datetime.now(timezone.utc) - t_start).total_seconds() * 1000)

            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO bronze.ingestion_log
                    (table_name, source_file, rows_read, rows_inserted, rows_updated, rows_skipped, duration_ms, status)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, (tdef["table"], tdef["file"], rows_read, inserted, 0, skipped, duration, "SUCCESS"))
            conn.commit()

            log.info(f"  ✓ {rows_read} lidos | {inserted} inseridos | {skipped} duplicatas | {duration}ms")

        except Exception as e:
            conn.rollback()
            log.error(f"  ✗ Erro: {e}")
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO bronze.ingestion_log
                    (table_name, source_file, status, error_msg)
                    VALUES (%s, %s, %s, %s)
                """, (tdef["table"], tdef["file"], "ERROR", str(e)))
            conn.commit()

    duration_total = int((datetime.now(timezone.utc) - total_start).total_seconds())
    log.info(f"\n✅ Ingestão concluída em {duration_total}s")
    conn.close()


if __name__ == "__main__":
    run_ingestion()