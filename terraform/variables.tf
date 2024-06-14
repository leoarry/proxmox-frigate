variable "proxmox" {
  description = "Target proxmox instance"
  type = object({
    ip = string
    user = string
    password = string 
    target_node = string
  })
  default = {
    ip = ""
    user = "root@pam"
    password = ""
    target_node = ""
  }
  sensitive   = true
}

variable "image" {
  description = "Frigate LXC image name and storage location"
  type = object({
    name = string
    storage = string
  })
  default = {
      name = ""
      storage = ""
    }
}

variable "ct_id" {
  type        = number
  description = "Frigate container ID"
  default     = 0
}

variable "on_boot" {
  type        = bool
  description = "Start the Frigate container when the host boot"
  default     = true
}

variable "lxc_hostname" {
  type        = string
  description = "Hostname for the Frigate container"
  default     = "frigate"
}

variable "lxc_password" {
  description = "Root user password for the Frigate container"
  type        = string
  default     = ""
  sensitive   = true
  validation {
    condition     = length(var.lxc_password) > 0
    error_message = "Please provide a password for the Frigate container."
  }
}

variable "network" {
  description = "Network details for the Frigate container"
  type = object({
    name = string
    bridge = string
    ip4 = string
    ip4mask = string
  })
  default = {
      name = "eth0"
      bridge = "vmbr0"
      ip4 = ""
      ip4mask = "24"
    }
}

variable "storage_fs" {
  description = "Storage name and size of the virtual disk to create for Frigate container root fs"
  type = object({
    name = string
    size = string
  })
  default = {
      name = ""
      size = "8G"
    }
}

variable "storage_media" {
  description = "Storage name (or path for binding mount) and size of the virtual disk to create for Frigate container root fs"
  type = object({
    name = string
    size = string
  })
  default = {
      name = ""
      size = "20G"
    }
}

variable "resources" {
  description = "Resources assigned to the Frigate container"
  type = object({
    cores = number
    memory = number
    swap = number
  })
  default = {
      cores = 2
      memory = 2048
      swap = 512
    }
}

variable "lxc_extraconfig" {
  description = "Extra configuration to append to the frigate .conf file"
  type = list(string)
  default = []
}

variable "frigate_config" {
  description = "Frigate configuration to upload to the container"
  type = string
  default = ""
  sensitive   = true
}