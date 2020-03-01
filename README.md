# yo
Todo la información sobre quien soy y que hago

## Requirements

- Terraform v0.12.21
- jq version: jq-1.5-1-a5b5cbe. JQ is a lightweight and flexible command-line JSON processor

## Build & deploy

```
cp ./terraform/terraform.tfvars.example ./terraform/stage/terraform.tfvars #Staging
```

```
cd ./terraform/stage # Staging
```

```
cd ./terraform/prod # Production
```
```
cp ./terraform/terraform.tfvars.example ./terraform/prod/terraform.tfvars #Production
```

```
mkdir -p ~/.terraform.d/plugins && \
curl -Ls https://api.github.com/repos/gavinbunney/terraform-provider-kubectl/releases/latest \
| jq -r ".assets[] | select(.browser_download_url | contains(\"$(uname -s | tr A-Z a-z)\")) \
| select(.browser_download_url | contains(\"amd64\")) | .browser_download_url" \
| xargs -n 1 curl -Lo ~/.terraform.d/plugins/terraform-provider-kubectl && \
chmod +x ~/.terraform.d/plugins/terraform-provider-kubectl
```

```
terraform init
```

```
terraform plan
```

```
terraform apply -auto-approve
```