# Coopllactia

### Passo a passo da Criação da estrutura do projeto

- Criação da Estrutura de pastas
- Criação do docker-compose.yaml
- Criação .venv
  - Instalção psycopg2-binary, dbt-postgres
- Execução do docker com docker-compose up -d (depois verificando com docker ps)
- Criação Scripts de Geração de dados sintéticos e Ingestão da camada Bronze no banco
- Execução dos scripts
- Criação da estrutura do dbt com dbt init dbt_project

### Configurações do DBT no momento da Criação

```
 C:\Code\SQL\coopllactia   3.13.13  dbt init dbt_project
18:00:40  Running with dbt=1.12.0-b1
18:00:40  Creating dbt configuration folder at C:\Users\eduar\.dbt
18:00:40  Setting up your profile.
Which database would you like to use?
[1] postgres

(Don't see the one you want? https://docs.getdbt.com/docs/available-adapters)

Enter a number: 1
host (hostname for the instance): localhost
port [5432]:
user (dev username): coopllactia
pass (dev password):
dbname (default database that dbt will build objects in): coopllactia
schema (default schema that dbt will build objects in): public
threads (1 or more) [1]: 4
```

#### Estrutura de pastas do dbt_project

```
models/ — onde ficam os SQLs do Silver e Gold. É aqui que vamos trabalhar mais

tests/ — testes de qualidade dos dados (ex: verificar se há nulos em colunas obrigatórias)

seeds/ — arquivos CSV pequenos que o dbt carrega direto no banco (tabelas de referência)

macros/ — funções SQL reutilizáveis

analyses/ e snapshots/ — não vamos usar nesse projeto

dbt_project.yml — arquivo de configuração central do projeto
```

### Visualizar o Profile

Get-Content $env:USERPROFILE\.dbt\profiles.yml

---

### Informações Extras:

TL Draw: https://www.tldraw.com/f/fh7zv-WTixXK2XGmc8RdG?d=v1769.-1084.2173.1193.page
