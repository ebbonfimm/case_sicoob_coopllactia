# Coopllactia

Feito por Eduardo Braga Bonfim

### Passo a passo da Criação da estrutura do projeto

- Criação da Estrutura de pastas
- Criação do docker-compose.yaml
- Criação .venv
  - Instalção psycopg2-binary, dbt-postgres
- Execução do docker com docker-compose up -d (depois verificando com docker ps)
- Criação Scripts de Geração de dados sintéticos e Ingestão da camada Bronze no banco
- Execução dos scripts
- Criação da estrutura do dbt com dbt init dbt_project
- Geração do script das tabelas

#### Estrutura do projeto

```
dbt_project/ — Toda a estrutura de pastas e conteúdo do DBT
docs/ - Comandos DDL
ingestion/ - Script para criação dos dados sintéticos e ingestão na camada bronze do banco de dados
raw_data/ - Dados Crus, gerados pelo código Python

arquivo docker-compose.yaml -> Arquivo contendo as configurações do Container Docker que roda o banco de dados PostgreSQL

arquivo general.sql -> Arquivo de apoio, foi usado para interagir com o banco de dados. Não contém uma estrutura, serviu somente como apoio mesmo.

arquivos requirements.txt -> dependências do Python necessárias para o projeto

```

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

### Estrutura de pastas do dbt_project (Principal)

```
models/ — Onde ficam as queries
    - bronze/
    - silver/
    - gold/

dbt_project.yml — arquivo de configuração central do projeto
```

### Visualizar o Profile

Get-Content $env:USERPROFILE\.dbt\profiles.yml

---

## Instruções de Execução do Projeto

```
1. Tenha o Docker os drivers do PostgrSQL isnstalados na máquina
2. Navegue até o diretório do projeto com comando "cd"
3. Execute o comando "docker-compose up -d" para subir a instância do banco
4. Ainda dentro da pasta do projeto (.../coopllactia), crie uma .venv executando o comando "python -m venv .venv"
5. Após criar, ative a .venv (comando varia de acordo com o SO)
6. Execute "pip install -r requirements.txt" para instalar as dependências
7. Executar o script "geracao_dados.py"
8. Executar o script "ingestao_bronze.py"
9. Feito tudo isso, navegue até a pasta dbt_project e execute o comando "dbt run" para rodar todos os models
10. voilá, dados populados no PostgreSQL prontos para gerar Insights
```

### Informações Extras:

TL Draw: https://www.tldraw.com/f/fh7zv-WTixXK2XGmc8RdG?d=v1769.-1084.2173.1193.page
