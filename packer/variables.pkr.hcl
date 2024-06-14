variable "frigate_version" {
  type = string
  default = "stable"
  description = "Frigate docker image tag used for download"
}

variable "image_name" {
  type = string
  default = "FrigateProxmoxLxc"
  description = "Output image file name"
}

variable "image_output_path" {
  type = string
  default = "/mnt/storage/template/cache"
  description = "Path where to create the image (path to your Proxmox LXC storage)"
}

variable "ssh_username" {
  type = string
  default = "root"
  description = "SSH user with admin access to create and manage LXC containers"
}

variable "ssh_password" {
  type = string
  default = "ChangeMe"
  description = "SSH user password"
}

variable "remote_host" {
  type    = string
  default = "127.0.0.1"
  description = "Remote host IP address (usually Proxmox IP address)"
}

variable "use_sudo" {
  type    = bool
  default = false
  description = "Run provisioning script as sudo"
}

variable "frigate_config" {
  type = string
  default = <<-EOT
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
  description = "Frigate configuration to load into the LXC image"
}

variable "network_config" {
  type = string
  default = <<-EOT
auto lo
iface lo inet loopback

# interfaces(5) file used by ifup(8) and ifdown(8)
# Include files from /etc/network/interfaces.d:
source /etc/network/interfaces.d/*

auto eth0
iface eth0 inet dhcp
EOT
  description = "LXC network config file (will override content of /etc/network/interfaces)"
}