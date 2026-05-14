"""
Coopllactia — Geração de Dados Sintéticos
==========================================
Gera 12 CSVs simulando 2 anos de operação (2023-2024).

Problemas de qualidade injetados intencionalmente:
  - Datas em formato DD/MM/YYYY (em vez de YYYY-MM-DD)
  - Valores nulos em campos não obrigatórios
  - Duplicatas ocasionais de registros
  - Valores fora do intervalo esperado (volume negativo, preço zero)
  - Capitalização inconsistente em campos categóricos
"""

import csv
import random
import os
from datetime import date, timedelta

random.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "raw_data")
os.makedirs(OUTPUT_DIR, exist_ok=True)

START_DATE = date(2023, 1, 1)
END_DATE   = date(2024, 12, 31)
DAYS       = (END_DATE - START_DATE).days + 1


# ─── helpers ──────────────────────────────────────────────────────────────────

def rand_date(start=START_DATE, end=END_DATE):
    return start + timedelta(days=random.randint(0, (end - start).days))

def maybe_null(value, prob=0.05):
    """Retorna vazio com probabilidade prob, simulando valor nulo."""
    return "" if random.random() < prob else value

def bad_date(d: date, prob=0.04):
    """Ocasionalmente retorna data em formato brasileiro (problema de qualidade)."""
    if random.random() < prob:
        return d.strftime("%d/%m/%Y")
    return d.isoformat()

def inconsistent_case(value, prob=0.30):
    """Retorna o valor com capitalização aleatória (problema de qualidade)."""
    if random.random() < prob:
        return random.choice([value.upper(), value.lower(), value.title()])
    return value

def write_csv(filename, rows, fieldnames):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)
    print(f"  ✓ {filename}  ({len(rows)} linhas)")


# ─── 1. cooperados ────────────────────────────────────────────────────────────
# Quem é a pessoa ou empresa associada à cooperativa

cooperados = []
for i in range(1, 101):
    cooperados.append({
        "id_cooperado": i,
        "nome":         f"Cooperado {i}",
        "cpf_cnpj":     maybe_null(f"{random.randint(100,999)}.{random.randint(100,999)}.{random.randint(100,999)}-{random.randint(10,99)}", prob=0.05),
        "data_adesao":  bad_date(rand_date(date(2010, 1, 1), date(2022, 12, 31))),
        "situacao":     inconsistent_case(random.choice(["Ativo", "Ativo", "Ativo", "Inativo", "Suspenso"])),
    })

# injeta duplicatas
for _ in range(5):
    cooperados.append(random.choice(cooperados[:100]))

write_csv("cooperados.csv", cooperados,
          ["id_cooperado", "nome", "cpf_cnpj", "data_adesao", "situacao"])


# ─── 2. fazendas ──────────────────────────────────────────────────────────────
# As propriedades pertencentes a um cooperado

MUNICIPIOS  = ["Uberlândia", "Uberaba", "Patos de Minas", "Araxá",
               "Ituiutaba", "Monte Carmelo", "Frutal", "Paracatu"]
RACAS       = ["Holandesa", "Gir Leiteiro", "Girolando", "Jersey", "Pardo-Suíço"]

fazendas = []
fazenda_id = 1
for coop in cooperados[:100]:
    n_fazendas = random.randint(1, 4)
    for j in range(n_fazendas):
        fazendas.append({
            "id_fazenda":           fazenda_id,
            "id_cooperado":         coop["id_cooperado"],
            "nome_fazenda":         f"Fazenda {chr(65 + j)}{fazenda_id}",
            "municipio":            random.choice(MUNICIPIOS),
            "area_hectares":        maybe_null(round(random.uniform(50, 2000), 1), prob=0.08),
            "qtd_animais_lactacao": maybe_null(random.randint(20, 300), prob=0.05),
            "raca_predominante":    inconsistent_case(random.choice(RACAS), prob=0.25),
        })
        fazenda_id += 1

write_csv("fazendas.csv", fazendas,
          ["id_fazenda", "id_cooperado", "nome_fazenda", "municipio",
           "area_hectares", "qtd_animais_lactacao", "raca_predominante"])


# ─── 3. rotas ─────────────────────────────────────────────────────────────────
# Os trajetos utilizados para coleta e entrega

rotas = []
for i in range(1, 21):
    rotas.append({
        "id_rota":          i,
        "nome_rota":        f"Rota {i:02d}",
        "municipio_origem": random.choice(MUNICIPIOS),
        "km_total":         round(random.uniform(30, 400), 1),
        "veiculo_tipo":     random.choice(["Caminhão Tanque", "Caminhonete", "Carreta"]),
        "ativa":            inconsistent_case(random.choice(["Sim", "Sim", "Sim", "Não"])),
    })

write_csv("rotas.csv", rotas,
          ["id_rota", "nome_rota", "municipio_origem", "km_total", "veiculo_tipo", "ativa"])


# ─── 4. coletas ───────────────────────────────────────────────────────────────
# Registro diário do volume de leite coletado em cada fazenda

coletas = []
coleta_id = 1
fazendas_ativas = [f for f in fazendas if True]  # todas as fazendas participam

for d in range(DAYS):
    dia = START_DATE + timedelta(days=d)
    # nem toda fazenda é coletada todo dia
    sample = random.sample(fazendas_ativas, k=min(len(fazendas_ativas), random.randint(80, 150)))
    for fazenda in sample:
        volume = round(random.uniform(200, 5000), 2)
        # injeta volume negativo (erro de digitação)
        if random.random() < 0.01:
            volume = -volume
        coletas.append({
            "id_coleta":    coleta_id,
            "id_fazenda":   fazenda["id_fazenda"],
            "id_rota":      random.randint(1, 20),
            "data_coleta":  bad_date(dia),
            "volume_litros": volume,
            "temperatura_c": maybe_null(round(random.uniform(2, 10), 1), prob=0.06),
            "gordura_pct":   maybe_null(round(random.uniform(3.0, 5.5), 2), prob=0.05),
            "proteina_pct":  maybe_null(round(random.uniform(2.8, 4.0), 2), prob=0.05),
            "acidez":        maybe_null(round(random.uniform(14, 20), 2), prob=0.06),
        })
        coleta_id += 1

# injeta duplicatas
for _ in range(200):
    coletas.append(random.choice(coletas[:5000]))

write_csv("coletas.csv", coletas,
          ["id_coleta", "id_fazenda", "id_rota", "data_coleta", "volume_litros",
           "temperatura_c", "gordura_pct", "proteina_pct", "acidez"])


# ─── 5. produtos ──────────────────────────────────────────────────────────────
# Catálogo de produtos fabricados pela cooperativa

CATEGORIAS = ["Leite UHT", "Queijo", "Manteiga", "Iogurte", "Creme de Leite", "Requeijão"]

produtos = []
for i in range(1, 31):
    cat = random.choice(CATEGORIAS)
    preco = round(random.uniform(3, 80), 2)
    # injeta preço zerado (problema de qualidade)
    if random.random() < 0.03:
        preco = 0
    produtos.append({
        "id_produto":     i,
        "nome_produto":   f"{cat} Coopllactia {i}",
        "categoria":      cat,
        "unidade":        random.choice(["L", "kg", "un", "cx"]),
        "preco_venda":    preco,
        "custo_unitario": round(random.uniform(1.5, 50), 2),
        "ativo":          inconsistent_case(random.choice(["Sim", "Sim", "Sim", "Não"])),
    })

write_csv("produtos.csv", produtos,
          ["id_produto", "nome_produto", "categoria", "unidade",
           "preco_venda", "custo_unitario", "ativo"])


# ─── 6. producao ──────────────────────────────────────────────────────────────
# Ordens de produção na planta industrial

LINHAS = ["Linha A", "Linha B", "Linha C"]

producao = []
for i in range(1, 3001):
    volume_entrada = round(random.uniform(500, 10000), 2)
    volume_saida   = round(volume_entrada * random.uniform(0.70, 0.98), 2)
    producao.append({
        "id_producao":          i,
        "id_produto":           random.randint(1, 30),
        "data_producao":        bad_date(rand_date()),
        "linha_producao":       inconsistent_case(random.choice(LINHAS)),
        "volume_entrada_litros": volume_entrada,
        "volume_saida":         volume_saida,
        "custo_total":          maybe_null(round(random.uniform(800, 50000), 2), prob=0.05),
        "lote":                 f"L{i:05d}",
        "validade":             bad_date(rand_date(date(2024, 1, 1), date(2025, 6, 30))),
    })

write_csv("producao.csv", producao,
          ["id_producao", "id_produto", "data_producao", "linha_producao",
           "volume_entrada_litros", "volume_saida", "custo_total", "lote", "validade"])


# ─── 7. clientes ──────────────────────────────────────────────────────────────
# Empresas ou pessoas que compram os produtos da cooperativa

SEGMENTOS = ["Varejo", "Atacado", "Food Service", "Exportação"]
ESTADOS   = ["MG", "SP", "GO", "DF", "RJ", "BA", "PR", "RS"]

clientes = []
for i in range(1, 201):
    clientes.append({
        "id_cliente":   i,
        "nome_cliente": f"Cliente {i}",
        "segmento":     inconsistent_case(random.choice(SEGMENTOS)),
        "estado":       random.choice(ESTADOS),
        "cidade":       maybe_null(f"Cidade {random.randint(1, 50)}", prob=0.08),
        "cnpj":         maybe_null(f"{random.randint(10,99)}.{random.randint(100,999)}.{random.randint(100,999)}/0001-{random.randint(10,99)}", prob=0.10),
        "ativo":        inconsistent_case(random.choice(["Sim", "Sim", "Sim", "Não"])),
    })

write_csv("clientes.csv", clientes,
          ["id_cliente", "nome_cliente", "segmento", "estado", "cidade", "cnpj", "ativo"])


# ─── 8. pedidos ───────────────────────────────────────────────────────────────
# Cabeçalho de cada pedido de venda realizado

STATUS_PEDIDO = ["Faturado", "Em separação", "Entregue", "Cancelado"]
CANAIS        = ["Direto", "Representante", "E-commerce"]

pedidos = []
for i in range(1, 5001):
    pedidos.append({
        "id_pedido":   i,
        "id_cliente":  random.randint(1, 200),
        "data_pedido": bad_date(rand_date()),
        "status":      inconsistent_case(random.choice(STATUS_PEDIDO)),
        "canal":       inconsistent_case(random.choice(CANAIS)),
        "desconto_pct": maybe_null(round(random.uniform(0, 15), 2), prob=0.20),
    })

# injeta duplicatas
for _ in range(50):
    pedidos.append(random.choice(pedidos[:500]))

write_csv("pedidos.csv", pedidos,
          ["id_pedido", "id_cliente", "data_pedido", "status", "canal", "desconto_pct"])


# ─── 9. itens_pedido ──────────────────────────────────────────────────────────
# Os produtos dentro de cada pedido, com quantidade e preço

itens = []
item_id = 1
for pedido in pedidos[:5000]:
    n_itens = random.randint(1, 6)
    pids = random.sample(range(1, 31), k=n_itens)
    for pid in pids:
        qtd   = random.randint(1, 500)
        preco = round(random.uniform(3, 80), 2)
        # injeta preço negativo (problema de qualidade)
        if random.random() < 0.005:
            preco = -preco
        itens.append({
            "id_item":        item_id,
            "id_pedido":      pedido["id_pedido"],
            "id_produto":     pid,
            "quantidade":     qtd,
            "preco_unitario": preco,
            "valor_total":    maybe_null(round(qtd * abs(preco), 2), prob=0.03),
        })
        item_id += 1

write_csv("itens_pedido.csv", itens,
          ["id_item", "id_pedido", "id_produto", "quantidade", "preco_unitario", "valor_total"])


# ─── 10. entregas ─────────────────────────────────────────────────────────────
# Execução logística de cada pedido, com prazo e custo de frete

STATUS_ENTREGA = ["Entregue", "Pendente", "Devolvido"]

entregas = []
for i in range(1, 5501):
    dt_prev = rand_date()
    atraso  = random.randint(-2, 10)
    dt_real = dt_prev + timedelta(days=atraso)
    entregas.append({
        "id_entrega":      i,
        "id_pedido":       random.randint(1, 5000),
        "id_rota":         random.randint(1, 20),
        "data_prevista":   bad_date(dt_prev),
        "data_realizada":  maybe_null(bad_date(dt_real), prob=0.05),
        "status_entrega":  inconsistent_case(random.choice(STATUS_ENTREGA)),
        "km_percorrido":   maybe_null(round(random.uniform(20, 420), 1), prob=0.07),
        "custo_frete":     maybe_null(round(random.uniform(80, 2500), 2), prob=0.06),
        "ocorrencia":      maybe_null(random.choice(["Sem ocorrência", "Atraso", "Avaria", "Recusa"]), prob=0.60),
    })

write_csv("entregas.csv", entregas,
          ["id_entrega", "id_pedido", "id_rota", "data_prevista", "data_realizada",
           "status_entrega", "km_percorrido", "custo_frete", "ocorrencia"])


# ─── 11. custos_operacionais ──────────────────────────────────────────────────
# Custos fixos e variáveis registrados por centro de custo

CENTROS     = ["Coleta", "Produção", "Logística", "Comercial", "Administrativo"]
TIPOS_CUSTO = ["Fixo", "Variável"]

custos = []
for i in range(1, 1001):
    dt = rand_date()
    custos.append({
        "id_custo":        i,
        "centro_custo":    random.choice(CENTROS),
        "tipo_custo":      inconsistent_case(random.choice(TIPOS_CUSTO)),
        "descricao":       maybe_null(random.choice(["Energia", "Combustível", "Mão de obra", "Manutenção", "Aluguel"]), prob=0.05),
        "valor":           round(random.uniform(500, 150000), 2),
        "data_referencia": bad_date(dt),
        "competencia":     f"{dt.year}-{dt.month:02d}",
    })

write_csv("custos_operacionais.csv", custos,
          ["id_custo", "centro_custo", "tipo_custo", "descricao",
           "valor", "data_referencia", "competencia"])


# ─── 12. perdas ───────────────────────────────────────────────────────────────
# Ocorrências de perda de volume ou valor em qualquer etapa da cadeia

TIPOS_PERDA = ["Vencimento", "Contaminação", "Derramamento", "Falha de processo", "Devolução"]
ETAPAS      = ["Coleta", "Produção", "Estoque", "Transporte"]

perdas = []
for i in range(1, 801):
    etapa = random.choice(ETAPAS)
    perdas.append({
        "id_perda":            i,
        "etapa":               etapa,
        "tipo_perda":          random.choice(TIPOS_PERDA),
        "data_perda":          bad_date(rand_date()),
        "volume_litros_ou_kg": maybe_null(round(random.uniform(5, 2000), 2), prob=0.05),
        "valor_estimado":      maybe_null(round(random.uniform(50, 20000), 2), prob=0.08),
        # IDs opcionais — preenchidos de acordo com a etapa
        "id_cooperado":  maybe_null(random.randint(1, 100), prob=0.50) if etapa == "Coleta"    else "",
        "id_producao":   maybe_null(random.randint(1, 3000), prob=0.40) if etapa == "Produção" else "",
        "id_entrega":    maybe_null(random.randint(1, 5500), prob=0.40) if etapa == "Transporte" else "",
        "descricao":     maybe_null(f"Perda na etapa de {etapa.lower()}", prob=0.15),
    })

write_csv("perdas.csv", perdas,
          ["id_perda", "etapa", "tipo_perda", "data_perda", "volume_litros_ou_kg",
           "valor_estimado", "id_cooperado", "id_producao", "id_entrega", "descricao"])


print("\n✅ Todos os arquivos gerados em /raw_data/")