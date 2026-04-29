# 🛒 Catálogo de Produtos — Azure Portal · ACR · ACI · SQL Server

Aplicação web Python que exibe produtos cadastrados em SQL Server, executada
em **Azure Container Instance (ACI)** com container Linux Ubuntu 22.04
(Nginx + Gunicorn + Flask). A imagem é armazenada no
**Azure Container Registry (ACR)**. Todo o provisionamento é feito pelo
**Azure Portal**, exceto o build da imagem, que usa **Azure CLI** ou
**Azure Cloud Shell** (disponível dentro do próprio Portal).

---

## 🗺️ Arquitetura

```
Código local / Cloud Shell
         │
         ▼  az acr build  ← ÚNICA etapa via CLI (sem Docker)
Azure Container Registry (ACR)
         │  acrprodutos.azurecr.io/produtos-app:v1
         ▼
Azure Container Instance (ACI)  ← Linux Ubuntu 22.04
  ├── Nginx          porta 80   ← ponto de entrada HTTP público
  └── Gunicorn+Flask porta 5000 ← lógica da aplicação Python
         │
         ▼
Azure SQL Database
  └── Tabela: Produtos (id, nome, descricao, valor, ativo, criado_em)

Acesso: http://<IP ou FQDN do ACI>/produtos
```

---

## 📋 Pré-requisitos

| Item | Detalhe |
|---|---|
| Conta Azure | Assinatura ativa com permissão de Contributor |
| Azure CLI | Necessário **somente** para o `az acr build` |
| Azure Cloud Shell | Alternativa ao CLI — disponível no Portal (ícone `>_`) |

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
   - **Password:** `Produtos@2025!`
3. Clique em **"Review + create"** → **"Create"**

> 📌 Guarde o FQDN completo: `produtos-sqlserver.database.windows.net`

---

### Passo 2B — Criar Azure SQL Database

1. Pesquise **"SQL databases"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Database name:** `ProdutosDB`
   - **Server:** `produtos-sqlserver`
   - **Compute + storage:** clique em *"Configure database"* → **Basic (5 DTUs)**
   - **Backup storage redundancy:** `Locally redundant`
3. Clique em **"Review + create"** → **"Create"**

---

### Passo 2C — Configurar Firewall e Criar Tabela

**Firewall do SQL Server:**
1. Abra o recurso **SQL Server** (`produtos-sqlserver`)
2. Menu lateral → **Networking**
3. Clique em **"Add client IP"** para liberar seu IP atual
4. Em *"Exceptions"*: marque **"Allow Azure services and resources to access this server"**
5. Clique em **"Save"**

> ⚠️ Adicionar seu IP é necessário para acessar o **Query Editor** pelo navegador.

**Criar tabela via Query Editor:**
1. Abra o recurso **SQL Database** (`ProdutosDB`)
2. Menu lateral → **Query editor (preview)**
3. **Login:** `sqladmin` | **Password:** *(definida no passo 2A)*
4. Cole o conteúdo completo do arquivo `scripts/init_db.sql`
5. Clique em **"Run"** e aguarde a mensagem de sucesso
6. Valide: execute `SELECT * FROM Produtos` → deve retornar 5 linhas

---

### Passo 3A — Criar Azure Container Registry

1. Pesquise **"Container registries"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Registry name:** `acrprodutos` *(único global, só letras e números)*
   - **Location:** `Brazil South`
   - **Pricing plan:** `Basic`
3. Clique em **"Review + create"** → **"Create"**
4. Após criar: **Settings → Access keys**
5. Ative o toggle **"Admin user"**
6. Anote os três valores:
   - **Login server:** `acrprodutos.azurecr.io`
   - **Username:** `acrprodutos`
   - **Password:** *(copie o valor gerado)*

---

### Passo 3B — Build da Imagem ⚡ *(única etapa via CLI)*

> Esta é a **única etapa** que não pode ser feita pelo Portal, pois requer
> enviar arquivos locais para o ACR Tasks realizar o build na nuvem.
> Use o **Azure Cloud Shell** (ícone `>_` na barra superior do Portal)
> para evitar instalação local.

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
1. Abra **Container Registry** → `acrprodutos`
2. Menu lateral → **Services → Repositories**
3. Clique em `produtos-app` → confirme a tag `v1` listada

---

### Passo 4A — Criar Container Instance — Aba Basics

1. Pesquise **"Container instances"** → **"+ Create"**
2. Preencha:
   - **Resource group:** `rg-produtos`
   - **Container name:** `aci-produtos`
   - **Region:** `Brazil South`
   - **SKU:** `Standard`
   - **Image source:** `Azure Container Registry`
   - **Registry:** `acrprodutos`
   - **Image:** `produtos-app`
   - **Image tag:** `v1`
   - **OS type:** `Linux`
   - **Size:** `1 vCPU, 1.5 GiB memory`
3. Clique em **"Next: Networking >"**

---

### Passo 4B — Container Instance — Aba Networking

1. Preencha:
   - **Networking type:** `Public`
   - **DNS name label:** `produtos-app` *(opcional — gera URL amigável e fixa)*
   - **Ports:** `80` | **Protocol:** `TCP`
2. Clique em **"Next: Advanced >"**

> 📌 Com o DNS label definido, a URL será sempre:
> `produtos-app.brazilsouth.azurecontainer.io` — mesmo ao recriar o container.

---

### Passo 4C — Container Instance — Aba Advanced

1. **Restart policy:** `On failure`
2. Em **"Environment variables"**, clique em **"+ Add"** para cada variável:

   | Name | Value | Secure |
   |---|---|---|
   | `DB_SERVER` | `produtos-sqlserver.database.windows.net` | No |
   | `DB_NAME` | `ProdutosDB` | No |
   | `DB_USER` | `sqladmin` | No |
   | `DB_PASSWORD` | `<sua senha>` | **Yes** |

3. Clique em **"Review + create"** → **"Create"**
4. Aguarde o provisionamento (1 a 3 minutos)

---

### Passo 4D — Acessar a Aplicação

1. Após o deploy: clique em **"Go to resource"**
2. Na tela **Overview** do ACI, localize:
   - **IP address:** ex. `20.195.123.45`
   - **FQDN:** ex. `produtos-app.brazilsouth.azurecontainer.io`
3. Acesse no navegador:
   - `http://<IP ou FQDN>/produtos` → página de produtos
   - `http://<IP ou FQDN>/health` → `{"status": "ok"}`

---

## 🔄 Atualizar para Nova Versão

> ⚠️ O ACI **não suporta atualização de imagem in-place**.
> Para nova versão: delete o container atual e recrie com a nova tag.

### 1. Rebuild da imagem (CLI / Cloud Shell)

```bash
az acr build \
  --registry acrprodutos \
  --image    produtos-app:v2 \
  --file     Containerfile \
  .
```

### 2. Recriar o ACI no Portal

1. Abra **Container Instance** → `aci-produtos`
2. Clique em **"Delete"** e confirme
3. Repita o **Passo 4** usando a tag `v2`

> 💡 **Dica:** use sempre a tag `latest` no `az acr build` e no ACI para
> evitar precisar recriar o container a cada atualização:
> ```bash
> az acr build --registry acrprodutos --image produtos-app:latest --file Containerfile .
> ```

---

## 📊 Monitoramento no Portal

| Onde | O que monitorar |
|---|---|
| Container Instance → **Overview** | Status, IP, FQDN e uso de recursos |
| Container Instance → **Containers → Logs** | Logs do stdout/stderr em tempo real |
| Container Instance → **Containers → Connect** | Terminal interativo no container |
| Container Instance → **Metrics** | CPU% e memória% ao longo do tempo |
| ACR → **Repositories** | Imagens disponíveis e histórico de tags |
| SQL Database → **Query Performance Insight** | Queries lentas e consumo de DTUs |

---

## ⚠️ Pontos de Atenção do ACI

| Característica | Detalhe |
|---|---|
| IP público | Pode mudar ao recriar — use **DNS name label** para URL fixa |
| Atualização | Não há update in-place — delete + recrie para nova versão |
| Alta disponibilidade | ACI não oferece HA nativa — para produção considere AKS |
| Reinício automático | Configurado via *Restart policy: On failure* |
| Custo | Cobrado por segundo de CPU e memória utilizados |

---

## ✅ Checklist de Deploy

### Via Azure Portal *(interface gráfica)*
- [ ] Criar Resource Group `rg-produtos`
- [ ] Criar SQL Server `produtos-sqlserver`
- [ ] Criar SQL Database `ProdutosDB` (Basic 5 DTUs)
- [ ] Firewall SQL: *Allow Azure services* + *Add client IP*
- [ ] Query Editor: executar `init_db.sql` e validar 5 linhas
- [ ] Criar Container Registry `acrprodutos` + ativar *Admin user*
- [ ] Criar Container Instance (Basics + Networking + Advanced)
- [ ] Validar acesso em `http://<FQDN>/produtos`

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
| `DB_PASSWORD` | Senha SQL | *(marque como Secure no ACI)* |
