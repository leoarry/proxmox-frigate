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
