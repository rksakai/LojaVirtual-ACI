az login

RESOURCE_GROUP="rg-produtos"
LOCATION="brazilsouth"
ACR_NAME="acrprodutos$(openssl rand -hex 4)"   # nome único global
ACA_ENV="aca-env-produtos"
ACA_APP="aca-app-produtos"

DB_SERVER="srv-sql-fiap-pf0807.database.windows.net"
DB_NAME="ProdutosDB"
DB_USER="sqladmin"
DB_PASSWORD="SuaSenhaForte123!"



az group create \
  --name     $RESOURCE_GROUP \
  --location $LOCATION




az acr create \
  --resource-group $RESOURCE_GROUP \
  --name           $ACR_NAME \
  --sku            Basic \
  --admin-enabled  true



# Execute na pasta raiz do projeto (onde está o Containerfile)
az acr build \
  --registry $ACR_NAME \
  --image    loja-app:v1 \
  --file     Dockerfile \
  .



# Via sqlcmd ou Azure Portal > SQL Database > Query Editor
sqlcmd \
  -S $DB_SERVER \
  -U $DB_USER \
  -P "$DB_PASSWORD" \
  -i scripts/init_db.sql



az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server         srv-sql-fiap-pf0807.database.windows.net \
  --name           AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address   0.0.0.0



az containerapp env create \
  --name           $ACA_ENV \
  --resource-group $RESOURCE_GROUP \
  --location       $LOCATION



ACR_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASS=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)



az containerapp create \
  --name              $ACA_APP \
  --resource-group    $RESOURCE_GROUP \
  --environment       $ACA_ENV \
  --image             $ACR_SERVER/loja-app:v1 \
  --registry-server   $ACR_SERVER \
  --registry-username $ACR_USER \
  --registry-password $ACR_PASS \
  --target-port       80 \
  --ingress           external \
  --min-replicas      1 \
  --max-replicas      3 \
  --cpu               0.5 \
  --memory            1.0Gi \
  --env-vars \
      DB_SERVER="$DB_SERVER" \
      DB_NAME="$DB_NAME" \
      DB_USER="$DB_USER" \
      DB_PASSWORD="$DB_PASSWORD"


az containerapp show \
  --name           $ACA_APP \
  --resource-group $RESOURCE_GROUP \
  --query          "properties.configuration.ingress.fqdn" \
  -o tsv
