# 🛒 Catálogo de Produtos — Azure Portal + ACR + Container Apps + SQL Server

Aplicação web Python que exibe produtos cadastrados em SQL Server, executada em
container Linux Ubuntu 22.04 com Nginx + Gunicorn + Flask, hospedada no
**Azure Container Apps**. Todo o provisionamento é feito pelo **Azure Portal**
(interface gráfica), exceto o build da imagem, que usa **Azure CLI** ou
**Azure Cloud Shell** (disponível dentro do próprio Portal).

---

## 🗺️ Arquitetura

```
Código local / Cloud Shell
         │
         ▼  az acr build  ← ÚNICA etapa via CLI (sem Docker)
Azure Container Registry (ACR)
         │  imagem: acrprodutos.azurecr.io/produtos-app:v1
         ▼
Azure Container Apps  (Linux Ubuntu 22.04)
  ├── Nginx           porta 80  ← entrada HTTPS pública
  └── Gunicorn+Flask  porta 5000 ← lógica da aplicação
         │
         ▼
Azure SQL Database
  └── Tabela: Produtos (id, nome, descricao, valor, ativo, criado_em)
```

---

## 📋 Pré-requisitos

| Item | Detalhe |
|---|---|
| Conta Azure | Assinatura ativa com permissão de Contributor |
| Azure CLI | Necessário **somente** para o `az acr build` |
| Azure Cloud Shell | Alternativa ao CLI local — disponível no Portal (ícone `>_`) |

> ✅ **Não é necessário instalar Docker** em nenhuma etapa.

---

## 📁 Estrutura do Projeto

```
projeto-produtos/
├── Containerfile                    # Definição do container (Ubuntu 22.04)
├── app/
│   ├── app.py                       # Aplicação Flask
│   ├── requirements.txt             # Dependências Python
│   └── templates/
│       └── produtos.html            # Página HTML de produtos
├── nginx/
│   └── nginx.conf                   # Reverse proxy Nginx
└── scripts/
    ├── start.sh                     # Inicialização do container
    └── init_db.sql                  # Criação da tabela e dados de exemplo
```

---

## 🚀 Deploy — Passo a Passo via Azure Portal

### Passo 1 — Criar Resource Group

1. Acesse [portal.azure.com](https://portal.azure.com) e faça login
2. Pesquise **"Resource groups"** na barra de busca superior
3. Clique em **"+ Create"**
4. Preencha:
   - **Subscription:** sua assinatura
   - **Resource group name:** `rg-produtos`
   - **Region:** `Brazil South`
5. Clique em **"Review + create"** → **"Create"**

---

### Passo 2A — Criar Azure SQL Server

1. Pesquise **"SQL servers"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Server name:** `produtos-sqlserver` *(único global)*
   - **Location:** `Brazil South`
   - **Authentication method:** `SQL authentication`
   - **Server admin login:** `sqladmin`
   - **Password:** `Produtos@2025!` *(ou senha de sua preferência)*
3. Clique em **"Review + create"** → **"Create"**

> 📌 Guarde o **Server name** — será usado como `DB_SERVER` no deploy.

---

### Passo 2B — Criar Azure SQL Database

1. Pesquise **"SQL databases"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Database name:** `ProdutosDB`
   - **Server:** `produtos-sqlserver`
   - **Compute + storage:** clique em *"Configure database"* → selecione **Basic (5 DTUs)**
   - **Backup storage redundancy:** `Locally redundant`
3. Clique em **"Review + create"** → **"Create"**

---

### Passo 2C — Configurar Firewall e Criar Tabela

**Firewall:**
1. Abra o recurso **SQL Server** (`produtos-sqlserver`)
2. Menu lateral → **Networking**
3. Em *"Exceptions"*: marque **"Allow Azure services and resources to access this server"**
4. Clique em **"Save"**

**Criar tabela via Query Editor:**
1. Abra o recurso **SQL Database** (`ProdutosDB`)
2. Menu lateral → **Query editor (preview)**
3. Login: `sqladmin` | Senha: *(definida no passo 2A)*
4. Cole o conteúdo completo do arquivo `scripts/init_db.sql`
5. Clique em **"Run"**
6. Valide: execute `SELECT * FROM Produtos` — deve retornar 5 linhas

---

### Passo 3A — Criar Azure Container Registry

1. Pesquise **"Container registries"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Registry name:** `acrprodutos` *(único global, só letras e números)*
   - **Location:** `Brazil South`
   - **Pricing plan:** `Basic`
3. Clique em **"Review + create"** → **"Create"**
4. Após criar, vá em: **Settings → Access keys**
5. Ative o toggle **"Admin user"**
6. Anote: **Login server**, **Username** e **Password**

---

### Passo 3B — Build da Imagem ⚡ *(única etapa via CLI)*

> Esta é a **única etapa** que não pode ser feita pelo Portal, pois requer
> enviar arquivos locais para o ACR Tasks realizar o build na nuvem.
> Use o **Azure Cloud Shell** (ícone `>_` na barra superior do Portal)
> para não precisar de instalação local.

```bash
# Somente se usar terminal local (não necessário no Cloud Shell)
az login

# Execute na pasta raiz do projeto (onde está o Containerfile)
az acr build \
  --registry acrprodutos \
  --image    produtos-app:v1 \
  --file     Containerfile \
  .
```

**Verificar no Portal após o build:**
1. Abra o recurso **Container Registry** (`acrprodutos`)
2. Menu lateral → **Services → Repositories**
3. Clique em `produtos-app` → confirme a tag `v1` listada

---

### Passo 4A — Criar Container Apps Environment

1. Pesquise **"Container Apps Environments"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Environment name:** `aca-env-produtos`
   - **Region:** `Brazil South`
   - **Monitoring:** pode desativar o Log Analytics para reduzir custo
3. Clique em **"Review + create"** → **"Create"**

---

### Passo 4B — Criar Container App — Aba Basics

1. Pesquise **"Container Apps"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Container app name:** `aca-app-produtos`
   - **Region:** `Brazil South`
   - **Container Apps Environment:** `aca-env-produtos`
3. Clique em **"Next: Container >"**

---

### Passo 4C — Container App — Aba Container

1. **Desmarque** *"Use quickstart image"*
2. Preencha:
   - **Image source:** `Azure Container Registry`
   - **Registry:** `acrprodutos`
   - **Image:** `produtos-app`
   - **Image tag:** `v1`
   - **CPU and Memory:** `0.5 CPU cores, 1 Gi memory`
3. Em **"Environment variables"**, clique em **"+ Add"** para cada variável:

   | Name | Value | Tipo |
   |---|---|---|
   | `DB_SERVER` | `produtos-sqlserver.database.windows.net` | Text |
   | `DB_NAME` | `ProdutosDB` | Text |
   | `DB_USER` | `sqladmin` | Text |
   | `DB_PASSWORD` | `<sua senha>` | **Secret** |

4. Clique em **"Next: Ingress >"**

---

### Passo 4D — Container App — Aba Ingress

1. Marque **"Enabled"** em Ingress
2. Preencha:
   - **Ingress Traffic:** `Accepting traffic from anywhere`
   - **Ingress type:** `HTTP`
   - **Target port:** `80`
3. Clique em **"Review + create"** → **"Create"**
4. Aguarde o deploy (2 a 5 minutos)
5. Clique em **"Go to resource"**
6. Copie a **"Application URL"** e acesse: `https://<url>/produtos`

---

## 🔄 Atualizar para Nova Versão

### 1. Rebuild da imagem (CLI / Cloud Shell)

```bash
az acr build \
  --registry acrprodutos \
  --image    produtos-app:v2 \
  --file     Containerfile \
  .
```

### 2. Atualizar no Portal

1. Abra o recurso **Container App** → `aca-app-produtos`
2. Menu lateral → **Containers**
3. Clique em **"Edit and deploy"**
4. Selecione o container listado → **"Edit"**
5. Altere **Image tag:** `v1` → `v2`
6. Clique em **"Save"** → **"Create"**
7. Nova revision ficará ativa em poucos segundos

---

## 📊 Monitoramento no Portal

| Onde | O que monitorar |
|---|---|
| Container App → **Overview** | Status, URL e réplicas ativas |
| Container App → **Revisions** | Histórico de versões deployadas |
| Container App → **Log stream** | Logs em tempo real do container |
| Container App → **Metrics** | CPU, memória e requisições HTTP |
| SQL Database → **Query Performance Insight** | Queries lentas |
| ACR → **Repositories** | Histórico de imagens e tags |

---

## ✅ Checklist de Deploy

### Via Azure Portal (interface gráfica)
- [ ] Criar Resource Group `rg-produtos`
- [ ] Criar SQL Server `produtos-sqlserver`
- [ ] Criar SQL Database `ProdutosDB`
- [ ] Configurar firewall — *Allow Azure services*
- [ ] Executar `init_db.sql` no Query Editor
- [ ] Criar Container Registry `acrprodutos` + ativar Admin user
- [ ] Criar Container Apps Environment `aca-env-produtos`
- [ ] Criar Container App com imagem, variáveis e ingress porta 80

### Via Azure CLI ou Cloud Shell *(obrigatório)*
- [ ] `az acr build` — build e push da imagem no ACR

---

## 🌐 Rotas da Aplicação

| Rota | Descrição |
|---|---|
| `GET /` | Redireciona para `/produtos` |
| `GET /produtos` | Página HTML com listagem de produtos |
| `GET /health` | Health check — retorna `{"status": "ok"}` |

---

## ⚙️ Variáveis de Ambiente

| Variável | Descrição | Exemplo |
|---|---|---|
| `DB_SERVER` | FQDN do SQL Server | `produtos-sqlserver.database.windows.net` |
| `DB_NAME` | Nome do banco | `ProdutosDB` |
| `DB_USER` | Usuário SQL | `sqladmin` |
| `DB_PASSWORD` | Senha SQL | *(defina como Secret no Portal)* |

