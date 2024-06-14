terraform {
  required_version = ">= 0.14"  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">=1.0.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">=3.2.2"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://${var.proxmox.ip}:8006/api2/json"
  pm_user         = var.proxmox.user          
  pm_password     = var.proxmox.password
  pm_tls_insecure = true
}

// resource to deploy the LXC container to Proxmox
resource "proxmox_lxc" "frigate_lxc" { 
  vmid         = var.ct_id
  target_node  = var.proxmox.target_node
  hostname     = var.lxc_hostname
  ostemplate   = "${var.image.storage}:vztmpl/${var.image.name}"
  password     = var.lxc_password
  cores        = var.resources.cores
  memory       = var.resources.memory
  swap         = var.resources.swap
  onboot       = var.on_boot
  start        = false

  features {
    nesting = true
  }

  // Rootfs mountpoint
  rootfs {
    storage = var.storage_fs.name
    size    = var.storage_fs.size
  }
  
  // Media storage
  mountpoint {
    key     = "0" 
    slot    = 0   
    storage = var.storage_media.name
    volume  = startswith(var.storage_media.name, "/") ? var.storage_media.name : ""
    size    = var.storage_media.size
    mp      = "/media/frigate"
  }

  // Network
  network {
    name   = var.network.name
    bridge = var.network.bridge
    ip     = var.network.ip4 != "" ? "${var.network.ip4}/${var.network.ip4mask}" : "dhcp"
  }

}

// resource to edit the LXC container configuration file on Proxmox host
resource "null_resource" "frigate_lxc_config" {

  depends_on = [proxmox_lxc.frigate_lxc]
    
  triggers = {
    lxc_created = "${proxmox_lxc.frigate_lxc.id}"
  }

  connection {
    type     = "ssh"
    user     = split("@", var.proxmox.user)[0]
    password = var.proxmox.password
    host     = var.proxmox.ip
  }

  provisioner "remote-exec" {
    inline = concat(
      ["echo 'Editing container config...'",
      "CONFIG_FILE=/etc/pve/lxc/${var.ct_id}.conf",
      "echo 'lxc.init.cmd: /init' >> \"$CONFIG_FILE\"",
      "echo 'lxc.log.level: 3' >> \"$CONFIG_FILE\"",
      "echo 'lxc.console.logfile: /var/log/frigate.log' >> \"$CONFIG_FILE\""],
      [for cnf in var.lxc_extraconfig : "echo '${cnf}' >> \"$CONFIG_FILE\""],
      ["echo 'Enabling HA for container...'",
      "ha-manager add ${var.ct_id} --type ct --max_relocate 0 --max_restart 10 "]
    )
  }
}

// resource to start the Frigate container without applying the Frigate configuration
resource "null_resource" "frigate_start" {
  count = var.frigate_config != "" ? 0 : 1
  depends_on = [proxmox_lxc.frigate_lxc, null_resource.frigate_lxc_config]
  
  connection {
    type     = "ssh"
    user     = split("@", var.proxmox.user)[0]
    password = var.proxmox.password
    host     = var.proxmox.ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting frigate container...'",
      "if ! pct status ${var.ct_id} | grep 'status: running'; then pct start ${var.ct_id}; fi",
      "for i in {1..24}; do pct status ${var.ct_id} | grep -q 'status: running' && break || sleep 5; done"
    ]
  }
}

// resource to update the Frigate configuration and restart the container
resource "null_resource" "frigate_config" {
  count = var.frigate_config != "" ? 1 : 0
  depends_on = [proxmox_lxc.frigate_lxc, null_resource.frigate_lxc_config]
  triggers = {
    config_checksum = var.frigate_config != "" ? md5(var.frigate_config) : ""
  }
  
  connection {
    type     = "ssh"
    user     = split("@", var.proxmox.user)[0]
    password = var.proxmox.password
    host     = var.proxmox.ip
  }

  provisioner "file" {
    content = var.frigate_config
    destination = "/tmp/config.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Starting frigate container...'",
      "if ! pct status ${var.ct_id} | grep 'status: running'; then pct start ${var.ct_id}; fi",
      "for i in {1..24}; do pct status ${var.ct_id} | grep -q 'status: running' && break || sleep 5; done",
      "echo 'Pushing the configuration...'",
      "pct push ${var.ct_id} /tmp/config.yml /config/config.yml",
      "echo 'Restarting the container...'",
      "pct reboot ${var.ct_id}"
    ]
  }
}