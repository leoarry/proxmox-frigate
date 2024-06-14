## Packer - Create Frigate golden image

open the `/packer` folder and edit the `variables.pkrvars.hcl` then run the script below from the `/packer` folder

```bash
packer init .
packer build -var-file="variables.pkrvars.hcl" .
```