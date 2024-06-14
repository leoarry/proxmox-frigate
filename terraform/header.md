## Terraform - Deploy Frigate to proxmox

open the `/terraform` folder and edit the `variables.tfvars` then run the script below from the `/terraform` folder

```bash
terraform init
terraform validate
terraform apply -var-file="variables.tfvars"
```