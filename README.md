# Frigate Proxmox Deployment
Frigate LXC image creation and deployment on Proxmox using HashiCorp Packer and Terraform.

## Prerequisite
Download this repo

### Install Packer and Terraform
Install [packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) and [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) then download this repository

### Optional - Coral M.2 drivers
Install the Google coral M.2 drivers on the Proxmox host with the following script
```
apt-get update
apt-get upgrade -y
apt install -y pve-headers git devscripts dh-dkms libedgetpu1-std
cd /home
git clone https://github.com/google/gasket-driver.git
cd gasket-driver/
debuild -us -uc -tc -b -d
cd ..
dpkg -i gasket-dkms_1.0-18_all.deb
```
Remember to disable the secure boot on the proxmox host

<!-- BEGIN_PACKER_DOCS -->
## Packer - Create Frigate golden image

open the `/packer` folder and edit the `variables.pkrvars.hcl` then run the script below from the `/packer` folder

```bash
packer init .
packer build -var-file="variables.pkrvars.hcl" .
```

#### Configuration Example

```hcl
frigate_version = "stable"
image_name = "FrigateProxmoxLxc"
image_output_path= "/mnt/storage/template/cache"
ssh_username = "root"
ssh_password = "ChangeMe"
remote_host = "127.0.0.1"
```

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_frigate_config"></a> [frigate\_config](#input\_frigate\_config) | Frigate configuration to load into the LXC image | `string` | `"mqtt:\n  enabled: False\n\ncameras:\n  dummy_camera:\n    enabled: False\n    ffmpeg:\n      inputs:\n        - path: rtsp://127.0.0.1:554/rtspn          roles:\n            - detect\n"` | no |
| <a name="input_frigate_version"></a> [frigate\_version](#input\_frigate\_version) | Frigate docker image tag used for download | `string` | `"stable"` | no |
| <a name="input_image_name"></a> [image\_name](#input\_image\_name) | Output image file name | `string` | `"FrigateProxmoxLxc"` | no |
| <a name="input_image_output_path"></a> [image\_output\_path](#input\_image\_output\_path) | Path where to create the image (path to your Proxmox LXC storage) | `string` | `"/mnt/storage/template/cache"` | no |
| <a name="input_network_config"></a> [network\_config](#input\_network\_config) | LXC network config file (will override content of /etc/network/interfaces) | `string` | `"auto lo\niface lo inet loopback\n\n# interfaces(5) file used by ifup(8) and ifdown(8)\n# Include files from /etc/network/interfaces.d:\nsource /etc/network/interfaces.d/*\n\nauto eth0\niface eth0 inet dhcp\n"` | no |
| <a name="input_remote_host"></a> [remote\_host](#input\_remote\_host) | Remote host IP address (usually Proxmox IP address) | `string` | `"127.0.0.1"` | no |
| <a name="input_ssh_password"></a> [ssh\_password](#input\_ssh\_password) | SSH user password | `string` | `"ChangeMe"` | no |
| <a name="input_ssh_username"></a> [ssh\_username](#input\_ssh\_username) | SSH user with admin access to create and manage LXC containers | `string` | `"root"` | no |
| <a name="input_use_sudo"></a> [use\_sudo](#input\_use\_sudo) | Run provisioning script as sudo | `bool` | `false` | no |
<!-- END_PACKER_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Terraform - Deploy Frigate to proxmox

open the `/terraform` folder and edit the `variables.tfvars` then run the script below from the `/terraform` folder

```bash
terraform init
terraform validate
terraform apply -var-file="variables.tfvars"
```

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |
| <a name="provider_proxmox"></a> [proxmox](#provider\_proxmox) | 2.9.14 |

## Outputs

No outputs.

#### Configuration Example

```hcl
proxmox = {
  ip = "127.0.0.1"
  user = "root@pam"
  password = "ProxmoxUserPassword"
  target_node = "pve-node-name"
}

image = {
  name = "FrigateProxmoxLxc"
  storage = "storage"
}

lxc_password = "ChangeMe"

network = {
  name = "eth0"
  bridge = "vmbr0"
  ip4 = "10.10.10.10"
  ip4mask = "24"
}

storage_fs = {
  name = "local-lvm"
  size = "8G"
}

storage_media = {
  name = "storage"
  size = "20G"
}

frigate_config = <<-EOT
mqtt:
  enabled: False

cameras:
  dummy_camera:
    enabled: False
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:554/rtsp
          roles:
            - detect
EOT
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ct_id"></a> [ct\_id](#input\_ct\_id) | Frigate container ID | `number` | `0` | no |
| <a name="input_frigate_config"></a> [frigate\_config](#input\_frigate\_config) | Frigate configuration to upload to the container | `string` | `""` | no |
| <a name="input_image"></a> [image](#input\_image) | Frigate LXC image name and storage location | <pre>object({<br>    name = string<br>    storage = string<br>  })</pre> | <pre>{<br>  "name": "",<br>  "storage": ""<br>}</pre> | no |
| <a name="input_lxc_extraconfig"></a> [lxc\_extraconfig](#input\_lxc\_extraconfig) | Extra configuration to append to the frigate .conf file | `list(string)` | `[]` | no |
| <a name="input_lxc_hostname"></a> [lxc\_hostname](#input\_lxc\_hostname) | Hostname for the Frigate container | `string` | `"frigate"` | no |
| <a name="input_lxc_password"></a> [lxc\_password](#input\_lxc\_password) | Root user password for the Frigate container | `string` | `""` | no |
| <a name="input_network"></a> [network](#input\_network) | Network details for the Frigate container | <pre>object({<br>    name = string<br>    bridge = string<br>    ip4 = string<br>    ip4mask = string<br>  })</pre> | <pre>{<br>  "bridge": "vmbr0",<br>  "ip4": "",<br>  "ip4mask": "24",<br>  "name": "eth0"<br>}</pre> | no |
| <a name="input_on_boot"></a> [on\_boot](#input\_on\_boot) | Start the Frigate container when the host boot | `bool` | `true` | no |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Target proxmox instance | <pre>object({<br>    ip = string<br>    user = string<br>    password = string <br>    target_node = string<br>  })</pre> | <pre>{<br>  "ip": "",<br>  "password": "",<br>  "target_node": "",<br>  "user": "root@pam"<br>}</pre> | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resources assigned to the Frigate container | <pre>object({<br>    cores = number<br>    memory = number<br>    swap = number<br>  })</pre> | <pre>{<br>  "cores": 2,<br>  "memory": 2048,<br>  "swap": 512<br>}</pre> | no |
| <a name="input_storage_fs"></a> [storage\_fs](#input\_storage\_fs) | Storage name and size of the virtual disk to create for Frigate container root fs | <pre>object({<br>    name = string<br>    size = string<br>  })</pre> | <pre>{<br>  "name": "",<br>  "size": "8G"<br>}</pre> | no |
| <a name="input_storage_media"></a> [storage\_media](#input\_storage\_media) | Storage name (or path for binding mount) and size of the virtual disk to create for Frigate container root fs | <pre>object({<br>    name = string<br>    size = string<br>  })</pre> | <pre>{<br>  "name": "",<br>  "size": "20G"<br>}</pre> | no |

## Resources


- resource.null_resource.frigate_config (terraform/main.tf#116)
- resource.null_resource.frigate_lxc_config (terraform/main.tf#65)
- resource.null_resource.frigate_start (terraform/main.tf#95)
- resource.proxmox_lxc.frigate_lxc (terraform/main.tf#23)
<!-- END_TF_DOCS -->